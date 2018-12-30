//
//  NewsController.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.29.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "NewsController.h"
#import "ArticleController.h"

@implementation NewsController

@synthesize channel, app;

/*- (id)init {
	id result = [super init];
	sections = [[NSMutableArray array] retain];
	return result;
}*/

- (AppDelegate *)app {
	AppDelegate *result = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	return result;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
																						 initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshNews)] 
																						autorelease];
	self.navigationItem.rightBarButtonItem.enabled = [self.app isInternetAvailable] && ![UIApplication sharedApplication].networkActivityIndicatorVisible;
	if ([self.app isInternetAvailable] && [[[self tabBarController] selectedViewController] isEqual:[self navigationController]]) 
		[self.channel reload];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(internetReachabilityChanged:) 
																							 name:kReachabilityChangedNotification 
																						 object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(articleChanged:) 
																							 name:kArticleChangedNotification 
																						 object:nil];
	[[UIApplication sharedApplication] addObserver:self forKeyPath:@"networkActivityIndicatorVisible" options:0 context:nil];
}

- (void)internetReachabilityChanged:(NSNotification *)note {
	//app = [note object];
	self.navigationItem.rightBarButtonItem.enabled = [self.app isInternetAvailable] && ![UIApplication sharedApplication].networkActivityIndicatorVisible;
	if ([self.app isInternetAvailable] && [[[self tabBarController] selectedViewController] isEqual:[self navigationController]]) 
		[self.channel reload];
}

- (void)setChannel:(Channel *)value {
	if (![channel isEqual:value]) {
		channel = value;
		[channel retain];
		self.channel.delegate = self;
		//[self.channel addObserver:self forKeyPath:@"articles" options:0 context:nil];
		if ([self.app isInternetAvailable]) 
			[self.channel reload];
	}
}

- (NSDate *)dayOf:(NSDate *)date {
	unsigned flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:flags fromDate:date];
	return [calendar dateFromComponents:components];
}

- (BOOL)isTheSameDay:(NSDate *)date1 as:(NSDate *)date2 {
	return [[self dayOf:date1] isEqualToDate:[self dayOf:date2]];
}

- (void)articleChanged:(NSNotification *)note {
	Article	*article = [note object];
	if ([article isKindOfClass:[Article class]]) {
		[self updateInterfaceWithArticle:article];
	}
}

- (void)updateInterfaceWithArticle:(Article	*)article {
	//[self.tableView reloadData]; // TODO (focus on specific article only)
	int i = [[channel articles] indexOfObject:article];
	if (i >= 0 && i < [[channel articles] count])
		[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

// listen for changes to the article list coming from outside.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	if ([keyPath isEqualToString:@"networkActivityIndicatorVisible"]) {
		[self performSelectorOnMainThread:@selector(updateRefreshButton)
													 withObject:nil
												waitUntilDone:NO];
	}
	else
		[self performSelectorOnMainThread:@selector(reloadTableData)
													 withObject:nil
												waitUntilDone:NO];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return YES;//(interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	//[self.channel removeObserver:self forKeyPath:@"articles"];
	[[NSNotificationCenter defaultCenter] removeObserver:self 
																							 name:kReachabilityChangedNotification 
																						 object:nil];	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
																							 name:kArticleChangedNotification 
																						 object:nil];
}


- (void)dealloc {
	//[self.channel removeObserver:self forKeyPath:@"articles"];
	[sections release]; 
	[super dealloc];
}

- (IBAction)refreshNews {
	[self.channel reload];
}

- (void)reloadTableData {
	[self.tableView	reloadData];
}

- (void)beginTableUpdates {
	[self.tableView	beginUpdates];
}

- (void)endTableUpdates {
	[self.tableView	endUpdates];
}

- (void)updateRefreshButton {
	self.navigationItem.rightBarButtonItem.enabled = [self.app isInternetAvailable] && ![UIApplication sharedApplication].networkActivityIndicatorVisible;
}

