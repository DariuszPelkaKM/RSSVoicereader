//
//  AddChannelView.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.28.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "ChannelViewController.h"
#import "Reachability.h"

@implementation ChannelViewController

@synthesize channelURL, channelName, delegate, channel, cancelButton, doneButton, navigationBar, channelURLLabel, channelNameLabel, app;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return YES;//(interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(internetReachabilityChanged:) 
																							 name:kReachabilityChangedNotification 
																						 object:nil];	
}

- (void)viewWillAppear:(BOOL)animated {
	[channelName becomeFirstResponder];
	if (self.channel) {
		self.channelName.text = self.channel.title;
		self.channelURL.text = self.channel.url;
	}
	
	if (self.parentViewController.modalViewController != self) {
		self.navigationItem.leftBarButtonItem = cancelButton;
		self.navigationItem.rightBarButtonItem = doneButton;
		self.navigationBar.hidden = YES;
		self.channelURLLabel.frame = CGRectOffset(self.channelURLLabel.frame, 0, -self.navigationBar.frame.size.height);
		self.channelNameLabel.frame = CGRectOffset(self.channelNameLabel.frame, 0, -self.navigationBar.frame.size.height);
		self.channelName.frame = CGRectOffset(self.channelName.frame, 0, -self.navigationBar.frame.size.height);
		self.channelURL.frame = CGRectOffset(self.channelURL.frame, 0, -self.navigationBar.frame.size.height);
	}
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
}


- (void)dealloc {
	[super dealloc];
}

- (IBAction)dismiss {
	if (self.parentViewController.modalViewController != self)
		[self.navigationController popViewControllerAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
}

- (void)internetReachabilityChanged:(NSNotification *)note {
	reachabilityValid = YES;
}

- (IBAction)done {
	
	/* check if we can connect to the specified host (if internet is not available, still allow)
	if ([app isInternetAvailable]) {
		NSString *url = self.channelURL.text;
		Reachability *hostReachability = [Reachability reachabilityWithHostName:url];
		reachabilityValid = NO;
		[hostReachability startNotifer];
		if (hostReachability) {
			//while (!reachabilityValid) {
			//}
			
			NetworkStatus netStatus = [hostReachability currentReachabilityStatus];
			NSString *msg = nil;
			if (netStatus == NotReachable) {
				msg = NSLocalizedString(@"CannotAddChannel_HostNotReachable", @"");
				
				UIAlertView *dialog = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ErrorTitle", @"") 
																													message:msg 
																												 delegate:self 
																								cancelButtonTitle:NSLocalizedString(@"OK", @"")
																								otherButtonTitles:nil] autorelease];
				[dialog show];
				return;
			}
			
		}
		
	}*/
	
	if (self.channel) {
		self.channel.title = self.channelName.text;
		self.channel.url = self.channelURL.text;
	}
	if (delegate) {
		if (![delegate channelViewControllerWillFinish:self withChannel:self.channel]) {
			// do not allow to close
			return;
		}
	}
	if (self.parentViewController.modalViewController != self)
		[self.navigationController popViewControllerAnimated:YES];
	else
		[self dismissModalViewControllerAnimated:YES];
}

@end
