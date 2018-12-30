//
//  ArticleController.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.29.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <MessageUI/MFMailComposeViewController.h>
#import "Article.h"
#import "Channel.h"

@protocol ArticleControllerDelegate;
@class ArticleHeaderView;

@interface ArticleController : UIViewController <UIActionSheetDelegate, UIWebViewDelegate, MFMailComposeViewControllerDelegate> {
	id<ArticleControllerDelegate> delegate;
	UIWebView *webView;
	UIBarButtonItem *rightButtonItem;
	CGRect textFieldRect;
	UIImageView *imageView;
	//NSString *url;
	Article *article;
	ArticleHeaderView *headerView;
	Channel *channel;
	BOOL allowArticleSaving;
}

@property (nonatomic, assign) IBOutlet UIWebView *webView;
//@property (nonatomic, copy) NSString *url;
@property (nonatomic, retain, setter=setArticle:) Article *article;
@property (nonatomic, retain) id<ArticleControllerDelegate> delegate;
@property (nonatomic, retain) Channel *channel;
@property (nonatomic) BOOL allowArticleSaving;
//@property (nonatomic, assign) IBOutlet UIImageView *imageView;

- (IBAction)showActionSheet;
- (IBAction)enterURLEditing;
- (IBAction)leaveURLEditing;
- (IBAction)cancelEditing;
- (IBAction)upDownTapped;
@end

@interface ArticleHeaderView : UIView {
	UISegmentedControl *upDown;
	UILabel *label;
	UISegmentedControl *cancel;
	UITextField *textField;
}
@property (nonatomic, retain) IBOutlet UISegmentedControl *upDown;
@property (nonatomic, retain) IBOutlet UISegmentedControl *cancel;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UITextField *textField;
@end

@interface ArticleHeaderViewController : UIViewController {
}
@end

@protocol ArticleControllerDelegate
- (Article *)canLoadPreviousArticleTo:(Article *)currentArticle;
- (Article *)canLoadNextArticleTo:(Article *)currentArticle;
//- (void)loadPreviousArticleTo:(Article *)currentArticle;
//- (void)loadNextArticleTo:(Article *)currentArticle;
@end


