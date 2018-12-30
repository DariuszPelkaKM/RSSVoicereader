//
//  About.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.29.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "AboutController.h"


@implementation AboutController

@synthesize webView;

/*
// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
	}
	return self;
}
 */

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	//webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 420)] autorelease];
	//[self.view addSubview:webView];
	NSURL *url = [NSURL URLWithString:@"http://www.e-ivn.com"];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[webView loadRequest:request];
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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
