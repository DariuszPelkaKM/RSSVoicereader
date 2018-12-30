//
//  ChannelsViewController.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.27.
//  Copyright ANTiSoftware 2010. All rights reserved.
//

#import "ChannelsViewController.h"
#import "NewsController.h"
#import "Channel.h"
#import "Reachability.h"
#import "JSON.h"
#import "mobileAPI.h"
#import <CFNetwork/CFNetwork.h>

@implementation ChannelsViewController

@synthesize refreshTimer, newsViewControllers;

- (NSString *)applicationDocumentsDirectory {
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"channels.archive"];
}

- (id)init {
	self = [super init];
	return self;
}

- (NSMutableDictionary *)newsViewControllers {
	if (!newsViewControllers)
		newsViewControllers = [[[NSMutableDictionary alloc] init] retain];
	return newsViewControllers;
}

- (void)viewDidLoad {
	//[super viewDidLoad];
	self.navigationItem.title = NSLocalizedString(@"ChannelsTitle", @"");
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// read channels from archive
	NSMutableArray *oldSavedArray = [NSKeyedUnarchiver unarchiveObjectWithFile:[self applicationDocumentsDirectory]];
	if (oldSavedArray != nil) {
		if (channels != nil)
			[channels release];
		
		channels = [NSMutableArray arrayWithArray:oldSavedArray];
		[channels retain];
	}
	
	if (!channels) {
		NSData *readData = [defaults objectForKey:@"channels"];
		if (readData != nil) {
			NSMutableArray *oldSavedArray = [NSKeyedUnarchiver unarchiveObjectWithData:readData];
			if (oldSavedArray != nil) {
				if (channels != nil)
					[channels release];
				
				channels = [NSMutableArray arrayWithArray:oldSavedArray];
				[channels retain];
			}
		}
	}
	
	if (!channels) {
		channels = [[[NSMutableArray alloc] init] retain];
	}
	channelsBeingEdited = NO;
	
	channelURLs = [[NSMutableDictionary dictionary] retain];
	for (Channel *ch in channels) {
		[channelURLs setObject:ch forKey:[ch url]];
	}
	
	// try to download default channels
	builtInChannels = [defaults objectForKey:@"builtInChannels"];
	if (builtInChannels) {
		[channels addObjectsFromArray:builtInChannels];
	}
	else {
		// load channel definitions from server
		NSString *channelsString = [NSString stringWithFormat:@"%@%@", mobileAPIURL, channelsURL];
		NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:channelsString]];
		[[[NSURLConnection alloc] initWithRequest:urlRequest delegate:self] autorelease];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(internetReachabilityChanged:) 
																							 name:kReachabilityChangedNotification 
																						 object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(refreshRateChanged:) 
																							 name:kRefreshRateChangedNotification 
																						 object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(channelChanged:) 
																							 name:kChannelChangedNotification 
																						 object:nil];	
	
	/*if (internetAvailable) {
	 for (Channel *channel in channels) {
	 [channel reload];
	 }
	 }*/
}

- (void)saveChannels {
	/* the simplest possible saving but without hierarchy
	 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	 [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:channels] forKey:@"channels"];
	 [defaults	synchronize];*/
	
	// saving based on archivers
	BOOL result = [NSKeyedArchiver archiveRootObject:channels toFile:[self applicationDocumentsDirectory]];
	if (!result) {
		UIAlertView *dialog = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", @"") 
																											message:NSLocalizedString(@"storingSessionsFailedMsg", @"") 
																										 delegate:self 
																						cancelButtonTitle:NSLocalizedString(@"OK", @"")
																						otherButtonTitles:nil] autorelease];
		[dialog show];
	}	
}

- (void)internetReachabilityChanged:(NSNotification *)note
{
	app = [note object];
	internetAvailable = [app isInternetAvailable];
	if (internetAvailable && [[self.tabBarController selectedViewController] isEqual:self.navigationController]) {
		for (Channel *channel in channels) {
			//[channel reload];
		}
	}
}

- (void)refreshRateChanged:(NSNotification *)note {
	app = [note object];
	if ([self.refreshTimer isValid]) 
		[self.refreshTimer invalidate]; // removing old timer (if any)
	if (app.refreshRate > 0) {
		refreshTimer = [[NSTimer timerWithTimeInterval:app.refreshRate target:self	selector:@selector(refreshTimerTick:) userInfo:nil repeats:YES] retain];
		[[NSRunLoop currentRunLoop] addTimer:refreshTimer forMode:NSDefaultRunLoopMode];
	}
}

