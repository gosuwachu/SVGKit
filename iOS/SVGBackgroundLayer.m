//
//  SVGBackgroundLayer.m
//  SVGKit
//
//  Created by Piotr Wach on 12/14/11.
//  Copyright (c) 2011 Polidea. All rights reserved.
//

#import "SVGBackgroundLayer.h"

@implementation SVGBackgroundLayer
@synthesize document;
@synthesize element;

- (void) dealloc {
    [document release];
    [element release];
    [super dealloc];
}

- (void) drawInContext:(CGContextRef)ctx {
    CGRect clipRect = CGRectInset([element getBoundingBox], -1, -1);
    CGContextClipToRect(ctx, clipRect);
    //CGContextSetRGBFillColor(ctx, 1, 0, 0, 1);
    //CGContextFillRect(ctx, clipRect);
    [document drawInContext:ctx];
    //[element drawInContext:ctx];
}
@end
