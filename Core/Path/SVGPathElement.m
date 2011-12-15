//
//  SVGPathElement.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGPathElement.h"

#import "SVGElement+Private.h"
#import "SVGShapeElement+Private.h"
#import "SVGUtils.h"

// TODO: support smooth-quadratic-bezier-curveto
// TODO: support elliptical-arc

typedef struct SVGCurve
{
    CGPoint c1;
    CGPoint c2;
    CGPoint p;
} SVGCurve;

SVGCurve SVGCurveMake(CGFloat cx1, CGFloat cy1, CGFloat cx2, CGFloat cy2, CGFloat px, CGFloat py);
inline SVGCurve SVGCurveMake(CGFloat cx1, CGFloat cy1, CGFloat cx2, CGFloat cy2, CGFloat px, CGFloat py)
{
    SVGCurve curve;
    curve.c1 = CGPointMake(cx1, cy1);
    curve.c2 = CGPointMake(cx2, cy2);
    curve.p = CGPointMake(px, py);
    return curve;
}

BOOL SVGCurveEqualToCurve(SVGCurve curve1, SVGCurve curve2);
inline BOOL SVGCurveEqualToCurve(SVGCurve curve1, SVGCurve curve2)
{
    return (
            CGPointEqualToPoint(curve1.c1, curve2.c1)
            &&
            CGPointEqualToPoint(curve1.c2, curve2.c2)
            &&
            CGPointEqualToPoint(curve1.p, curve2.p)
            );
}

#define SVGCurveZero SVGCurveMake(0.,0.,0.,0.,0.,0.)

@interface SVGPathElement ()

- (void) parseData:(NSString *)data;
- (void) parseAttributes:(NSDictionary *)attributes;

- (void) readWhitespace:(NSScanner*)scanner;
- (void) readCommaAndWhitespace:(NSScanner*)scanner;

- (CGFloat) readCoordinate:(NSScanner*)scanner;
- (CGPoint) readCoordinatePair:(NSScanner*)scanner;

- (CGPoint) readMovetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isAbsolute:(BOOL)isAbsolute;
- (CGPoint) readMovetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isAbsolute:(BOOL)isAbsolute;
- (CGPoint) readMovetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;

- (CGPoint) readLinetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isAbsolute:(BOOL)isAbsolute;
- (CGPoint) readLinetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isAbsolute:(BOOL)isAbsolute;
- (CGPoint) readLinetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;

- (CGPoint) readVerticalLinetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;
- (CGPoint) readVerticalLinetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;
- (CGPoint) readHorizontalLinetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;
- (CGPoint) readHorizontalLinetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;

- (SVGCurve) readCurvetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isAbsolute:(BOOL)isAbsolute;
- (SVGCurve) readCurvetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isAbsolute:(BOOL)isAbsolute;
- (SVGCurve) readCurvetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;

- (SVGCurve) readSmoothCurvetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevCurve:(SVGCurve)prevCurve isAbsolute:(BOOL)isAbsolute;
- (SVGCurve) readSmoothCurvetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevCurve:(SVGCurve)prevCurve isAbsolute:(BOOL)isAbsolute;
- (SVGCurve) readSmoothCurvetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevCurve:(SVGCurve)prevCurve;

- (SVGCurve) readQuadCurvetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevCurve:(SVGCurve)prevCurve isAbsolute:(BOOL)isAbsolute;
- (SVGCurve) readQuadCurvetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevCurve:(SVGCurve)prevCurve isAbsolute:(BOOL)isAbsolute;
- (SVGCurve) readQuadCurvetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevCurve:(SVGCurve)prevCurve;

- (CGPoint) readCloseCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin;

@end

@implementation SVGPathElement

- (void)parseAttributes:(NSDictionary *)attributes
{
	[super parseAttributes:attributes];
	
	id value = nil;
	
	if ((value = [attributes objectForKey:@"d"])) {
		[self parseData:value];
	}
}

