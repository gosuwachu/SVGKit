//
//  SVGView.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGView.h"
#import "SVGDocument.h"
#import "SVGTiledLayer.h"

@implementation SVGView

@synthesize document = _document;

- (id)initWithDocument:(SVGDocument *)document {
	NSParameterAssert(document != nil);
	
	self = [self initWithFrame:CGRectMake(0.0f, 0.0f, document.width, document.height)];
	if (self) {
        SVGTiledLayer *tiledLayer = (SVGTiledLayer *)[self layer];
        tiledLayer.levelsOfDetail = 10;
		tiledLayer.levelsOfDetailBias = 5;
		tiledLayer.tileSize = CGSizeMake(512.0, 512.0);
        tiledLayer.document = document;
        self.document = document;
	}
	return self;
}

+ (Class) layerClass 
{
    return [SVGTiledLayer class];
}

- (void)dealloc {
	[_document release];
	[super dealloc];
}

- (void)setDocument:(SVGDocument *)aDocument {
	if (_document != aDocument) {
		[_document release];
		_document = [aDocument retain];
	}
}

- (void) drawRect:(CGRect)rect
{
    // needed to tell the framework to call drawLayer:inContext:
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx{
    //[self.document drawInContext:ctx];
    
    //    @synchronized(self) {
    //        CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    //        CGContextFillRect(ctx, rootLayer.bounds);
    //        [document drawInContext:ctx];
    //    }
    [self.layer drawLayer:layer inContext:ctx];
}

@end
