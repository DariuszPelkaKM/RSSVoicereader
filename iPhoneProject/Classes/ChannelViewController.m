//
//  AddChannelView.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.28.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "ChannelViewController.h"


@implementation ChannelViewController

@synthesize channelURL, channelName, delegate, channel, cancelButton, doneButton, navigationBar, channelURLLabel, channelNameLabel;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return YES;//(interfaceOrientation == UIInterfaceOrientationPortrait);
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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
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

- (IBAction)done {
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
