//
//  BrowserController.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.05.01.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface BrowserController : UIViewController <UIWebViewDelegate, UITextFieldDelegate> {
	UIWebView *webView;
	UITextField *urlField;
	UIBarButtonItem *backButton;
	UIBarButtonItem *reloadButton;
	BOOL internetConnectionAvailable;
	BOOL lockURLUpdate;
	BOOL lockURLNotification;
	NSString *lastURL;
	AppDelegate *app;
}
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UITextField *urlField;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *reloadButton;
@property (nonatomic, retain) AppDelegate *app;

- (IBAction)enterURLEditing;
- (IBAction)leaveURLEditing;
- (IBAction)urlChanged;
- (IBAction)reload;
- (IBAction)back;

- (void)loadURL:(NSString *)urlString;

@end
