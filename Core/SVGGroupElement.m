//
//  SVGGroupElement.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGGroupElement.h"

#import "SVGDocument.h"
#import "SVGElement+Private.h"

@interface SVGGroupElement ()
- (void) parseTransform:(NSString*)transform;
- (void) readMatrixTransform:(NSString*)args;
- (void) readTranslateTransform:(NSString*)args;
- (void) readScaleTransform:(NSString*)args;
- (void) readRotateTransform:(NSString*)args;
- (void) readSkewXTransform:(NSString*)args;
- (void) readSkewYTransform:(NSString*)args;
@end

@implementation SVGGroupElement
@synthesize transforms;
@synthesize opacity = _opacity;

- (void) dealloc {
    [transforms release];
    [super dealloc];
}

- (void)loadDefaults {
	_opacity = 1.0f;
}

- (void)parseAttributes:(NSDictionary *)attributes {
	[super parseAttributes:attributes];
	
	id value = nil;
	
	if ((value = [attributes objectForKey:@"opacity"])) {
		_opacity = [value floatValue];
	} else if ((value = [attributes objectForKey:@"transform"])) {
        [self parseTransform:value];
    }
}
                         
- (void) parseTransform:(NSString*)transform {
    transforms = [[NSMutableArray alloc] init];
    
    NSScanner* dataScanner = [NSScanner scannerWithString:transform];
    BOOL foundCmd;
    
    NSCharacterSet* knownCommands = [NSCharacterSet characterSetWithCharactersInString:
                                     @"matrix|translate|scale|rotate|skewX|skewY"];
    
    do {
        NSString* command;
        foundCmd = [dataScanner scanCharactersFromSet:knownCommands intoString:&command];
        if(foundCmd) {
            NSString* cmdArgs = nil;
            BOOL foundParameters = [dataScanner scanUpToCharactersFromSet:knownCommands
                                                               intoString:&cmdArgs];
            if (foundParameters) {
                if([command isEqualToString:@"matrix"]) {
                    [self readMatrixTransform:cmdArgs];
                } else if([command isEqualToString:@"translate"]) {
                    [self readTranslateTransform:cmdArgs];
                } else if([command isEqualToString:@"scale"]) {
                    [self readScaleTransform:cmdArgs];
                } else if([command isEqualToString:@"rotate"]) {
                    [self readRotateTransform:cmdArgs];
                } else if([command isEqualToString:@"skewX"]) {
                    [self readSkewXTransform:cmdArgs];
                } else if([command isEqualToString:@"skewY"]) {
                    [self readSkewYTransform:cmdArgs];
                }
            }
        }
    } while(foundCmd);
}

- (void) readBracket:(NSScanner*)scanner
{
    NSCharacterSet* bracket = [NSCharacterSet characterSetWithCharactersInString:@"()"];
    [scanner scanCharactersFromSet:bracket intoString:nil];
}

- (void) readWhitespace:(NSScanner*)scanner
{
    NSCharacterSet* whitespace = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"%c%c%c%c", 0x20, 0x9, 0xD, 0xA]];
    [scanner scanCharactersFromSet:whitespace intoString:nil];
}

- (void) readCommaAndWhitespace:(NSScanner*)scanner
{
    [self readWhitespace:scanner];
    static NSString* comma = @",";
    [scanner scanString:comma intoString:nil];
    [self readWhitespace:scanner];
}

- (CGFloat) readCoordinate:(NSScanner*)scanner
{
    CGFloat f;
    BOOL ok;
    ok = [scanner scanFloat:&f];
    NSAssert(ok, @"invalid coord");
    return f;
}

- (void) readMatrixTransform:(NSString *)args {
    NSScanner* scanner = [NSScanner scannerWithString:args];
    [self readBracket:scanner];

    CGAffineTransform transform;
    [self readCommaAndWhitespace:scanner];
    transform.a = [self readCoordinate:scanner];
    [self readCommaAndWhitespace:scanner];
    transform.b = [self readCoordinate:scanner];
    [self readCommaAndWhitespace:scanner];
    transform.c = [self readCoordinate:scanner];
    [self readCommaAndWhitespace:scanner];
    transform.d = [self readCoordinate:scanner];
    [self readCommaAndWhitespace:scanner];
    transform.tx = [self readCoordinate:scanner];
    [self readCommaAndWhitespace:scanner];
    transform.ty = [self readCoordinate:scanner];
    
    [transforms addObject:[NSValue valueWithCGAffineTransform:transform]];
}

