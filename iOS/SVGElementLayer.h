//
//  SVGElementLayer.h
//  SVGKit
//
//  Created by Piotr Wach on 12/13/11.
//  Copyright (c) 2011 Polidea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "SVGKit.h"

@interface SVGElementLayer : CALayer
@property(nonatomic, retain) SVGElement* element;
@property(nonatomic, retain) SVGDocument* document;
@end
