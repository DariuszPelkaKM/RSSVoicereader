//
//  AppDelegate.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.27.
//  Copyright ANTiSoftware 2010. All rights reserved.
//

#import "AppDelegate.h"
#import "Article.h"
#import <CFNetwork/CFNetwork.h>
#import "mobileAPI.h"

@implementation AppDelegate

@synthesize window;
@synthesize tabBarController, refreshRate, removeDeadline, onlyWiFiAllowed, enableSounds, lastURL, appID;

#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	
	internetReachability = [[Reachability reachabilityForInternetConnection] retain];
	[internetReachability startNotifer];
	
	//hostReachability = [[Reachability reachabilityWithHostName:@"www.xxx.pl"] retain]; TODO
	//[hostReachability startNotifer];
	
	// Add the tab bar controller's current view as a subview of the window
	[window addSubview:tabBarController.view];
	
	NSArray *tabs = [self tabBarController].tabBar.items;
	tabTitles = [[NSLocalizedString(@"TabTitles", @"") componentsSeparatedByString:@";"] copy];
	int i=0;
	for (UITabBarItem *tab in tabs) {
		tab.title = [tabTitles objectAtIndex:i];
		i++;
	}

	// setting the tab which was last selected
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	i = [defaults integerForKey:@"selectedTab"];
	if (i >= 0 && i < [[self	tabBarController].tabBar.items count]) {
		[self tabBarController].selectedIndex = i;
	}
	
	self.appID = [defaults objectForKey:@"appID"];
	if (!self.appID || [self.appID isEqualToString:@""])
		[self loadAppID];
		
	// initial settings
	refreshRate = 0;
	removeDeadline = 0;
	
	self.refreshRate = [defaults integerForKey:@"refreshRate"];
	self.removeDeadline = [defaults integerForKey:@"removeDeadline"];
	self.onlyWiFiAllowed = [defaults integerForKey:@"onlyWiFiAllowed"];
	enableSounds = YES; // this is only for brand new application
	self.enableSounds = [defaults integerForKey:@"enableSounds"];
	self.lastURL = [defaults objectForKey:@"lastURL"];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(articleChanged:) 
																							 name:kArticleChangedNotification 
																						 object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(playSound:) 
																							 name:kCellSelectedNotification 
																						 object:nil];	
	
	welcomeSound = [[[SoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"welcome" ofType:@"wav"]] retain];
	if (self.enableSounds)
		[welcomeSound play];
	goodbyeSound = [[[SoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"goodbye" ofType:@"wav"]] retain];
	tapSound = [[[SoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tap" ofType:@"aiff"]] retain];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	if (self.enableSounds) {
		[goodbyeSound play];
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]];
	}
	[goodbyeSound release];
}

- (void)articleChanged:(NSNotification *)note {
	/*Article	*article = [note object];
	if ([article isKindOfClass:[Article class]]) {
		[self updateInterfaceWithArticle:article];
	}*/
}

- (void)playSound:(NSNotification *)note {
	if (self.enableSounds)
		[tapSound play];
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
	//UINavigationItem *navItem = viewController.navigationItem;
	//navItem.title = [self tabBarController].tabBar.selectedItem.title;
	
	// store the currently selected tab (to be restored upon launch)
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[[self tabBarController] selectedIndex] forKey:@"selectedTab"];
	[defaults synchronize];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:self];
}

- (BOOL)isInternetAvailable {
	NetworkStatus netStatus = [internetReachability currentReachabilityStatus];
	if (self.onlyWiFiAllowed)
		return (netStatus == ReachableViaWiFi);
	else
		return (netStatus != NotReachable);
}

/*
 // Optional UITabBarControllerDelegate method
 - (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
 }
 */

- (void)setRefreshRate:(NSTimeInterval)value {
	refreshRate = value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:refreshRate forKey:@"refreshRate"];
	[defaults synchronize];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRefreshRateChangedNotification object:self];
}

- (void)setRemoveDeadline:(NSTimeInterval)value {
	removeDeadline = value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:removeDeadline forKey:@"removeDeadline"];
	[defaults synchronize];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRemoveDeadlineChangedNotification object:self];
}

