//
//  SVGStyleDeclaration.m
//  SVGKit
//
//  Created by Piotr Wach on 12/12/11.
//  Copyright (c) 2011 Polidea. All rights reserved.
//

#import "SVGStyleDeclaration.h"

@interface SVGStyleDeclaration()
- (void) loadDefaults;
@end

@implementation SVGStyleDeclaration
@synthesize opacity = _opacity;

@synthesize fillType = _fillType;
@synthesize fillColor = _fillColor;
@synthesize fillPattern = _fillPattern;

@synthesize strokeWidth = _strokeWidth;
@synthesize strokeColor = _strokeColor;

- (id) init 
{
    self = [super init];
    if(self) {
        [self loadDefaults];
    }
    return self;
}

- (void)loadDefaults {
	_opacity = 1.0f;
	
	//_fillColor = SVGColorMake(0, 0, 0, 255);
	//_fillType = SVGFillTypeSolid;
}

- (void)parseAttributes:(NSDictionary *)attributes
{
    id value = nil;
	
	if ((value = [attributes objectForKey:@"opacity"])) {
		_opacity = [value floatValue];
	}
	
	if ((value = [attributes objectForKey:@"fill"])) {
		const char *cvalue = [value UTF8String];
		
		if (!strncmp(cvalue, "none", 4)) {
			_fillType = SVGFillTypeNone;
		}
		else if (!strncmp(cvalue, "url", 3)) {
			NSLog(@"Gradients are no longer supported");
			_fillType = SVGFillTypeNone;
		}
		else {
			_fillColor = SVGColorFromString([value UTF8String]);
			_fillType = SVGFillTypeSolid;
		}
	}
	
	if ((value = [attributes objectForKey:@"stroke-width"])) {
		_strokeWidth = [value floatValue];
	}
	
	if ((value = [attributes objectForKey:@"stroke"])) {
		const char *cvalue = [value UTF8String];
		
		if (!strncmp(cvalue, "none", 4)) {
			_strokeWidth = 0.0f;
		}
		else {
			_strokeColor = SVGColorFromString(cvalue);
			
			if (!_strokeWidth)
				_strokeWidth = 1.0f;
		}
	}
	
	if ((value = [attributes objectForKey:@"stroke-opacity"])) {
		_strokeColor.a = (uint8_t) ([value floatValue] * 0xFF);
	}
	
	if ((value = [attributes objectForKey:@"fill-opacity"])) {
		_fillColor.a = (uint8_t) ([value floatValue] * 0xFF);
	}
}

- (void) applyStyle:(CGContextRef)context 
{
    if (_strokeWidth) {
        CGContextSetLineWidth(context, _strokeWidth);
        CGContextSetStrokeColorWithColor(context, CGColorWithSVGColor(_strokeColor));
    }
    
    if (_fillType == SVGFillTypeNone) {
		// ...
	} else if (_fillType == SVGFillTypeSolid) {
        CGContextSetFillColorWithColor(context, CGColorWithSVGColor(_fillColor));
	}
    
    if (_fillPattern) {
        CGContextSetFillColorWithColor(context, [_fillPattern CGColor]);
    }
}
@end
