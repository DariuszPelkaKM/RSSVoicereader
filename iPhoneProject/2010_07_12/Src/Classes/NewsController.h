//
//  NewsController.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.29.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ArticleController.h"
#import "Channel.h"
#import "AppDelegate.h"

@interface NewsController : UITableViewController <ArticleControllerDelegate, ChannelDelegate> {
	Channel *channel;
	NSMutableArray *sections;
	AppDelegate *app;
}
@property (nonatomic, retain, setter=setChannel) Channel *channel;
@property (nonatomic, retain, readonly) AppDelegate *app;

- (IBAction)refreshNews;
- (void)updateInterfaceWithArticle:(Article *)article;
- (int)groupCount;
- (void)setChannel:(Channel *)value;


@end
