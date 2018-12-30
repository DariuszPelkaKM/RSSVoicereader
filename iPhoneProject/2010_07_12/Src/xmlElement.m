//
//  xmlElement.m
//  kiedyforsa.pl
//
//  Created by Mateusz Bajer on 10.03.04.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "xmlElement.h"


@implementation xmlElement
@synthesize prevElement, name, attributes, currentParsedCharacterData;

+ (id)xmlElement:(NSString *)name withAttributes:(NSDictionary *)attrs {
	xmlElement *element = [[super alloc] init];
	if (element) {
		element.prevElement = nil;
		element.name = name;
		element.attributes = [NSDictionary dictionaryWithDictionary:attrs];
		element.currentParsedCharacterData = [[[NSMutableString alloc] initWithString:@""] retain];
	}
	return element;
}

- (void)dealloc {
	[attributes release];
	[currentParsedCharacterData release];
	[super dealloc];
}

@end
