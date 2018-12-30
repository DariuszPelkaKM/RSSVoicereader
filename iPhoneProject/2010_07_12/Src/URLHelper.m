//
//  URLHelper.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.07.08.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "URLHelper.h"


@implementation URLHelper

+ (NSString *)standarizeStringToURL:(NSString *)urlString {
	NSString *s = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (!s)
		return nil; // error
	
	if (!CFStringHasPrefix((CFStringRef)s , (CFStringRef)@"http://"))
		s = [NSString stringWithFormat:@"http://%@", s];
	
	return s;
}

@end
