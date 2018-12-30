//
//  Article.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.06.12.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "Article.h"


@implementation Article

@synthesize title, url, data, stamp, visited, uniqueID, content, stampStr;

+ (id)articleNamed:(NSString *)name url:(NSString *)url {
	return [Article articleNamed:name url:url stamp:[NSDate date] data:nil];
}

+ (id)articleNamed:(NSString *)name url:(NSString *)url stamp:(NSDate *)stamp {
	return [Article articleNamed:name url:url stamp:stamp data:nil];
}

+ (id)articleNamed:(NSString *)name url:(NSString *)url stamp:(NSDate *)stamp data:(NSData *)data {
	Article *result = [[[super alloc] init] autorelease];
	result.title = [name copy];
	result.url = [url copy];
	result.stamp = [stamp copy];
	result.stampStr = [result.stamp description];
	result.data = [data copy];
	result.visited = NO;
	return result;
}

- (void)setVisited:(BOOL)value {
	BOOL prevVisited = visited;
	visited = value;
	if (prevVisited != visited && !loading) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kArticleChangedNotification object:self]; 
	}
}

- (void)setURL:(NSString *)value {
	[url release];
	url = [value copy];
}


- (void)setData:(NSMutableData *)value {
	[data release];
	data = [value copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:kArticleChangedNotification object:self]; 
}

- (void)setContent:(NSString *)value {
	content = [value copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:kArticleChangedNotification object:self]; 
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self != nil) {
		loading = YES;
		self.title = [[decoder decodeObjectForKey:@"title"] copy];
		self.url = [[decoder decodeObjectForKey:@"url"] copy];
		self.stamp = [[decoder decodeObjectForKey:@"stamp"] copy];
		self.stampStr = [[decoder decodeObjectForKey:@"stampStr"] copy];
		self.data = [[decoder decodeObjectForKey:@"data"] copy];
		self.visited = [decoder decodeBoolForKey:@"visited"];
		self.uniqueID = [[decoder decodeObjectForKey:@"uniqueID"] copy];
		self.content = [[decoder decodeObjectForKey:@"content"] copy];
		loading = NO;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:title forKey:@"title"];
	[encoder encodeObject:url forKey:@"url"];
	[encoder encodeObject:stamp forKey:@"stamp"];
	[encoder encodeObject:stampStr forKey:@"stampStr"];
	[encoder encodeObject:data forKey:@"data"];
	[encoder encodeBool:visited forKey:@"visited"];
	[encoder encodeObject:uniqueID forKey:@"uniqueID"];
	[encoder encodeObject:content forKey:@"content"];
}

- (NSComparisonResult)compareWith:(Article *)article {
	NSComparisonResult result = ([self.stamp compare:article.stamp]);
	if (result == NSOrderedSame)
		return [[self title] compare:[article title] options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
	else
		return -result;
}

- (void)dealloc {
	[title release];
	[url release];
	[stamp release];
	[data release];
	
	[super dealloc];
}

@end

// -------------------------------------------

@implementation ArticleGroup

@synthesize date, articles;

- (NSMutableArray *)articles {
	if (articles == nil)
		articles = [[[NSMutableArray alloc] init] retain];
	
	return articles;
}

- (NSDate *)date {
	if (date == nil)
		date = [[NSDate date] retain];
	
	return date;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super init];
	if (self != nil) {
		self.date = [[decoder decodeObjectForKey:@"date"] copy];
		[self.articles addObjectsFromArray:[decoder decodeObjectForKey:@"articles"]];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:self.date forKey:@"date"];
	[encoder encodeObject:self.articles forKey:@"articles"];
}

- (void)dealloc {
	[self.articles release];
	[self.date release];
	[super dealloc];
}

@end

