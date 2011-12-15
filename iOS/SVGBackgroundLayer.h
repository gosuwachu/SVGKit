//
//  SVGBackgroundLayer.h
//  SVGKit
//
//  Created by Piotr Wach on 12/14/11.
//  Copyright (c) 2011 Polidea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "SVGKit.h"

@interface SVGBackgroundLayer : CALayer
@property(nonatomic, retain) SVGDocument* document;
@property(nonatomic, retain) SVGElement* element;
@end
