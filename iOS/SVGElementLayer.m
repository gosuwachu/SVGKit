//
//  SVGElementLayer.m
//  SVGKit
//
//  Created by Piotr Wach on 12/13/11.
//  Copyright (c) 2011 Polidea. All rights reserved.
//

#import "SVGElementLayer.h"

@implementation SVGElementLayer
@synthesize element;
@synthesize document;

- (void) dealloc {
    [document release];
    [element release];
    [super dealloc];
}

- (void) drawInContext:(CGContextRef)ctx {
    //CGRect clipRect = CGRectInset([element getBoundingBox], -20, -20);
    //CGContextClipToRect(ctx, clipRect);
    //CGContextSetRGBFillColor(ctx, 1, 0, 0, 1);
    //CGContextFillRect(ctx, clipRect);
    //[document drawInContext:ctx];
    [element drawInContext:ctx];
}
@end