- (void)parseData:(NSString *)data
{
	CGMutablePathRef path = CGPathCreateMutable();
    NSScanner* dataScanner = [NSScanner scannerWithString:data];
    CGPoint lastCoordinate = CGPointZero;
    SVGCurve lastCurve = SVGCurveZero;
    BOOL foundCmd;
    
    NSCharacterSet* knownCommands = [NSCharacterSet characterSetWithCharactersInString:@"MmLlCcVvHhAaSsQqTtZz"];
    
    do {
        NSString* command = nil;
        foundCmd = [dataScanner scanCharactersFromSet:knownCommands intoString:&command];
        
        if (foundCmd) {
            if ([@"z" isEqualToString:command] || [@"Z" isEqualToString:command]) {
                lastCoordinate = [self readCloseCommand:[NSScanner scannerWithString:command]
                                                   path:path
                                             relativeTo:lastCoordinate];
            } else {
                NSString* cmdArgs = nil;
                BOOL foundParameters = [dataScanner scanUpToCharactersFromSet:knownCommands
                                                                   intoString:&cmdArgs];
                
                if (foundParameters) {
                    NSString* commandWithParameters = [command stringByAppendingString:cmdArgs];
                    NSScanner* commandScanner = [NSScanner scannerWithString:commandWithParameters];
                    
                    if ([@"m" isEqualToString:command]) {
                        lastCoordinate = [self readMovetoCommand:commandScanner
                                                                        path:path
                                                                  relativeTo:lastCoordinate isAbsolute:NO];
                        lastCurve = SVGCurveZero;
                    } else if ([@"M" isEqualToString:command]) {
                        lastCoordinate = [self readMovetoCommand:commandScanner
                                                                        path:path
                                                                  relativeTo:CGPointZero isAbsolute:YES];
                        lastCurve = SVGCurveZero;
                    } else if ([@"l" isEqualToString:command]) {
                        lastCoordinate = [self readLinetoCommand:commandScanner
                                                            path:path
                                                      relativeTo:lastCoordinate isAbsolute:NO];
                        lastCurve = SVGCurveZero;
                    } else if ([@"L" isEqualToString:command]) {
                        lastCoordinate = [self readLinetoCommand:commandScanner
                                                            path:path
                                                      relativeTo:CGPointZero isAbsolute:YES];
                        lastCurve = SVGCurveZero;
                    } else if ([@"v" isEqualToString:command]) {
                        lastCoordinate = [self readVerticalLinetoCommand:commandScanner
                                                                    path:path
                                                              relativeTo:lastCoordinate];
                        lastCurve = SVGCurveZero;
                    } else if ([@"V" isEqualToString:command]) {
                        lastCoordinate = [self readVerticalLinetoCommand:commandScanner
                                                                    path:path
                                                      relativeTo:CGPointZero];
                        lastCurve = SVGCurveZero;
                    } else if ([@"h" isEqualToString:command]) {
                        lastCoordinate = [self readHorizontalLinetoCommand:commandScanner
                                                                      path:path
                                                                relativeTo:lastCoordinate];
                        lastCurve = SVGCurveZero;
                    } else if ([@"H" isEqualToString:command]) {
                        lastCoordinate = [self readHorizontalLinetoCommand:commandScanner
                                                                      path:path
                                                                relativeTo:CGPointZero];
                        lastCurve = SVGCurveZero;
                    } else if ([@"c" isEqualToString:command]) {
                        lastCurve = [self readCurvetoCommand:commandScanner
                                                        path:path
                                                  relativeTo:lastCoordinate isAbsolute:NO];
                        lastCoordinate = lastCurve.p;
                    } else if ([@"C" isEqualToString:command]) {
                        lastCurve = [self readCurvetoCommand:commandScanner
                                                        path:path
                                                  relativeTo:CGPointZero isAbsolute:YES];
                        lastCoordinate = lastCurve.p;
                    } else if ([@"s" isEqualToString:command]) {
                        lastCurve = [self readSmoothCurvetoCommand:commandScanner
                                                              path:path
                                                        relativeTo:lastCoordinate
                                                     withPrevCurve:lastCurve isAbsolute:NO];
                        lastCoordinate = lastCurve.p;
                    } else if ([@"S" isEqualToString:command]) {
                        lastCurve = [self readSmoothCurvetoCommand:commandScanner
                                                              path:path
                                                        relativeTo:CGPointZero
                                                     withPrevCurve:lastCurve isAbsolute:YES];
                        lastCoordinate = lastCurve.p;
                    } else if([@"q" isEqualToString:command]) {
                        lastCurve = [self readQuadCurvetoCommand:commandScanner
                                                            path:path
                                                      relativeTo:lastCoordinate
                                                   withPrevCurve:lastCurve isAbsolute:NO];
                        lastCoordinate = lastCurve.p;
                    } else if([@"Q" isEqualToString:command]) {
                        lastCurve = [self readQuadCurvetoCommand:commandScanner
                                                              path:path
                                                        relativeTo:CGPointZero
                                                     withPrevCurve:lastCurve isAbsolute:YES];
                        lastCoordinate = lastCurve.p;
                    } else {
                        NSLog(@"unsupported command %@", command);
                    }
                }
            }
        }
        
    } while (foundCmd);
    
	[self loadPath:path];
	CGPathRelease(path);
}

