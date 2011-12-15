//
//  SVGText.m
//  SVGKit
//
//  Created by Piotr Wach on 12/12/11.
//  Copyright (c) 2011 Polidea. All rights reserved.
//

#import "SVGTextElement.h"
#import "SVGElement+Private.h"

@interface SVGTextElement()
@end

@implementation SVGTextElement
@synthesize text;
@synthesize style;
@synthesize x, y, dx, dy, fontSize, fontFamily;

- (id) initWithParent:(SVGElement *)parent {
    self = [super initWithParent:parent];
    if(self) {
        style = [[SVGStyleDeclaration alloc] init];
    }
    return self;
}

+ (BOOL)shouldStoreContent {
	return YES;
}

- (void) dealloc {
    [fontFamily release];
    [text release];
    [style release];
    [super dealloc];
}

- (SVGStyleDeclaration *)styleDeclaration {
    return style;
}

- (void)parseAttributes:(NSDictionary *)attributes
{
	[super parseAttributes:attributes];
	
	id value = nil;
	
	if ((value = [attributes objectForKey:@"x"])) {
		x = [value floatValue];
	} 
    if ((value = [attributes objectForKey:@"y"])) {
		y = [value floatValue];
	} 
    if ((value = [attributes objectForKey:@"dx"])) {
		dx = [value floatValue];
	} 
    if ((value = [attributes objectForKey:@"dy"])) {
		dy = [value floatValue];
	}
    
    if ((value = [attributes objectForKey:@"font-size"])) {
		fontSize = [value floatValue];
	}
    
    if ((value = [attributes objectForKey:@"font-family"])) {
		self.fontFamily = value;
	}
    
    [style parseAttributes:attributes];
}

- (void) parseContent:(NSString *)content {
    self.text = content;
}

- (void) drawInContext:(CGContextRef)context {
    
//    if(self.fontFamily) {
//        CGFontRef font = CGFontCreateWithFontName((CFStringRef)self.fontFamily);
//        CGContextSetFont(context, font);
//        //CGFontRelease(font);
//    }
//    
//    if(fontSize > 0) {
//        CGContextSetFontSize(context, fontSize);
//    }
    
    if(self.fontFamily) {
        CGContextSelectFont(context, [self.fontFamily cStringUsingEncoding:NSUTF8StringEncoding], fontSize, kCGEncodingMacRoman);
    }
    CGContextSetTextDrawingMode (context, kCGTextFill);
    
    [style applyStyle:context];
        
    if(self.text) {
        CGContextSaveGState(context);
        
        CGContextConcatCTM(context, CGAffineTransformMakeScale(1, -1));
        const char* raw = [self.text cStringUsingEncoding:NSUTF8StringEncoding];
        CGContextShowTextAtPoint(context, x + dx, -y - dy, raw, strlen(raw));
        
        CGContextRestoreGState(context);
    }
    
    for(SVGElement* element in self.children) {
        [element drawInContext:context];
    }
}

@end
