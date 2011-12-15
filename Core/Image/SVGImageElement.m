//
//  SVGImageElement.m
//  SvgLoader
//
//  Created by Joshua May on 24/06/11.
//  Copyright 2011 Polidea. All rights reserved.
//

#import "SVGImageElement.h"

@implementation SVGImageElement

@synthesize x = _x;
@synthesize y = _y;
@synthesize width = _width;
@synthesize height = _height;

@synthesize href = _href;

- (void)dealloc {
    [_href release];
    _href = nil;
    
    [image release];

    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)parseAttributes:(NSDictionary *)attributes {
	id value = nil;

	if ((value = [attributes objectForKey:@"x"])) {
		_x = [value floatValue];
	}

	if ((value = [attributes objectForKey:@"y"])) {
		_y = [value floatValue];
	}

	if ((value = [attributes objectForKey:@"width"])) {
		_width = [value floatValue];
	}

	if ((value = [attributes objectForKey:@"height"])) {
		_height = [value floatValue];
	}

	if ((value = [attributes objectForKey:@"href"])) {
		_href = [value retain];
	}
}

- (void) drawInContext:(CGContextRef)context {
    
}

@end
