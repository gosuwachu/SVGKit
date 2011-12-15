//
//  SVGLayer.m
//  SVGKit
//
//  Created by Piotr Wach on 12/13/11.
//  Copyright (c) 2011 Polidea. All rights reserved.
//

#import "SVGTiledLayer.h"
#import "SVGElementLayer.h"
#import "SVGBackgroundLayer.h"

@interface SVGTiledLayer()
//- (SVGElementLayer*) getLayerForElement:(SVGElement*)element;
@end

@implementation SVGTiledLayer
@synthesize document;

- (id) init {
    self = [super init];
    if(self) {
        elements = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (id) layerWithDocument:(SVGDocument*)document
{
    SVGTiledLayer* layer = [CATiledLayer layer];
    layer.document = document;
    return layer;
}

- (void) dealloc {
    [elements release];
    [document release];
    [super dealloc];
}

+(CFTimeInterval)fadeDuration
{
    return 0.0;     // Normally it’s 0.25
}

- (void) setNeedsDisplay {
    [super setNeedsDisplay];
    for(CALayer* sublayer in self.sublayers) {
        [sublayer setNeedsDisplay];
    }
}

- (void) setNeedsDisplayInRect:(CGRect)r {
    [super setNeedsDisplayInRect:r];
    for(CALayer* sublayer in self.sublayers) {
        [sublayer setNeedsDisplayInRect:r];
    }
}

- (void)drawInContext:(CGContextRef)ctx {
    @synchronized(self) {
        CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
        CGContextFillRect(ctx, self.bounds);
        [document drawInContext:ctx];
    }
}

- (BOOL) isElementDetached:(SVGElement *)element {
    return [self getLayerForElement:element] != nil;
}

- (void) detachElement:(SVGElement *)element {
    SVGBackgroundLayer* backgroundLayer = [SVGBackgroundLayer layer];
    backgroundLayer.element = element;
    backgroundLayer.document = document;
    backgroundLayer.frame = self.bounds;
    backgroundLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0].CGColor;
    [backgroundLayer setNeedsDisplay];
    
    SVGElementLayer* elementLayer = [SVGElementLayer layer];
    elementLayer.element = element;
    elementLayer.document = document;
    elementLayer.frame = self.bounds;
    elementLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0].CGColor;
    //elementLayer.opacity = 0.5;
    [elementLayer setNeedsDisplay];
    elementLayer.rasterizationScale = 10;
    [elementLayer setShouldRasterize:NO];
    [self setShouldRasterize:NO];
    
//    [self addSublayer:backgroundLayer];
    [self addSublayer:elementLayer];
    [elements addObject:elementLayer];
    
    [element retain];
    [element deattachFromParent];
    
    [self setNeedsDisplayInRect:[element getBoundingBox]];
    [element release];
    // TODO: force a redraw of element rect?
}

- (void) attachElement:(SVGElement *)element {
    [element attachToParent];
    
    SVGElementLayer* elementLayer = [self getLayerForElement:element];
    if(elementLayer) {
        [elementLayer removeFromSuperlayer];
    }
    
    [self setNeedsDisplay];
    // TODO: force a redraw of element rect?
}

- (SVGElementLayer*) getLayerForElement:(SVGElement*)element {
    for(SVGElementLayer* layer in elements) {
        if(layer.element == element) {
            return layer;
        }
    }
    return nil;
}
@end
