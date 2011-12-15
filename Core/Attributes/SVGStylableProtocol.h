//
//  SVGStylable.h
//  SVGKit
//
//  Created by Piotr Wach on 12/12/11.
//  Copyright (c) 2011 Polidea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVGStyleDeclaration.h"

@protocol SVGStylableProtocol <NSObject>
- (SVGStyleDeclaration*) styleDeclaration;
@end
