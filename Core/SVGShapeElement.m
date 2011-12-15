//
//  SVGShapeElement.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGShapeElement.h"

#import "CGPathAdditions.h"
#import "SVGDefsElement.h"
#import "SVGDocument.h"
#import "SVGElement+Private.h"
#import "SVGPattern.h"
#import "SVGGroupElement.h"

#define IDENTIFIER_LEN 256

@implementation SVGShapeElement
@synthesize style;
@synthesize path = _path;

- (id) initWithParent:(SVGElement *)parent {
    self = [super initWithParent:parent];
    if(self) {
        style = [[SVGStyleDeclaration alloc] init];
    }
    return self;
}

- (void)dealloc {
    [style release];
	CGPathRelease(_path);
	[super dealloc];
}

- (void)parseAttributes:(NSDictionary *)attributes {
	[super parseAttributes:attributes];
    [style parseAttributes:attributes];
}

- (void)loadPath:(CGPathRef)aPath {
	if (_path) {
		CGPathRelease(_path);
		_path = NULL;
	}
	
	if (aPath) {
		_path = CGPathCreateCopy(aPath);
	}
}

- (void) drawInContext:(CGContextRef)context {
    [style applyStyle:context];
    CGContextAddPath(context, _path);
    
    if (style.fillType == SVGFillTypeNone) {
        CGContextDrawPath(context, kCGPathStroke);
	} else if (style.fillType == SVGFillTypeSolid) {
        if(style.strokeWidth) {
            CGContextDrawPath(context, kCGPathFillStroke);
        } else {
            CGContextDrawPath(context, kCGPathFill);
        }
    }
}

- (SVGElement*) getElementAtPosition:(CGPoint)aPosition {
    CGAffineTransform transform = CGAffineTransformIdentity;
    if([self.parent isKindOfClass:[SVGGroupElement class]]) {
        SVGGroupElement* parent = (SVGGroupElement*)self.parent;
        transform = CGAffineTransformInvert([parent getTransformation]);
    }

    if(CGPathContainsPoint(_path, &transform, aPosition, NO)) {
        return self;
    } else {
        return nil;
    }
}

- (CGRect) getBoundingBox {
    CGAffineTransform transform = CGAffineTransformIdentity;
    if([self.parent isKindOfClass:[SVGGroupElement class]]) {
        SVGGroupElement* parent = (SVGGroupElement*)self.parent;
        transform = CGAffineTransformInvert([parent getTransformation]);
    }
    
    CGRect boundingBox = CGRectZero;
    
    CGPathRef transformedPath = CGPathCreateCopyByTransformingPath(_path, &transform);
    boundingBox = CGPathGetBoundingBox(transformedPath);
    CGPathRelease(transformedPath);
    
    return boundingBox;
}

#pragma SVGStylableProtocol
- (SVGStyleDeclaration*) styleDeclaration
{
    return style;
}

@end
