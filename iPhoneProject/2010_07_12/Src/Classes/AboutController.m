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

/*- (void)viewDidLoad {
 [super viewDidLoad];
 NSURL *url = [NSURL URLWithString:@"http://www.e-ivn.com"];
 NSURLRequest *request = [NSURLRequest requestWithURL:url];
 [webView loadRequest:request];
 }*/

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
