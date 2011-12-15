//
//  SVGElement.h
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

@class SVGDocument;

@interface SVGElement : NSObject 
{
    NSMutableArray *_children;
    int wasAttachedAtPosition;
}
@property (nonatomic, readonly) SVGElement* parent;
@property (nonatomic, readonly) NSMutableArray *children;

@property (nonatomic, readwrite, retain) NSString *identifier; // 'id' is reserved

// to optimize parser, default is NO
+ (BOOL)shouldStoreContent; 

- (id)initWithParent:(SVGElement*)parent;

- (void) deattachFromParent;
- (void) attachToParent;

// should be overriden to set element defaults
- (void)loadDefaults;

- (void) drawInContext:(CGContextRef)context;

- (SVGElement*) findElementWithIdentifier:(NSString*)aIdentifier;

- (SVGElement*) getElementAtPosition:(CGPoint)aPosition;

- (CGRect) getBoundingBox;

@end