/* reference
 http://www.w3.org/TR/2011/REC-SVG11-20110816/paths.html#PathDataBNF
 */

/*
svg-path:
    wsp* moveto-drawto-command-groups? wsp*
moveto-drawto-command-groups:
    moveto-drawto-command-group
    | moveto-drawto-command-group wsp* moveto-drawto-command-groups
moveto-drawto-command-group:
    moveto wsp* drawto-commands?
drawto-commands:
    drawto-command
    | drawto-command wsp* drawto-commands
drawto-command:
    closepath
    | lineto
    | horizontal-lineto
    | vertical-lineto
    | curveto
    | smooth-curveto
    | quadratic-bezier-curveto
    | smooth-quadratic-bezier-curveto
    | elliptical-arc
moveto:
    ( "M" | "m" ) wsp* moveto-argument-sequence
moveto-argument-sequence:
    coordinate-pair
    | coordinate-pair comma-wsp? lineto-argument-sequence
closepath:
    ("Z" | "z")
lineto:
    ( "L" | "l" ) wsp* lineto-argument-sequence
lineto-argument-sequence:
    coordinate-pair
    | coordinate-pair comma-wsp? lineto-argument-sequence
horizontal-lineto:
    ( "H" | "h" ) wsp* horizontal-lineto-argument-sequence
horizontal-lineto-argument-sequence:
    coordinate
    | coordinate comma-wsp? horizontal-lineto-argument-sequence
vertical-lineto:
    ( "V" | "v" ) wsp* vertical-lineto-argument-sequence
vertical-lineto-argument-sequence:
    coordinate
    | coordinate comma-wsp? vertical-lineto-argument-sequence
curveto:
    ( "C" | "c" ) wsp* curveto-argument-sequence
curveto-argument-sequence:
    curveto-argument
    | curveto-argument comma-wsp? curveto-argument-sequence
curveto-argument:
    coordinate-pair comma-wsp? coordinate-pair comma-wsp? coordinate-pair
smooth-curveto:
    ( "S" | "s" ) wsp* smooth-curveto-argument-sequence
smooth-curveto-argument-sequence:
    smooth-curveto-argument
    | smooth-curveto-argument comma-wsp? smooth-curveto-argument-sequence
smooth-curveto-argument:
    coordinate-pair comma-wsp? coordinate-pair
quadratic-bezier-curveto:
    ( "Q" | "q" ) wsp* quadratic-bezier-curveto-argument-sequence
quadratic-bezier-curveto-argument-sequence:
    quadratic-bezier-curveto-argument
    | quadratic-bezier-curveto-argument comma-wsp? 
        quadratic-bezier-curveto-argument-sequence
quadratic-bezier-curveto-argument:
    coordinate-pair comma-wsp? coordinate-pair
smooth-quadratic-bezier-curveto:
    ( "T" | "t" ) wsp* smooth-quadratic-bezier-curveto-argument-sequence
smooth-quadratic-bezier-curveto-argument-sequence:
    coordinate-pair
    | coordinate-pair comma-wsp? smooth-quadratic-bezier-curveto-argument-sequence
elliptical-arc:
    ( "A" | "a" ) wsp* elliptical-arc-argument-sequence
elliptical-arc-argument-sequence:
    elliptical-arc-argument
    | elliptical-arc-argument comma-wsp? elliptical-arc-argument-sequence
elliptical-arc-argument:
    nonnegative-number comma-wsp? nonnegative-number comma-wsp? 
        number comma-wsp flag comma-wsp? flag comma-wsp? coordinate-pair
coordinate-pair:
    coordinate comma-wsp? coordinate
coordinate:
    number
nonnegative-number:
    integer-constant
    | floating-point-constant
number:
    sign? integer-constant
    | sign? floating-point-constant
flag:
    "0" | "1"
comma-wsp:
    (wsp+ comma? wsp*) | (comma wsp*)
comma:
    ","
integer-constant:
    digit-sequence
floating-point-constant:
    fractional-constant exponent?
    | digit-sequence exponent
fractional-constant:
    digit-sequence? "." digit-sequence
    | digit-sequence "."
exponent:
    ( "e" | "E" ) sign? digit-sequence
sign:
    "+" | "-"
digit-sequence:
    digit
    | digit digit-sequence
digit:
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
*/

