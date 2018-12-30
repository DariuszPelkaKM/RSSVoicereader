//
//  BrowserController.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.05.01.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "BrowserController.h"
#import "Reachability.h"
#import "URLHelper.h"

@implementation BrowserController

@synthesize webView, urlField, backButton, reloadButton, app;

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
	if (!app) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		urlField.text = [defaults objectForKey:@"lastURL"];
		lockURLNotification = YES;
		[self loadURL:urlField.text];
		lockURLNotification = NO;
	}
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

- (void)updateLastURLWith:(NSString *)urlString {
	BOOL lock = lockURLNotification;
	lockURLNotification = YES;
	[lastURL release];
	lastURL = [[urlString copy] retain];
	if (app)
		app.lastURL = lastURL;
	lockURLNotification = lock;
}																								 

- (void)loadURL:(NSString *)urlString {
	if (!urlString)
		return; // error
	
	[self updateLastURLWith:urlString];

	if (app && ![app isInternetAvailable]) {
		[app warnAboutNoConnectivity];
		return;
	}
	
	
	NSString *s = [URLHelper standarizeStringToURL:urlString];
	if (!s)
		return;
	
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
	reloadButton.enabled = [app isInternetAvailable];//internetConnectionAvailable;
	backButton.enabled = _webView.canGoBack && [app isInternetAvailable];//internetConnectionAvailable;
	
	NSString *urlString = _webView.request.mainDocumentURL.absoluteString;
	urlField.text = urlString;
	[self updateLastURLWith:urlString];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	//if (error.domain == NSURLErrorDomain)
	//	return;
	
	UIAlertView *dialog = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PageLoadError", @"") 
																										message:[error localizedDescription] 
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