- (void) readTranslateTransform:(NSString*)args {
    NSScanner* scanner = [NSScanner scannerWithString:args];
    [self readBracket:scanner];
    
    CGAffineTransform transform;
    transform.a = 1;
    transform.b = 0;
    transform.c = 0;
    transform.d = 1;
    [self readCommaAndWhitespace:scanner];
    transform.tx = [self readCoordinate:scanner];
    [self readCommaAndWhitespace:scanner];
    transform.ty = [self readCoordinate:scanner];
    
    [transforms addObject:[NSValue valueWithCGAffineTransform:transform]];
}

- (void) readScaleTransform:(NSString*)args {
    NSScanner* scanner = [NSScanner scannerWithString:args];
    [self readBracket:scanner];
    
    CGAffineTransform transform;
    [self readCommaAndWhitespace:scanner];
    transform.a = [self readCoordinate:scanner];
    transform.b = 0;
    transform.c = 0;
    [self readCommaAndWhitespace:scanner];
    transform.d = [self readCoordinate:scanner];
    transform.tx = 0;
    transform.ty = 0;
    
    [transforms addObject:[NSValue valueWithCGAffineTransform:transform]];
}

- (void) readRotateTransform:(NSString*)args {
    NSScanner* scanner = [NSScanner scannerWithString:args];
    [self readBracket:scanner];
    
    CGAffineTransform transform;
    [self readCommaAndWhitespace:scanner];
    float angle = [self readCoordinate:scanner];
    transform.a = cos(angle);
    transform.b = sin(angle);
    transform.c = -transform.b;
    transform.d = transform.a;
    transform.tx = 0;
    transform.ty = 0;
    
    [self readCommaAndWhitespace:scanner];
    BOOL hasAnchor = ![scanner isAtEnd];
    float x, y;
    if(hasAnchor) {
        x = [self readCoordinate:scanner];
        [self readCommaAndWhitespace:scanner];
        y = [self readCoordinate:scanner];
    }
    if(hasAnchor) {
        [transforms addObject:[NSValue valueWithCGAffineTransform:
                               CGAffineTransformMakeTranslation(x, y)]];
    }
    [transforms addObject:[NSValue valueWithCGAffineTransform:transform]];
    if(hasAnchor) {
        [transforms addObject:[NSValue valueWithCGAffineTransform:
                               CGAffineTransformMakeTranslation(-x, -y)]];
    }
}

- (void) readSkewXTransform:(NSString*)args {
    NSScanner* scanner = [NSScanner scannerWithString:args];
    [self readBracket:scanner];
    
    CGAffineTransform transform;
    transform.a = 1;
    transform.b = 0;
    [self readCommaAndWhitespace:scanner];
    transform.c = tan([self readCoordinate:scanner]);
    transform.d = 1;
    transform.tx = 0;
    transform.ty = 0;
    
    [transforms addObject:[NSValue valueWithCGAffineTransform:transform]];
}

- (void) readSkewYTransform:(NSString*)args {
    NSScanner* scanner = [NSScanner scannerWithString:args];
    [self readBracket:scanner];
    
    CGAffineTransform transform;
    transform.a = 1;
    [self readCommaAndWhitespace:scanner];
    transform.b = tan([self readCoordinate:scanner]);
    transform.c = 0;
    transform.d = 1;
    transform.tx = 0;
    transform.ty = 0;
    
    [transforms addObject:[NSValue valueWithCGAffineTransform:transform]];
}

- (CGAffineTransform) getTransformation {
    CGAffineTransform parentTransform = CGAffineTransformIdentity;
    if(self.parent && [self.parent isKindOfClass:[SVGGroupElement class]]) {
        SVGGroupElement* parent = (SVGGroupElement*)self.parent;
        parentTransform = [parent getTransformation];
    }
    return CGAffineTransformConcat(parentTransform, [self getCurrentTransformation]);
}

- (CGAffineTransform) getCurrentTransformation {
    CGAffineTransform transformation = CGAffineTransformIdentity;
    if(transforms) {
        @synchronized(transforms) {
            for(int i = 0; i < transforms.count; ++i) {
                CGAffineTransform t;
                [((NSValue*)[transforms objectAtIndex:i]) getValue:&t];
                transformation = CGAffineTransformConcat(transformation, t);
            }
        }
    }
    return transformation;
}

- (void) drawInContext:(CGContextRef)context {
    CGContextSaveGState(context);
    
    CGContextSetAlpha(context, _opacity);
    CGContextBeginTransparencyLayer(context, nil);

    CGContextConcatCTM(context, [self getCurrentTransformation]);
    
    for(SVGElement* element in self.children) {     
        [element drawInContext:context];
    }
    CGContextEndTransparencyLayer(context);
    CGContextRestoreGState(context);
}

@end
