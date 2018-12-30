//
//  SavedArticlesController.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.06.19.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "SavedArticlesController.h"
#import "SavedArticle.h"

@implementation SavedArticlesController

@synthesize savedChannels;

- (NSString *)storedArticlesDirectory {
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"storedArticles.archive"];
}

- (NSMutableArray *)savedChannels {
	if (!savedChannels)
		savedChannels = [[NSMutableArray array] retain];
	return savedChannels;
}

- (void)save {
	[NSKeyedArchiver archiveRootObject:self.savedChannels toFile:[self storedArticlesDirectory]];
}

- (void)reload {
	NSMutableArray *oldSavedArray = [NSKeyedUnarchiver unarchiveObjectWithFile:[self storedArticlesDirectory]];
	if (oldSavedArray != nil) {
		
		// checking if articles have been stored enough long ago to remove
		BOOL changed = NO;
		if ([app removeDeadline]) {
			for (int j=0; j<[oldSavedArray count]; j++) {
				Channel *channel = [oldSavedArray objectAtIndex:j];
				for (int i=0; i<[[channel articles] count]; i++) {
					SavedArticle *article = [[channel articles] objectAtIndex:i];
					if ([[NSDate date] timeIntervalSinceDate:article.stamp] >= [app removeDeadline]) {
						[[channel articles] removeObject:article];
						i--;
						changed = YES;
					}
				}
				if ([[channel articles] count] == 0) {
					[oldSavedArray removeObject:channel];
					j--;
					changed = YES;
				}
			}
		}
		if (changed)
			[self save];
		
		if (savedChannels != nil)
			[savedChannels release];
		
		savedChannels = [NSMutableArray arrayWithArray:oldSavedArray];
		[savedChannels retain];
		
		/*for (Channel *channel in savedChannels) {
			for (SavedArticle *article in savedChannels)
				article.channel = channel;
		}*/
	}
	[self.tableView reloadData];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.navigationItem.title = NSLocalizedString(@"SavedTitle", @"");

	// read channels from archive
	[self reload];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(articleSaveRequest:) 
																							 name:kArticleSaveRequestNotification 
																						 object:nil];		
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(removeDeadlineChanged:) 
																							 name:kRemoveDeadlineChangedNotification 
																						 object:nil];	
}

- (void)articleSaveRequest:(NSNotification *)note {
	SavedArticle *savedArticle = [note object];
	Channel *channel = [savedArticle channel];
	if (!channel)
		return;
	
	for (Channel *ch in self.savedChannels) {
		if ([[ch url] isEqualToString:[channel url]]) {
			savedArticle.channel = ch;
			savedArticle.stamp = [NSDate date];
			for (Article *existingA in [ch articles]) {
				if ([existingA.url isEqualToString:savedArticle.url])
					return;
			}
			[[ch articles] insertObject:savedArticle atIndex:0];
			[self save];
			[self reload];
			return;
		}
	}
	
	[self.savedChannels addObject:channel];
	[self save];
	[self reload];
}

- (void)removeDeadlineChanged:(NSNotification *)note {
	app = [note object];
	[self reload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self 
																							 name:kArticleSaveRequestNotification 
																						 object:nil];		
	[[NSNotificationCenter defaultCenter] removeObserver:self 
																							 name:kRemoveDeadlineChangedNotification 
																						 object:nil];	
}

- (void)dealloc {
	[savedChannels release];
	[super dealloc];
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.savedChannels count];
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	Channel *channel = [self.savedChannels objectAtIndex:section];
	return [[channel articles] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[savedChannels objectAtIndex:section] title];
}

static NSString *channelCell = @"ANTiSoftware.RSSReader.channelCell";

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = nil;
	cell = [table dequeueReusableCellWithIdentifier:channelCell];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:channelCell] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	SavedArticle *article = [[[savedChannels objectAtIndex:indexPath.section] articles] objectAtIndex:indexPath.row];
	if (article) {
		cell.textLabel.text = article.title;
	}
	return cell;
}

- (void)showArticle:(Article *)article forChannel:(Channel *)channel animated:(BOOL)animated {
	if (article) {
		ArticleController *articleController = [[[ArticleController alloc] init] autorelease];
		if ([article isKindOfClass:[SavedArticle class]])
			((SavedArticle *)article).channel = channel;
		articleController.delegate = self;
		articleController.article = article;
		articleController.allowArticleSaving = NO;
		[[self navigationController] pushViewController:articleController animated:animated];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[[NSNotificationCenter defaultCenter] postNotificationName:kCellSelectedNotification object:self];
	
	Channel *ch = [savedChannels objectAtIndex:indexPath.section];
	[self showArticle:[[ch articles] objectAtIndex:indexPath.row] forChannel:ch animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)table editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		Channel *channel = [self.savedChannels objectAtIndex:indexPath.section];
		Article *article = [[channel articles] objectAtIndex:indexPath.row];
		[[channel articles] removeObject:article];
		if ([[channel articles] count] == 0) {
			[self.savedChannels removeObject:channel];
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
		}
		else
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		[self save];
		//[self.tableView reloadData];
	}
}

#pragma mark -
#pragma mark ArticleControllerDelegate

- (Article *)canLoadPreviousArticleTo:(Article *)currentArticle {
	
	if (![currentArticle isKindOfClass:[SavedArticle class]])
		return nil;
	SavedArticle *a = (SavedArticle *)currentArticle;

	for (Channel *ch in self.savedChannels) {
		if ([[ch url] isEqualToString:[a.channel url]]) {
			int i = [[ch articles] indexOfObject:a];
			if ((i != -1) && (i > 0) && (i < [[ch articles] count]))
				return [[ch articles] objectAtIndex:i-1];
			else {
				// look in previous channel
				i = [self.savedChannels indexOfObject:ch];
				if (i > 0)
					return [[[self.savedChannels objectAtIndex:i-1] articles] lastObject];
			}
		}
	}
	
	return nil;
}

- (Article *)canLoadNextArticleTo:(Article *)currentArticle {

	if (![currentArticle isKindOfClass:[SavedArticle class]])
		return nil;
	SavedArticle *a = (SavedArticle *)currentArticle;
	
	for (Channel *ch in self.savedChannels) {
		if ([[ch url] isEqualToString:[a.channel url]]) {
			int i = [[ch articles] indexOfObject:a];
			if ((i != -1) && (i >= 0) && (i < [[ch articles] count] - 1))
				return [[ch articles] objectAtIndex:i+1];
			else {
				// look in next channel
				i = [self.savedChannels indexOfObject:ch];
				if (i >= 0 && i < [self.savedChannels count]-1)
					return [[[self.savedChannels objectAtIndex:i+1] articles] objectAtIndex:0];
			}
		}
	}
	
	return nil;
}

@end

