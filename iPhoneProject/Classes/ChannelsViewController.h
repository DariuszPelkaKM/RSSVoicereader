//
//  ChannelsViewController.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.27.
//  Copyright ANTiSoftware 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChannelViewController.h"
#import "AppDelegate.h"

@interface ChannelsViewController : UITableViewController <ChannelViewControllerDelegate, UIAlertViewDelegate> {
	NSMutableArray *channels;
	NSMutableDictionary *channelURLs;
	BOOL channelsBeingEdited;
	BOOL internetAvailable;
	UIAlertView *removingChannelAlert;
	NSIndexPath *channelBeingRemoved;
	NSTimer *refreshTimer;
	AppDelegate *app;
	
	NSMutableDictionary *newsViewControllers;
	
	// data for loading predefined channels from server
	NSMutableData *data;
	NSMutableArray *builtInChannels;
}
@property (nonatomic, readonly, retain) NSTimer *refreshTimer;
@property (nonatomic, retain) NSMutableDictionary *newsViewControllers;

- (IBAction)toggleEditingMode;
- (IBAction)addChannel;

- (void)removeChannelAtIndexPath:(NSIndexPath *)indexPath;

@end
