//
//  SVGGroupElement.h
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGElement.h"

@interface SVGGroupElement : SVGElement 
{ 
    NSMutableArray* transforms;
}
@property (atomic, readonly) NSMutableArray* transforms;
@property (nonatomic, readonly) CGFloat opacity;

- (CGAffineTransform) getTransformation;
- (CGAffineTransform) getCurrentTransformation;

@end
