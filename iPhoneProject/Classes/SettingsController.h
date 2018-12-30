//
//  SettingsController.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.29.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ValueTableController.h"
#import "AppDelegate.h"

@interface SettingsController : UITableViewController <ValueTableControllerDelegate> {
	NSDictionary *refreshRateValues;
	NSDictionary *removeDeadlineValues;
	AppDelegate *app;
	NSString *refreshRateKey;
	NSString *removeDeadlineKey;
	BOOL onlyWiFiAllowed;
	BOOL enableSounds;
	//UISwitch *onlyWiFiAllowedSwitch;
	//UISwitch *enableSoundsSwitch;
}

@end
