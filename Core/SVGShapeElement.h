//
//  SVGShapeElement.h
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGElement.h"
#import "SVGUtils.h"
#import "SVGStylableProtocol.h"
#import "SVGTransformableProtocol.h"
#import "SVGStyleDeclaration.h"

@interface SVGShapeElement : SVGElement<SVGStylableProtocol>
{
}
@property (nonatomic, readonly) SVGStyleDeclaration* style;
@property (nonatomic, readwrite) CGPathRef path;

@end
