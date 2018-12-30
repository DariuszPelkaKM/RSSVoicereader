//
//  Channel.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.05.09.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Article.h"

#define kChannelChangedNotification @"kChannelChangedNotification"

@protocol ChannelDelegate;

// class designed to be a RSS channel definition, which holds a list of articles
@interface Channel : NSObject <NSCoding> {
	id<ChannelDelegate> delegate;
	NSString *title;
	NSString *url;
	NSMutableData *data;
	NSURLConnection *feedConnection;
	Article *currentArticle;
	NSMutableString *currentParsedCharacterData;
	NSMutableArray *currentParseBatch;
	BOOL reloading;

	NSMutableArray *articles;
	NSMutableArray *oldArticles;
	NSMutableDictionary *articleIDs;
	BOOL accumulatingParsedCharacterData;
	NSUInteger parsedArticleCounter;
	BOOL lockChangesNotifications;
}
@property (nonatomic, copy) NSString *title;
@property (nonatomic, retain, setter=setURL:) NSString *url;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) NSURLConnection *feedConnection;
@property (nonatomic, retain) Article *currentArticle;
@property (nonatomic, retain) NSMutableString *currentParsedCharacterData;
@property (nonatomic, retain) NSMutableArray *currentParseBatch;
@property (nonatomic, retain) NSMutableArray *articles; 
@property (nonatomic, retain) NSMutableArray *oldArticles; 
@property (nonatomic, retain) NSMutableDictionary *articleIDs;
@property (nonatomic, readonly) BOOL reloading;
@property (nonatomic, retain) id<ChannelDelegate> delegate;

+ (id)channelNamed:(NSString *)name url:(NSString *)url;
+ (id)channelNamed:(NSString *)name url:(NSString *)url data:(NSData *)data;
- (void)reload;
- (void)setURL:(NSString *)value;

@end

@protocol ChannelDelegate
- (void)channelWillLoad:(Channel *)channel;
- (void)channelDidFinishLoading:(Channel *)channel;
- (void)articlesChangedInChannel:(Channel *)channel;
@end

