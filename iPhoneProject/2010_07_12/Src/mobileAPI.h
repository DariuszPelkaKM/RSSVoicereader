//
//  mobileAPI.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.06.24.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSON.h"

#define kJSONResultSuccess @"Success"
#define kJSONResultFailure @"Failure"
#define kJSONKeyResult @"Result"
#define kJSONKeyAppId @"AppId"
#define kJSONKeyData @"Data"
#define kJSONKeyName @"Name"
#define kJSONKeyChildren @"Children"
#define kJSONKeyFeeds @"Feeds"
#define kJSONKeyURL @"Url"

#define mobileAPIURL @"http://62.121.100.3/mobile-api"
#define appIDURL @"/iphone/app/getid"
#define channelsURL @"/iphone/feed/list"
#define mobileAPILoggingRequest @"/iphone/log/save?AppId=%@&LogType=%@&Description=%@&ModuleName=%@&CodeLine=%d"

@interface NSDictionary (mobileAPI) 
- (BOOL)isSuccess;
@end