- (void)channelChanged:(NSNotification *)note {
	[self saveChannels];
}

- (void)refreshTimerTick:(NSTimer*)timer {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (internetAvailable) {
		for (Channel *channel in channels) {
			[channel reload];
		}
	}
	[pool release];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return YES;// || (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self 
																									name:kReachabilityChangedNotification 
																								object:nil];	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
																									name:kRefreshRateChangedNotification 
																								object:nil];	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
																									name:kChannelChangedNotification 
																								object:nil];	
}

/*- (void)viewWillAppear:(BOOL)animated {
 [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
 }*/


- (void)dealloc {
	[channelURLs release];
	[self.newsViewControllers release];
	[channels release];
	[super dealloc];
}

- (IBAction) toggleEditingMode {
	[self.tableView setEditing:!self.tableView.editing animated:YES];
	channelsBeingEdited = self.tableView.editing;
	if (self.tableView.editing) {
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
																							initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																							target:self action:@selector(toggleEditingMode)] autorelease];
	}	else {
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
																							initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
																							target:self action:@selector(toggleEditingMode)] autorelease];
	}
}

- (IBAction)addChannel {
	ChannelViewController *newChannelView = [[[ChannelViewController alloc] initWithNibName:@"ChannelView" bundle:nil] autorelease];
	newChannelView.delegate = self;
	newChannelView.channel = [Channel channelNamed:@"" url:@""];
	[self presentModalViewController:newChannelView animated:YES];
}

#pragma mark -
#pragma mark ChannelViewControllerDelegate

- (BOOL)channelViewControllerWillFinish:(ChannelViewController *)viewController withChannel:(Channel *)channel {
	if (!channel.title || !channel.url)
		return NO;
	
	channel.title = [channel.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	channel.url = [channel.url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([channel.title isEqualToString:@""] || [channel.url isEqualToString:@""]) {
		// show error msg
		return NO;
	}
	
	[self.tableView beginUpdates];
	int i = [channels indexOfObject:channel];
	if (i < 0 || i >= [channels count]) {
		[channels addObject:channel];
		// we have to distinguish edit/non-edit mode, as edit mode may contain reordering parts which are not properly updated if only
		// the currently added row is being refreshed
		if ([self.tableView isEditing])
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
		else
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:[channels count]-1 inSection:0], nil] withRowAnimation:UITableViewRowAnimationFade];
	}
	else {
		[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:i inSection:0], nil] withRowAnimation:UITableViewRowAnimationNone];
	}
	[self.tableView endUpdates];
	
	[self saveChannels];
	[channel reload];
	
	return YES;
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

//static int channelCount = 3;

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [channels count];
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return ([channels count] > 1);
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	if (sourceIndexPath == destinationIndexPath)
		return;
	
	Channel *ch = [[channels objectAtIndex:sourceIndexPath.row] retain];
	[channels removeObjectAtIndex:sourceIndexPath.row];
	[channels insertObject:ch atIndex:destinationIndexPath.row];
	[self saveChannels];
}

static NSString *channelCell = @"ANTiSoftware.RSSReader.channelCell";
//static NSString *addChannelCell = @"ANTiSoftware.RSSReader.addChannelCell";

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = nil;
	//NSDate *time;
	
	/*if (indexPath.row == channelCount - 1) {
	 cell = [table dequeueReusableCellWithIdentifier:addChannelCell];
	 if (cell == nil) {
	 cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addChannelCell] autorelease];
	 cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	 cell.textLabel.text = NSLocalizedString(@"AddNewChannel", @"");
	 }
	 }
	 else*/ {
		 cell = [table dequeueReusableCellWithIdentifier:channelCell];
		 if (cell == nil) {
			 cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:channelCell] autorelease];
			 cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			 cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
			 cell.showsReorderControl = YES;//[table isEditing];
		 }
		 
		 /*switch (indexPath.row) {
			case 0:
			cell.textLabel.text = @"Onet wiadomości dnia";
			cell.detailTextLabel.text = @"http://wiadomosci.onet.pl/2,kategoria.rss";
			break;
			case 1:
			cell.textLabel.text = @"Onet kraj";
			cell.detailTextLabel.text = @"http://wiadomosci.onet.pl/11,kategoria.rss";
			break;
			case 2:
			cell.textLabel.text = @"Onet biznes";
			cell.detailTextLabel.text = @"http://wiadomosci.onet.pl/10,kategoria.rss";
			break;
			}*/
		 Channel *channel = [channels objectAtIndex:indexPath.row];
		 if (channel) {
			 cell.textLabel.text = channel.title;
			 cell.detailTextLabel.text = channel.url;
		 }
	 }
	return cell;
}