/**
 wsp:
    (#x20 | #x9 | #xD | #xA)
*/
- (void) readWhitespace:(NSScanner*)scanner
{

    NSCharacterSet* whitespace = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"%c%c%c%c", 0x20, 0x9, 0xD, 0xA]];
    [scanner scanCharactersFromSet:whitespace
                        intoString:NULL];
}

- (void) readCommaAndWhitespace:(NSScanner*)scanner
{
    [self readWhitespace:scanner];
    static NSString* comma = @",";
    [scanner scanString:comma intoString:NULL];
    [self readWhitespace:scanner];
}

/**
 coordinate-pair:
 coordinate comma-wsp? coordinate
 */

- (CGPoint) readCoordinatePair:(NSScanner*)scanner
{
    CGFloat x = [self readCoordinate:scanner];
    [self readCommaAndWhitespace:scanner];
    CGFloat y = [self readCoordinate:scanner];
    
    CGPoint p = CGPointMake(x, y);
    return p;
}

- (CGFloat) readCoordinate:(NSScanner*)scanner
{
    CGFloat f;
    BOOL ok;
    ok = [scanner scanFloat:&f];
    NSAssert(ok, @"invalid coord");
    return f;
}

/**
 moveto:
 ( "M" | "m" ) wsp* moveto-argument-sequence
 */
- (CGPoint) readMovetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isAbsolute:(BOOL)isAbsolute
{
    NSString* cmd = nil;
    NSCharacterSet* cmdFormat = [NSCharacterSet characterSetWithCharactersInString:@"Mm"];
    BOOL ok = [scanner scanCharactersFromSet:cmdFormat intoString:&cmd];
    
    NSAssert(ok, @"failed to scan move to command");
    if (!ok) return origin;
    
    [self readWhitespace:scanner];
    
    CGPoint lastCoordinate = [self readMovetoArgumentSequence:scanner path:path relativeTo:origin isAbsolute:isAbsolute];
    return lastCoordinate;
}

/** moveto-argument-sequence:
 coordinate-pair
 | coordinate-pair comma-wsp? lineto-argument-sequence
*/
- (CGPoint) readMovetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isAbsolute:(BOOL)isAbsolute
{
    CGPoint lastPos = [self readMovetoArgument:scanner path:path relativeTo:origin];
    if(!isAbsolute) {
        origin = lastPos;
    }
    [self readCommaAndWhitespace:scanner];

    if (![scanner isAtEnd]) {
        lastPos = [self readLinetoArgumentSequence:scanner path:path relativeTo:origin isAbsolute:isAbsolute];
    }
    return lastPos;
}

- (CGPoint) readMovetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
    CGPoint p = [self readCoordinatePair:scanner];
    CGPoint coord = CGPointMake(p.x+origin.x, p.y+origin.y);
    CGPathMoveToPoint(path, NULL, coord.x, coord.y);
    
    return coord;
}

