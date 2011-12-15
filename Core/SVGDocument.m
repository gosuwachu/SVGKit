//
//  SVGDocument.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGDocument.h"

#import "SVGDefsElement.h"
#import "SVGDescriptionElement.h"
#import "SVGElement+Private.h"
#import "SVGParser.h"
#import "SVGTitleElement.h"
#import "SVGPathElement.h"

@interface SVGDocument ()

@property (nonatomic, copy) NSString *version;

- (BOOL)parseFileAtPath:(NSString *)aPath;

@end


@implementation SVGDocument

@synthesize width = _width;
@synthesize height = _height;
@synthesize version = _version;

@dynamic title, desc, defs;

/* TODO: parse 'viewBox' */

+ (id)documentNamed:(NSString *)name {
	NSParameterAssert(name != nil);
	
	NSBundle *bundle = [NSBundle mainBundle];
	
	if (!bundle)
		return nil;
	
	NSString *newName = [name stringByDeletingPathExtension];
	NSString *extension = [name pathExtension];
    if ([@"" isEqualToString:extension]) {
        extension = @"svg";
    }
	
	NSString *path = [bundle pathForResource:newName ofType:extension];
	
	if (!path)
		return nil;
	
	return [self documentWithContentsOfFile:path];
}

+ (id)documentWithContentsOfFile:(NSString *)aPath {
	return [[[[self class] alloc] initWithContentsOfFile:aPath] autorelease];
}

- (id)initWithContentsOfFile:(NSString *)aPath {
	NSParameterAssert(aPath != nil);
	
	self = [super initWithParent:nil];
	if (self) {
		_width = _height = 100;
		
		if (![self parseFileAtPath:aPath]) {
			[self release];
			return nil;
		}
	}
	return self;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithParent:nil];
	if (self) {
        _width = CGRectGetWidth(frame);
        _height = CGRectGetHeight(frame);
    }
	return self;
}

- (void)dealloc {
	[_version release];
	[super dealloc];
}

- (BOOL)parseFileAtPath:(NSString *)aPath {
	NSError *error = nil;
	
	SVGParser *parser = [[SVGParser alloc] initWithPath:aPath document:self];
	
	if (![parser parse:&error]) {
		NSLog(@"Parser error: %@", error);
		[parser release];
		
		return NO;
	}
	
	[parser release];
	
	return YES;
}

- (void)parseAttributes:(NSDictionary *)attributes {
	[super parseAttributes:attributes];
	
	id value = nil;
	
	if ((value = [attributes objectForKey:@"width"])) {
		_width = [value floatValue];
	}
	
	if ((value = [attributes objectForKey:@"height"])) {
		_height = [value floatValue];
	}
	
	if ((value = [attributes objectForKey:@"version"])) {
		self.version = value;
	}
}

@end
