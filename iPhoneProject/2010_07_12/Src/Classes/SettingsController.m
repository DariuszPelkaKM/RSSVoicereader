//
//  SettingsController.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.29.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "SettingsController.h"
#import "ValueTableController.h"
#import "AppDelegate.h"

@implementation SettingsController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

static int minute = 60;
static int day = 86400;

- (void)initRefreshRateValues {
	if (refreshRateValues == nil) {
		refreshRateValues = [[NSDictionary dictionaryWithObjectsAndKeys: 
							[NSNumber numberWithInteger:minute*0], @"neverRefresh", 
							[NSNumber numberWithInteger:minute*1], @"each1minute", 
							[NSNumber numberWithInteger:minute*5], @"each5minutes", 
							[NSNumber numberWithInteger:minute*10], @"each10minutes",  
							[NSNumber numberWithInteger:minute*15], @"each15minutes", 
							[NSNumber numberWithInteger:minute*30], @"each30minutes", 
							[NSNumber numberWithInteger:minute*60], @"everyHour", 
							nil] retain]; 
	}
}

- (void)initRemoveDeadlineValues {
	if (removeDeadlineValues == nil) {
		removeDeadlineValues = [[NSDictionary dictionaryWithObjectsAndKeys: 
													[NSNumber numberWithInteger:day*0], @"neverRemove", 
													[NSNumber numberWithInteger:day*1], @"after1day", 
													[NSNumber numberWithInteger:day*2], @"after2days", 
													[NSNumber numberWithInteger:day*5], @"after5days",  
													[NSNumber numberWithInteger:day*10], @"after10days", 
													[NSNumber numberWithInteger:day*14], @"after2weeks", 
													[NSNumber numberWithInteger:day*28], @"after4weeks", 
													nil] retain]; 
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.title = NSLocalizedString(@"SettingsTitle", @"");
	
	[self initRefreshRateValues];
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(refreshRateChanged:) 
																							 name:kRefreshRateChangedNotification 
																						 object:nil];	
	[self initRemoveDeadlineValues];
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(removeDeadlineChanged:) 
																							 name:kRemoveDeadlineChangedNotification 
																						 object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(updateOnlyWiFiAllowed:) 
																							 name:kOnlyWiFiAllowedChangedNotification 
																						 object:nil];	
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(updateEnableSounds:) 
																							 name:kEnableSoundsChangedNotification 
																						 object:nil];	
	
}

- (void)updateRefreshRateKey {
	if (app) {
		[self initRefreshRateValues];
		NSNumber *no = [NSNumber numberWithInteger:app.refreshRate];
		NSArray *keys = [refreshRateValues allKeysForObject:no];
		if ([keys count] == 1) {
			refreshRateKey = [keys objectAtIndex:0];
			[self.tableView reloadData];
		}
	}
}

- (void)refreshRateChanged:(NSNotification *)note {
	app = [note object];
	[self updateRefreshRateKey];
}

- (void)updateRemoveDeadlineKey {
	if (app) {
		[self initRemoveDeadlineValues];
		NSNumber *no = [NSNumber numberWithInteger:app.removeDeadline];
		NSArray *keys = [removeDeadlineValues allKeysForObject:no];
		if ([keys count] == 1) {
			removeDeadlineKey = [keys objectAtIndex:0];
			[self.tableView reloadData];
		}
	}
}

- (void)removeDeadlineChanged:(NSNotification *)note {
	app = [note object];
	[self updateRemoveDeadlineKey];
}

- (void)updateOnlyWiFiAllowed:(NSNotification *)note {
	app = [note object];
	if (app) {
		onlyWiFiAllowed = app.onlyWiFiAllowed;
	}
}

- (void)updateEnableSounds:(NSNotification *)note {
	app = [note object];
	if (app) {
		enableSounds = app.enableSounds;
	}
}

- (IBAction)enableSoundsChanged:(id)sender {
	if (app) 
		app.enableSounds = ((UISwitch *)sender).on;
}

- (IBAction)onlyWiFiAllowedChanged:(id)sender {
	if (app) 
		app.onlyWiFiAllowed = ((UISwitch *)sender).on;
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

- (void)dealloc {
  [super dealloc];
	[refreshRateValues release];
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 4;
}

static NSString *settingsCell = @"ANTiSoftware.RSSReader.settingsCell";

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = nil;
	cell = [table dequeueReusableCellWithIdentifier:settingsCell];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:settingsCell] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	switch (indexPath.row) {
		case 0: {
			cell.textLabel.text = NSLocalizedString(@"SettingsRefreshTimeout", @"");
			cell.detailTextLabel.text = NSLocalizedString(refreshRateKey, @"");
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
		}
		case 1:
			cell.textLabel.text = NSLocalizedString(@"SettingsRemoveNewsAfter", @"");
			cell.detailTextLabel.text = NSLocalizedString(removeDeadlineKey, @"");
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
		case 2: {
			cell.textLabel.text = NSLocalizedString(@"SettingsOnlyWiFiConnection", @"");
			UISwitch *s = [[[UISwitch alloc] init] autorelease]; 
			[s addTarget:self action:@selector(onlyWiFiAllowedChanged:) forControlEvents:UIControlEventValueChanged];
			[s setOn:onlyWiFiAllowed animated:NO];
			cell.accessoryView = s;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			break;
		}
		case 3: {
			cell.textLabel.text = NSLocalizedString(@"SettingsEnableAudioEffects", @"");
			UISwitch *s = [[[UISwitch alloc] init] autorelease];
			[s addTarget:self action:@selector(enableSoundsChanged:) forControlEvents:UIControlEventValueChanged];
			[s setOn:enableSounds animated:NO];
			cell.accessoryView = s;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			break;
		}
		default:
			break;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ValueTableController *valueTable = [[ValueTableController alloc] initWithNibName:@"ValueTable" bundle:nil];
	valueTable.delegate = self;
	switch (indexPath.row) {
		case 0: // refresh news each
			valueTable.values = refreshRateValues; 
			valueTable.key = refreshRateKey;
			break;
		case 1: // remove news after
			valueTable.values = removeDeadlineValues; 
			valueTable.key = removeDeadlineKey;
			break;
		default: // do nothing
			//
			break;
	}
	[self.navigationController pushViewController:valueTable animated:YES];
	[valueTable release];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// avoid selection of ANY row which has no subView assigned (has no disclosure indicator)
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if (cell) {
		if (cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator)
			return indexPath;
	}

	return nil;
}

#pragma mark -
#pragma mark ValueTableControllerDelegate

- (void)valueChosen:(ValueTableController *)controller item:(id)key {
	if (app) {
		if ([controller.values isEqual:refreshRateValues]) {
			id obj = [refreshRateValues objectForKey:key];
			if ([obj isKindOfClass:[NSNumber class]])
				app.refreshRate = [(NSNumber *)obj intValue];
		}
		else if ([controller.values isEqual:removeDeadlineValues]) {
			id obj = [removeDeadlineValues objectForKey:key];
			if ([obj isKindOfClass:[NSNumber class]])
				app.removeDeadline = [(NSNumber *)obj intValue];
		}
	}
	[self.navigationController popViewControllerAnimated:YES];
}

@end