- (void)showArticle:(Article *)article animated:(BOOL)animated {
	if (![self.app isInternetAvailable]) {
		[self.app warnAboutNoConnectivity];
		[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
		return;
	}
	
	if (article) {
		ArticleController *articleController = [[[ArticleController alloc] init] autorelease];
		//articleController.url = article.url;
		articleController.delegate = self;
		articleController.article = article;
		articleController.channel = self.channel;
		articleController.allowArticleSaving = YES;
		//articleController.app = app;
		//[articleController.navigationItem setTitle:[table cellForRowAtIndexPath:indexPath].textLabel.text];
		[[self navigationController] pushViewController:articleController animated:animated];
		//article.visited = YES;
	}
}

#pragma mark -
#pragma mark Table view methods

/*- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self groupCount];
}*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[channel articles] count]; // TODO
}

/*- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSDate *date;
	if (section == 0) 
		date = [NSDate date];
	else
		date = [[NSDate date] addTimeInterval:-24*3600];
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterLongStyle];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	NSString *s = [formatter stringFromDate:date];
	[formatter release];
	return s;
}*/

- (void)sortArticles {
	if (channel) {
		[channel.articles sortUsingSelector:@selector(compareWith:)];
	}
}

- (int)groupCount {
	int result = 1;
	[self sortArticles];
	NSDate *lastDate = [NSDate distantPast];
	for (Article *article in channel.articles) {
		if (![article.stamp isEqualToDate:lastDate]) {
			result++;
			lastDate = article.stamp;
		}
	}
	
	return result;
}

- (Article *)articleAtIndexPath:(NSIndexPath *)path {
	/*
	// finding first item in the group indicated by path
	int groupCount = 0;
	NSDate *lastDate = [NSDate distantPast];
	Article *article = nil;
	NSArray *articles = [self.channel articles];
	int i;
	for (i=0; i<[articles count]; i++) {
		article = [articles objectAtIndex:i];
		if (![self isTheSameDay:[article stamp] as:lastDate]) {
			if (path.section == groupCount)
				break;
			
			lastDate = [article stamp];
			groupCount++;
		}
	}
	
	// searching article indicated by path inside the found group
	if ([articles count] <= i+path.row || [articles count] == 0)
		return nil;
	
	Article *article2 = [articles objectAtIndex:i+path.row];
	if (article2 && [self isTheSameDay:lastDate as:[article2 stamp]])
		return article2;
	else
		return nil;*/
	int i=path.row;
	if (i >= 0 && i < [[channel articles] count])
		return [[channel articles] objectAtIndex:i];
	else
		return nil;
	
	//return [[channel articles] objectAtIndex:path.row];
}

static NSString *newsCell = @"ANTiSoftware.RSSReader.newsCell";

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = nil;
	Article *article = [self articleAtIndexPath:indexPath];
	
	cell = [table dequeueReusableCellWithIdentifier:newsCell];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:newsCell] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.textLabel.numberOfLines = 2;
		cell.textLabel.font = [UIFont systemFontOfSize:14];
	}
	cell.textLabel.text = [article title];
	if (![article visited])
		cell.imageView.image = [UIImage imageNamed:@"blueDot2.png"];
	else
		cell.imageView.image = [UIImage imageNamed:@"empty.png"];
	
	return cell;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[[NSNotificationCenter defaultCenter] postNotificationName:kCellSelectedNotification object:self];
	
	Article *article = [self articleAtIndexPath:indexPath];
	[self showArticle:article animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)table editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleDelete;
}

#pragma mark -
#pragma mark ArticleControllerDelegate

- (Article *)canLoadPreviousArticleTo:(Article *)currentArticle {
	int i = [[self.channel articles] indexOfObject:currentArticle];
	if ((i != -1) && (i > 0) && (i < [[self.channel articles] count]))
		return [[self.channel articles] objectAtIndex:i-1];
	
	return nil;
}

- (Article *)canLoadNextArticleTo:(Article *)currentArticle {
	int i = [[self.channel articles] indexOfObject:currentArticle];
	if ((i != -1) && (i >= 0) && (i < [[self.channel articles] count] - 1))
		return [[self.channel articles] objectAtIndex:i+1];
	
	return nil;
}

#pragma mark -
#pragma mark ChannelDelegate

- (void)channelWillLoad:(Channel *)channel {
	//[self.tableView beginUpdates];
}

- (void)channelDidFinishLoading:(Channel *)channel {
	//[self.tableView endUpdates];
	[self performSelectorOnMainThread:@selector(updateRefreshButton)
												 withObject:nil
											waitUntilDone:NO];
}

- (void)articlesChangedInChannel:(Channel *)channel {
	[self performSelectorOnMainThread:@selector(reloadTableData)
												 withObject:nil
											waitUntilDone:NO];
}

@end