/*- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 if (indexPath.section > 1)
 return nil;
 else
 return indexPath;
 }*/

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NewsController *news;
	Channel *channel = [channels objectAtIndex:indexPath.row];
	news = [self.newsViewControllers objectForKey:[channel url]];
	if (!news) {
		news = [[[NewsController alloc] init] autorelease];
		[self.newsViewControllers setObject:news forKey:[channel url]];
		
		news.app = app;
		[news.navigationItem setTitle:[table cellForRowAtIndexPath:indexPath].textLabel.text];
		
		[news addObserver:self forKeyPath:@"articles" options:0 context:NULL];
		news.channel = [channels objectAtIndex:indexPath.row];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kCellSelectedNotification object:self];
	
	[news.channel reload];
	[[self navigationController] pushViewController:news animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)table editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleDelete;
}

- (void)removeChannelAtIndexPath:(NSIndexPath *)indexPath {
	[channels removeObjectAtIndex:indexPath.row];
	NSArray *paths = [NSArray arrayWithObject:indexPath];
	[self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
	[self saveChannels];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		if (!cell)
			return;
		
		if (channelsBeingEdited) {
			// no need to display a warning
			[self removeChannelAtIndexPath:indexPath];
			return;
		}
		
		// display alert to make sure
		channelBeingRemoved = indexPath;
		removingChannelAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"RemovingChannelTitle", @"") 
																											 message:NSLocalizedString(@"RemovingChannelMsg", @"")
																											delegate:self 
																						 cancelButtonTitle:NSLocalizedString(@"CancelBtnTitle", @"") 
																						 otherButtonTitles:NSLocalizedString(@"RemoveBtnTitle", @""), nil] autorelease];
		[removingChannelAlert show];	
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	ChannelViewController *channelView = [[[ChannelViewController alloc] initWithNibName:@"ChannelView" bundle:nil] autorelease];
	channelView.delegate = self;
	channelView.channel = [channels objectAtIndex:indexPath.row];
	[[self navigationController] pushViewController:channelView animated:YES];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (alertView == removingChannelAlert) {
		if (buttonIndex > 0) {
			[self removeChannelAtIndexPath:channelBeingRemoved];
		}
	}
}

#pragma mark -
#pragma mark NSURLConnection methods

- (void)handleError:(NSError *)error {
	NSString *errorMessage = [error localizedDescription];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LoadingBuiltInChannedlsErrorTitle", @"")
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
	
	if (!builtInChannels)
		builtInChannels = [[NSMutableArray array] retain];
	else
		[builtInChannels removeAllObjects];

	if (data) {
		NSString *jsonString = [NSString stringWithCString:data.mutableBytes length:[data length]];
		NSLog(@"%@", jsonString);
		NSDictionary *result = [jsonString JSONValue];
		if ([result isSuccess]) { 
			BOOL needsUpdate = NO;
			NSArray *_data = [result objectForKey:kJSONKeyData];
			for (NSDictionary *country in _data) {
				NSArray *providers = [country objectForKey:kJSONKeyChildren];
				for (NSDictionary *provider in providers) {
					NSArray *categories = [provider objectForKey:kJSONKeyChildren];
					for (NSDictionary *category in categories) {
						NSArray *feeds = [category objectForKey:kJSONKeyFeeds];
						for (NSDictionary *feed in feeds) {
							Channel *ch = [Channel channelNamed:[NSString stringWithFormat:@"%@ (%@ %@, %@)", [feed objectForKey:kJSONKeyName], [provider objectForKey:kJSONKeyName], [category objectForKey:kJSONKeyName], [country objectForKey:kJSONKeyName]] 
																							url:[feed objectForKey:kJSONKeyURL] 
																						 data:nil];
							if (![channelURLs objectForKey:[ch url]]) {
								[channels addObject:ch];
								needsUpdate = YES;
							}
								//[builtInChannels addObject:ch];
						}
					}
				}
			}
			if (needsUpdate)
				[self.tableView reloadData];
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


@end
