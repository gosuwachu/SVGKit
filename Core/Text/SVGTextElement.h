//
//  SVGText.h
//  SVGKit
//
//  Created by Piotr Wach on 12/12/11.
//  Copyright (c) 2011 Polidea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVGElement.h"
#import "SVGStylableProtocol.h"
#import "SVGStyleDeclaration.h"

@interface SVGTextElement : SVGElement<SVGStylableProtocol>
{
}

@property(nonatomic, assign) CGFloat x;
@property(nonatomic, assign) CGFloat y;
@property(nonatomic, assign) CGFloat dx;
@property(nonatomic, assign) CGFloat dy;

@property(nonatomic, assign) int fontSize;
@property(nonatomic, retain) NSString* fontFamily;

@property(nonatomic, copy) NSString* text;

@property (nonatomic, readonly) SVGStyleDeclaration* style;
@end