/** 
 lineto:
    ( "L" | "l" ) wsp* lineto-argument-sequence
*/
- (CGPoint) readLinetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isAbsolute:(BOOL)isAbsolute
{
    NSString* cmd = nil;
    NSCharacterSet* cmdFormat = [NSCharacterSet characterSetWithCharactersInString:@"Ll"];
    BOOL ok = [scanner scanCharactersFromSet:cmdFormat intoString:&cmd];
    
    NSAssert(ok, @"failed to scan line to command");
    if (!ok) return origin;

    [self readWhitespace:scanner];
    
    CGPoint lastCoordinate = [self readLinetoArgumentSequence:scanner path:path relativeTo:origin isAbsolute:isAbsolute];
    return lastCoordinate;
}

/** 
 lineto-argument-sequence:
 coordinate-pair
 | coordinate-pair comma-wsp? lineto-argument-sequence
 */
- (CGPoint) readLinetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isAbsolute:(BOOL)isAbsolute
{
    CGPoint lastPos;   
    while (![scanner isAtEnd]) {
        [self readCommaAndWhitespace:scanner];
        lastPos = [self readLinetoArgument:scanner path:path relativeTo:origin];
        if(!isAbsolute) {
            origin = lastPos;
        }
    }
    return lastPos;
}

- (CGPoint) readLinetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
    CGPoint p = [self readCoordinatePair:scanner];
    CGPoint coord = CGPointMake(p.x+origin.x, p.y+origin.y);
    CGPathAddLineToPoint(path, NULL, coord.x, coord.y);
    return coord;
}

/**
 curveto:
 ( "C" | "c" ) wsp* curveto-argument-sequence
 */
- (SVGCurve) readCurvetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isAbsolute:(BOOL)isAbsolute
{
    NSString* cmd = nil;
    NSCharacterSet* cmdFormat = [NSCharacterSet characterSetWithCharactersInString:@"Cc"];
    BOOL ok = [scanner scanCharactersFromSet:cmdFormat intoString:&cmd];
    
    NSAssert(ok, @"failed to scan curve to command");
    if (!ok) return SVGCurveZero;

    [self readWhitespace:scanner];
    
    SVGCurve lastCurve = [self readCurvetoArgumentSequence:scanner path:path relativeTo:origin isAbsolute:isAbsolute];
    return lastCurve;
}

/**
 curveto-argument-sequence:
    curveto-argument
    | curveto-argument comma-wsp? curveto-argument-sequence
 */
- (SVGCurve) readCurvetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin isAbsolute:(BOOL)isAbsolute
{
    SVGCurve curve;
    while (![scanner isAtEnd]) {
        curve = [self readCurvetoArgument:scanner path:path relativeTo:origin];
        if(!isAbsolute) {
            origin = curve.p;
        }
    }
    return curve;
}

/**
 curveto-argument:
    coordinate-pair comma-wsp? coordinate-pair comma-wsp? coordinate-pair
 */
- (SVGCurve) readCurvetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
    CGPoint p1 = [self readCoordinatePair:scanner];
    CGPoint coord1 = CGPointMake(p1.x+origin.x, p1.y+origin.y);
    [self readCommaAndWhitespace:scanner];
    
    CGPoint p2 = [self readCoordinatePair:scanner];
    CGPoint coord2 = CGPointMake(p2.x+origin.x, p2.y+origin.y);
    [self readCommaAndWhitespace:scanner];
    
    CGPoint p3 = [self readCoordinatePair:scanner];
    CGPoint coord3 = CGPointMake(p3.x+origin.x, p3.y+origin.y);
    [self readCommaAndWhitespace:scanner];
    
    CGPathAddCurveToPoint(path, NULL, coord1.x, coord1.y, coord2.x, coord2.y, coord3.x, coord3.y);
    
    return SVGCurveMake(coord1.x, coord1.y, coord2.x, coord2.y, coord3.x, coord3.y);
}

