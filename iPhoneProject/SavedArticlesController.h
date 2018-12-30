//
//  SavedArticlesController.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.06.19.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "ArticleController.h"


@interface SavedArticlesController : UITableViewController <ArticleControllerDelegate> {
	NSMutableArray *savedChannels;
	AppDelegate *app;
}
@property (nonatomic, retain) NSMutableArray *savedChannels;

@end
