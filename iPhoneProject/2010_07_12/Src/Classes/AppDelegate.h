//
//  AppDelegate.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.27.
//  Copyright ANTiSoftware 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import "JSON.h"
#import "SoundEffect.h"

#define kRefreshRateChangedNotification @"kRefreshRateChangedNotification"
#define kRemoveDeadlineChangedNotification @"kRemoveDeadlineChangedNotification"
#define kOnlyWiFiAllowedChangedNotification @"kOnlyWiFiAllowedChangedNotification"
#define kEnableSoundsChangedNotification @"kEnableSoundsChangedNotification"
#define kLastURLChangedNotification @"kLastURLChangedNotification"
#define kCellSelectedNotification @"kCellSelectedNotification"

@interface AppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, UITabBarDelegate> {
	UIWindow *window;
	UITabBarController *tabBarController;
	Reachability *internetReachability;
	Reachability *WiFiReachability;
	//Reachability *hostReachability;
	
	NSArray *tabTitles;
	
	// settings
	NSTimeInterval refreshRate;
	NSTimeInterval removeDeadline;
	BOOL onlyWiFiAllowed;
	BOOL enableSounds;
	
	// browser
	NSString *lastURL;
	
	// global
	NSString *appID;
	NSMutableData *data;
	
	// sounds
	SoundEffect *welcomeSound;
	SoundEffect *goodbyeSound;
	SoundEffect *tapSound;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, setter=setRefreshRate:) NSTimeInterval refreshRate;
@property (nonatomic, setter=setRemoveDeadline:) NSTimeInterval removeDeadline;
@property (nonatomic, setter=setOnlyWiFiAllowed:) BOOL onlyWiFiAllowed;
@property (nonatomic, setter=setEnableSounds:) BOOL enableSounds;
@property (nonatomic, setter=setLastURL:, copy) NSString *lastURL;
@property (nonatomic, setter=setAppID:, copy) NSString *appID;

- (BOOL)isInternetAvailable;
- (void)loadAppID;
- (void)warnAboutNoConnectivity;
- (void)error:(NSString *)title message:(NSString *)msg delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles;
- (void)warning:(NSString *)title message:(NSString *)msg delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles;
- (void)info:(NSString *)title message:(NSString *)msg delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles;

@end
