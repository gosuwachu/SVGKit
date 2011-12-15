//
//  SVGStyleDeclaration.h
//  SVGKit
//
//  Created by Piotr Wach on 12/12/11.
//  Copyright (c) 2011 Polidea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVGUtils.h"

@class SVGGradientElement;
@class SVGPattern;

typedef enum {
	SVGFillTypeNone = 0,
	SVGFillTypeSolid,
} SVGFillType;

@interface SVGStyleDeclaration : NSObject

@property (nonatomic, readwrite) CGFloat opacity;

@property (nonatomic, readwrite) SVGFillType fillType;
@property (nonatomic, readwrite) SVGColor fillColor;
@property (nonatomic, readwrite, retain) SVGPattern* fillPattern;

@property (nonatomic, readwrite) CGFloat strokeWidth;
@property (nonatomic, readwrite) SVGColor strokeColor;

- (void)parseAttributes:(NSDictionary *)attributes;
- (void) applyStyle:(CGContextRef) context;
@end