- (void)setOnlyWiFiAllowed:(BOOL)value {
	onlyWiFiAllowed = value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:onlyWiFiAllowed forKey:@"onlyWiFiAllowed"];
	[defaults synchronize];
	[[NSNotificationCenter defaultCenter] postNotificationName:kOnlyWiFiAllowedChangedNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:self];
}

- (void)setEnableSounds:(BOOL)value {
	enableSounds = value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:enableSounds forKey:@"enableSounds"];
	[defaults synchronize];
	[[NSNotificationCenter defaultCenter] postNotificationName:kEnableSoundsChangedNotification object:self];
}

- (void)setLastURL:(NSString *)value {
	[lastURL release];
	lastURL = [[value copy] retain];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:lastURL forKey:@"lastURL"];
	[defaults synchronize];
	[[NSNotificationCenter defaultCenter] postNotificationName:kLastURLChangedNotification object:self];
}

- (void)setAppID:(NSString *)value {
	appID = value;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:appID forKey:@"appID"];
	[defaults synchronize];
}

- (void)loadAppID {
	NSString *appIDString = [NSString stringWithFormat:@"%@%@", mobileAPIURL, appIDURL];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:appIDString]];
	[[[NSURLConnection alloc] initWithRequest:urlRequest delegate:self] autorelease];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	//NSError *error;
	//appID = [NSString stringWithContentsOfURL:[NSURL URLWithString:appIDString] encoding:NSUTF8StringEncoding error:&error];
	//[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self 
																									name:kArticleChangedNotification 
																								object:nil];	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
																									name:kCellSelectedNotification 
																								object:nil];	
	[welcomeSound release];
	[data release];
	[lastURL release];
	[tabTitles release];
	[tabBarController release];
	[window release];
	[super dealloc];
}

#pragma mark -
#pragma mark NSURLConnection methods

- (void)handleError:(NSError *)error {
	NSString *errorMessage = [error localizedDescription];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LoadingAppIDErrorTitle", @"")
																											message:errorMessage
																										 delegate:nil
																						cancelButtonTitle:@"OK"
																						otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)_data {
	[data appendData:_data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	// check for HTTP status code for proxy authentication failures
	// anything in the 200 to 299 range is considered successful,
	// also make sure the MIMEType is correct:
	//
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	int statusCode = [httpResponse statusCode];
	NSString *mime = [response MIMEType];
	if (((statusCode/100) == 2) && [mime isEqual:@"plain/text"]) {
		data = [[NSMutableData data] retain];
	} 
	else {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:
															NSLocalizedString(@"HTTPError", @"Error message displayed when receving a connection error.")
																												 forKey:NSLocalizedDescriptionKey];
		NSError *error = [NSError errorWithDomain:@"HTTP" code:[httpResponse statusCode] userInfo:userInfo];
		[self handleError:error];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;   

	if (data) {
		NSString *jsonString = [NSString stringWithCString:data.mutableBytes length:[data length]];
		NSDictionary *result = [jsonString JSONValue];
		if ([result isSuccess]) { // TODO
			self.appID = [result objectForKey:kJSONKeyAppId];
		}
		[data release];
		data = nil;
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
	if ([error code] == kCFURLErrorNotConnectedToInternet) {
		// if we can identify the error, we can present a more precise message to the user.
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject: NSLocalizedString(@"No Connection Error", @"Error message displayed when not connected to the Internet.") forKey:NSLocalizedDescriptionKey];
		NSError *noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain
																										 code:kCFURLErrorNotConnectedToInternet
																								 userInfo:userInfo];
		[self handleError:noConnectionError];
	} else {
		// otherwise handle the error generically
		[self handleError:error];
	}
}


/*#pragma mark -
#pragma mark UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
	// store the currently selected tab (to be restored upon launch)
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[[self tabBarController] selectedIndex] forKey:@"selectedTab"];
	[defaults synchronize];
}*/

@end

