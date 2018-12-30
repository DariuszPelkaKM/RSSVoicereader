//
//  SavedArticle.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.06.21.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Article.h"
#import "Channel.h"

#define kArticleSaveRequestNotification @"kArticleSaveRequestNotification"

@interface SavedArticle : Article {
	Channel *channel;
}
@property (nonatomic, copy, setter=setChannel:) Channel *channel;

+ (id)savedArticleWithArticle:(Article *)article andChannel:(Channel *)channel;
- (void)save;

@end