/**
 smooth-curveto:
    ( "S" | "s" ) wsp* smooth-curveto-argument-sequence
*/
- (SVGCurve) readSmoothCurvetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevCurve:(SVGCurve)prevCurve isAbsolute:(BOOL)isAbsolute
{
    NSString* cmd = nil;
    NSCharacterSet* cmdFormat = [NSCharacterSet characterSetWithCharactersInString:@"Ss"];
    BOOL ok = [scanner scanCharactersFromSet:cmdFormat intoString:&cmd];
    
    NSAssert(ok, @"failed to scan smooth curve to command");
    if (!ok) return SVGCurveZero;

    [self readWhitespace:scanner];
    
    SVGCurve lastCurve = [self readSmoothCurvetoArgumentSequence:scanner path:path relativeTo:origin withPrevCurve:prevCurve isAbsolute:isAbsolute];
    return lastCurve;
}

/**
 smooth-curveto-argument-sequence:
     smooth-curveto-argument
     | smooth-curveto-argument comma-wsp? smooth-curveto-argument-sequence
*/
- (SVGCurve) readSmoothCurvetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevCurve:(SVGCurve)prevCurve isAbsolute:(BOOL)isAbsolute
{
    SVGCurve curve;
    while (![scanner isAtEnd]) {
        curve = [self readSmoothCurvetoArgument:scanner path:path relativeTo:origin withPrevCurve:prevCurve];
        if(!isAbsolute) {
            origin = curve.p;
            prevCurve = curve;
        }
    }
    return curve;
}

/**
 smooth-curveto-argument:
    coordinate-pair comma-wsp? coordinate-pair
*/
- (SVGCurve) readSmoothCurvetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevCurve:(SVGCurve)prevCurve
{
    CGPoint p1 = [self readCoordinatePair:scanner];
    CGPoint coord1 = CGPointMake(p1.x+origin.x, p1.y+origin.y);
    [self readCommaAndWhitespace:scanner];
    
    CGPoint p2 = [self readCoordinatePair:scanner];
    CGPoint coord2 = CGPointMake(p2.x+origin.x, p2.y+origin.y);
    
    SVGCurve thisCurve;
    if (SVGCurveEqualToCurve(SVGCurveZero, prevCurve)) {
        // assume control point is coincident with the current point
        thisCurve = SVGCurveMake(coord1.x, coord1.y, coord2.x, coord2.y, coord1.x, coord1.y);
    } else {
        // calculate the mirror of the previous control point
        CGPoint currentPoint = prevCurve.p;
        CGPoint controlPoint = prevCurve.c2;
        CGPoint mirrorCoord = CGPointMake(currentPoint.x+(currentPoint.x-controlPoint.x), currentPoint.y+(currentPoint.y-controlPoint.y));
        thisCurve = SVGCurveMake(mirrorCoord.x, mirrorCoord.y, coord1.x, coord1.y, coord2.x, coord2.y);
    }
    
    CGPathAddCurveToPoint(path, NULL, thisCurve.c1.x, thisCurve.c1.y, thisCurve.c2.x, thisCurve.c2.y, thisCurve.p.x, thisCurve.p.y);
    return thisCurve;
}

- (SVGCurve) readQuadCurvetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevCurve:(SVGCurve)prevCurve isAbsolute:(BOOL)isAbsolute
{
    NSString* cmd = nil;
    NSCharacterSet* cmdFormat = [NSCharacterSet characterSetWithCharactersInString:@"Qq"];
    BOOL ok = [scanner scanCharactersFromSet:cmdFormat intoString:&cmd];
    
    NSAssert(ok, @"failed to scan quad curve to command");
    if (!ok) return SVGCurveZero;
    
    [self readWhitespace:scanner];
    
    SVGCurve lastCurve = [self readQuadCurvetoArgumentSequence:scanner path:path relativeTo:origin withPrevCurve:prevCurve isAbsolute:isAbsolute];
    return lastCurve;
}

- (SVGCurve) readQuadCurvetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevCurve:(SVGCurve)prevCurve isAbsolute:(BOOL)isAbsolute
{
    SVGCurve curve;
    while (![scanner isAtEnd]) {
        curve = [self readQuadCurvetoArgument:scanner path:path relativeTo:origin withPrevCurve:prevCurve];
        if(!isAbsolute) {
            origin = curve.p;
            prevCurve = curve;
        }
    }
    return curve;
}

