//
//  SVGElement.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGElement.h"

@implementation SVGElement

@synthesize parent = _parent;
@synthesize children = _children;
@synthesize identifier = _identifier;

+ (BOOL)shouldStoreContent {
	return NO;
}

- (id)init {
    self = [super init];
    if (self) {
		[self loadDefaults];
        _children = [[NSMutableArray alloc] init];
        wasAttachedAtPosition = -1;
    }
    return self;
}

- (id)initWithParent:(SVGElement*)aParent {
	self = [self init];
	if (self) {
        _parent = aParent;
	}
	return self;
}

- (void)dealloc {
	[_children release];
	[_identifier release];
	
	[super dealloc];
}

- (void) deattachFromParent {
    if(_parent) {
        wasAttachedAtPosition = [_parent.children indexOfObject:self];
        [_parent.children removeObject:self];
    }
}

- (void) attachToParent {
    if(_parent && wasAttachedAtPosition >=0) {
        [_parent.children insertObject:self atIndex:wasAttachedAtPosition];
        wasAttachedAtPosition = -1;
    }
}

- (void)loadDefaults {
	// to be overriden by subclasses
}

- (void)addChild:(SVGElement *)element {
	[_children addObject:element];
}

- (void)parseAttributes:(NSDictionary *)attributes {
	// to be overriden by subclasses
	// make sure super implementation is called
	
	id value = nil;
	
	if ((value = [attributes objectForKey:@"id"])) {
		_identifier = [value copy];
	}
}

- (void)parseContent:(NSString *)content {
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@ %p | children=%d | id=%@>", 
			[self class], self, [_children count], _identifier];
}

- (void) drawInContext:(CGContextRef)context {
    for(SVGElement* element in self.children) {
        [element drawInContext:context];
    }
}

- (SVGElement*) findElementWithIdentifier:(NSString*)aIdentifier {
    if([_identifier isEqualToString:aIdentifier]) {
        return self;
    }
    for(SVGElement* element in _children) {
        SVGElement* found = [element findElementWithIdentifier:aIdentifier];
        if(found) {
            return found;
        }
    }
    return nil;
}

- (SVGElement*) getElementAtPosition:(CGPoint)aPosition {
    SVGElement* topElement = nil;
    for(SVGElement* element in _children) {
        SVGElement* found = [element getElementAtPosition:aPosition];
        if(found) {
            topElement = found;
        }
    }
    return topElement;
}

- (CGRect) getBoundingBox {
    CGRect boundingBox = CGRectZero;
    for(SVGElement* element in self.children) {
        CGRect elementBoundingBox = [element getBoundingBox];
        boundingBox = CGRectUnion(boundingBox, elementBoundingBox);
    }
    return boundingBox;
}

@end
