//
//  SavedArticle.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.06.21.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "SavedArticle.h"


@implementation SavedArticle

@synthesize channel;

+ (id)savedArticleWithArticle:(Article *)article andChannel:(Channel *)channel {
	SavedArticle *result = [[[super alloc] init] autorelease];
	result.data = [article data];
	result.stamp = [article stamp];
	result.stampStr = [article stampStr];
	result.title = [article title];
	result.uniqueID = [article uniqueID];
	result.url = [article url];
	result.visited = article.visited;
	result.content = [article content];
	[result setChannel:channel];
	return result;
}

- (void)setChannel:(Channel *)value {
	NSMutableArray *articles = [channel articles];
	[articles removeObject:self];
	channel = [Channel channelNamed:[value title] url:[value url]];
	[channel retain];
	articles = [channel articles];
	if ([articles indexOfObject:self] == NSNotFound)
		[articles addObject:self];
}

- (void)save {
	[[NSNotificationCenter defaultCenter] postNotificationName:kArticleSaveRequestNotification object:self]; 
}

@end