- (SVGCurve) readQuadCurvetoArgument:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin withPrevCurve:(SVGCurve)prevCurve
{
    CGPoint p1 = [self readCoordinatePair:scanner];
    CGPoint controlPoint = CGPointMake(p1.x+origin.x, p1.y+origin.y);
    [self readCommaAndWhitespace:scanner];
    
    CGPoint p2 = [self readCoordinatePair:scanner];
    CGPoint currentPoint = CGPointMake(p2.x+origin.x, p2.y+origin.y);
    
    SVGCurve thisCurve = SVGCurveMake(controlPoint.x, controlPoint.y, currentPoint.x, currentPoint.y, currentPoint.x, currentPoint.y);
    CGPathAddQuadCurveToPoint(path, NULL, thisCurve.c1.x, thisCurve.c1.y, thisCurve.c2.x, thisCurve.c2.y);
    return thisCurve;
}

/**
 vertical-lineto-argument-sequence:
    coordinate
    | coordinate comma-wsp? vertical-lineto-argument-sequence
*/
- (CGPoint) readVerticalLinetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
    CGFloat yValue = [self readCoordinate:scanner];
    CGPoint vertCoord = CGPointMake(origin.x, origin.y+yValue);
    CGPoint currentPoint = CGPathGetCurrentPoint(path);
    CGPoint coord = CGPointMake(currentPoint.x, currentPoint.y+(vertCoord.y-currentPoint.y));
    CGPathAddLineToPoint(path, NULL, coord.x, coord.y);
    return coord;
}

/**
 vertical-lineto:
 ( "V" | "v" ) wsp* vertical-lineto-argument-sequence
*/
- (CGPoint) readVerticalLinetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
    NSString* cmd = nil;
    NSCharacterSet* cmdFormat = [NSCharacterSet characterSetWithCharactersInString:@"Vv"];
    BOOL ok = [scanner scanCharactersFromSet:cmdFormat intoString:&cmd];
    
    NSAssert(ok, @"failed to scan vertical line to command");
    if (!ok) return origin;

    [self readWhitespace:scanner];
    
    CGPoint lastCoordinate = [self readVerticalLinetoArgumentSequence:scanner path:path relativeTo:origin];
    return lastCoordinate;
}

/**
 horizontal-lineto-argument-sequence:
    coordinate
    | coordinate comma-wsp? horizontal-lineto-argument-sequence
 */
- (CGPoint) readHorizontalLinetoArgumentSequence:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
    CGFloat xValue = [self readCoordinate:scanner];
    CGPoint horizCoord = CGPointMake(origin.x+xValue, origin.y);
    CGPoint currentPoint = CGPathGetCurrentPoint(path);
    CGPoint coord = CGPointMake(currentPoint.x+(horizCoord.x-currentPoint.x), currentPoint.y);
    CGPathAddLineToPoint(path, NULL, coord.x, coord.y);
    return coord;
}

/**
 horizontal-lineto:
    ( "H" | "h" ) wsp* horizontal-lineto-argument-sequence
 */
- (CGPoint) readHorizontalLinetoCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
    NSString* cmd = nil;
    NSCharacterSet* cmdFormat = [NSCharacterSet characterSetWithCharactersInString:@"Hh"];
    BOOL ok = [scanner scanCharactersFromSet:cmdFormat intoString:&cmd];
    
    NSAssert(ok, @"failed to scan horizontal line to command");
    if (!ok) return origin;

    [self readWhitespace:scanner];
    
    CGPoint lastCoordinate = [self readHorizontalLinetoArgumentSequence:scanner path:path relativeTo:origin];
    return lastCoordinate;
}

- (CGPoint) readCloseCommand:(NSScanner*)scanner path:(CGMutablePathRef)path relativeTo:(CGPoint)origin
{
    NSString* cmd = nil;
    NSCharacterSet* cmdFormat = [NSCharacterSet characterSetWithCharactersInString:@"Zz"];
    BOOL ok = [scanner scanCharactersFromSet:cmdFormat intoString:&cmd];
    
    NSAssert(ok, @"failed to scan close command");
    if (!ok) return origin;

    CGPathCloseSubpath(path);
    
    return origin;
}

@end
