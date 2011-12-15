//
//  SVGLayer.h
//  SVGKit
//
//  Created by Piotr Wach on 12/13/11.
//  Copyright (c) 2011 Polidea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "SVGDocument.h"
#import "SVGElementLayer.h"

@interface SVGTiledLayer : CATiledLayer
{
    NSMutableArray* elements;
}
@property(nonatomic, retain) SVGDocument* document;

- (BOOL) isElementDetached:(SVGElement*)element;
- (void) detachElement:(SVGElement*)element;
- (void) attachElement:(SVGElement*)element;
- (SVGElementLayer*) getLayerForElement:(SVGElement*)element;
@end
