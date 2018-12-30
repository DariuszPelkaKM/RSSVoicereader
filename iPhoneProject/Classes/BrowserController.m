//
//  BrowserController.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.05.01.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "BrowserController.h"
#import "Reachability.h"

@implementation BrowserController

@synthesize webView, urlField, backButton, reloadButton;

- (void)viewDidLoad {
	[super viewDidLoad];
	[urlField setPlaceholder:NSLocalizedString(@"BrowserTypeURL", @"")];

	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(reachabilityChanged:) 
																							 name:kReachabilityChangedNotification 
																						 object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(lastURLChanged:) 
																							 name:kLastURLChangedNotification 
																						 object:nil];
	
	[webView addObserver:self forKeyPath:@"canGoBack" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)dealloc {
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"canGoBack"]) {
		backButton.enabled = webView.canGoBack && [app isInternetAvailable];
	}
}

- (void)updateInterfaceWithReachability {
	reloadButton.enabled = [app isInternetAvailable];
	backButton.enabled = webView.canGoBack && [app isInternetAvailable];
}

- (void)reachabilityChanged:(NSNotification *)note {
	app = [note object];
	if (app) {
		[self updateInterfaceWithReachability];
	}
}

- (void)lastURLChanged:(NSNotification *)note {
	if (lockURLNotification)
		return;
	
	app = [note object];
	if (app) {
		urlField.text = app.lastURL;
		if ([self isViewLoaded]) {
			lockURLNotification = YES;
			[self loadURL:app.lastURL];
			lockURLNotification = NO;
		}
	}
}

static double duration = 0.4;

- (IBAction)enterURLEditing {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:duration];
	[webView setAlpha:0.2];
	
	[UIView commitAnimations];
	lockURLUpdate = NO;
}

- (IBAction)leaveURLEditing {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:duration];
	[webView setAlpha:1.0];
	
	[UIView commitAnimations];
	
	// update URL so that it reflects value from URL request
	if (!lockURLUpdate)
		[urlField setText:lastURL];
}

- (void)loadURL:(NSString *)urlString {
	if (!urlString)
		return; // error
	
	[lastURL release];
	lastURL = [[urlString copy] retain];
	if (app)
		app.lastURL = lastURL;
	
	NSString *s = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (!s)
		return; // error
	
	if (!CFStringHasPrefix((CFStringRef)s , (CFStringRef)@"http://"))
		s = [NSString stringWithFormat:@"http://%@", s];
	NSURL *url = [NSURL URLWithString:s];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	reloadButton.enabled = NO;
	[webView loadRequest:request];
}

- (IBAction)urlChanged {
	self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (IBAction)reload {
	[webView reload];
}
- (IBAction)back {
	[webView goBack];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)_webView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	reloadButton.enabled = internetConnectionAvailable;
	backButton.enabled = _webView.canGoBack && internetConnectionAvailable;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	UIAlertView *dialog = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CannotOpenPage", @"") 
																										message:[error localizedFailureReason] 
																									 delegate:self 
																					cancelButtonTitle:NSLocalizedString(@"OK", @"")
																					otherButtonTitles:nil] autorelease];
	[dialog show];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == urlField) {
		lockURLUpdate = YES;
		[textField resignFirstResponder];
		[self loadURL:textField.text];
	}
	
	return YES;
}

@end
