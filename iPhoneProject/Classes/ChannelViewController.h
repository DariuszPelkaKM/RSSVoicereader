//
//  AddChannelView.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.28.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Channel.h"

@protocol ChannelViewControllerDelegate;

@interface ChannelViewController : UIViewController {
	id<ChannelViewControllerDelegate> delegate;
	UITextField *channelName;
	UITextField *channelURL;
	UILabel *channelNameLabel;
	UILabel *channelURLLabel;
	UINavigationBar *navigationBar;
	UIBarButtonItem *cancelButton;
	UIBarButtonItem *doneButton;

	Channel *channel;
}
@property (nonatomic, assign) IBOutlet UITextField *channelName;
@property (nonatomic, assign) IBOutlet UITextField *channelURL;
@property (nonatomic, assign) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, assign) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, assign) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, assign) IBOutlet UILabel *channelNameLabel;
@property (nonatomic, assign) IBOutlet UILabel *channelURLLabel;
@property (nonatomic, assign) id<ChannelViewControllerDelegate> delegate;
@property (nonatomic, retain) Channel *channel;

- (IBAction)dismiss;
- (IBAction)done;

@end

@protocol ChannelViewControllerDelegate
- (BOOL)channelViewControllerWillFinish:(ChannelViewController *)viewController withChannel:(Channel *)channel;
@end

