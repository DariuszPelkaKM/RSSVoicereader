//
//  mobileAPI.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.06.24.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "mobileAPI.h"


@implementation NSDictionary (mobileAPI)

- (BOOL)isSuccess {
	return [[self objectForKey:kJSONKeyResult] isEqualToString:kJSONResultSuccess];
}

@end
