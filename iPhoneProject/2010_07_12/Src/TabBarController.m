//
//  TabBarController.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.06.19.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "TabBarController.h"


@implementation TabBarController

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
	[super dealloc];
}


@end
