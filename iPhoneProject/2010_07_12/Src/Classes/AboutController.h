//
//  About.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.29.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutController : UIViewController <UIWebViewDelegate> {
	UIWebView *webView;
}

@property (nonatomic, assign) IBOutlet UIWebView *webView;

@end
