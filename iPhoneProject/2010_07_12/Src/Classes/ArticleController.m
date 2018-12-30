//
//  ArticleController.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.04.29.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "ArticleController.h"
#import "SavedArticle.h"
#import "URLHelper.h"

@implementation ArticleController

@synthesize webView, delegate, article, channel, allowArticleSaving, app;

- (AppDelegate *)app {
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(internetReachabilityChanged:) 
																							 name:kReachabilityChangedNotification 
																						 object:nil];	

	if (!headerView) {
		headerView = (ArticleHeaderView *)[[[NSBundle mainBundle] loadNibNamed:@"ArticleHeader" owner:self options:nil] objectAtIndex:0];
		//headerView.textField.text = [self.article url];
		self.navigationItem.titleView = headerView;
	}
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
																						 initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet)] 
																						autorelease];
	
	[webView setDelegate:self];
	[self setArticle:article];
}

- (void)internetReachabilityChanged:(NSNotification *)note {
	//app = [note object];
}

- (void)showErrorWithTitle:(NSString *)msg {
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ErrorTitle", @"") 
																									 message:msg
																									delegate:self 
																				 cancelButtonTitle:NSLocalizedString(@"OKBtnTitle", @"") 
																				 otherButtonTitles:nil] autorelease];
	[alert show];	
}

- (void)loadURL:(NSString *)urlString {
	if (!urlString)
		return;

	urlString = [URLHelper standarizeStringToURL:urlString];
	
	if (![self.app isInternetAvailable]) {
		[self.app warnAboutNoConnectivity];
		return;
	}
	
	NSURL *_url = [NSURL URLWithString:urlString];
	NSURLRequest *request = [NSURLRequest requestWithURL:_url];
	[webView loadRequest:request];
}

- (void)setArticle:(Article *)value {
	article = value;
	[article retain];
	if (![self isViewLoaded])
		return;
	
	if (article) {
		if (delegate) {
			Article *a = [delegate canLoadPreviousArticleTo:self.article];
			[headerView.upDown setEnabled:(a != nil) forSegmentAtIndex:0];
			a = [delegate canLoadNextArticleTo:self.article];
			[headerView.upDown setEnabled:(a != nil) forSegmentAtIndex:1];
		}
		
		article.visited = YES;

		// according to ATOM specification, if article has CONTENTS defined, its link is ignored
		if ((self.article.content != nil) && ![self.article.content isEqualToString:@""]) {
			NSString *text = self.article.content;// [self.article.content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			[webView loadHTMLString:text baseURL:nil];
			return;
		}
		else if (self.article.url == nil || [self.article.url isEqualToString:@""]) {
			[self performSelectorOnMainThread:@selector(showErrorWithTitle:) withObject:NSLocalizedString(@"EmptyArticleURL", @"") waitUntilDone:YES];
			return;
		}
		else
			headerView.textField.text = self.article.url;
		
		[self loadURL:self.article.url];
	}
	else {
		[webView loadHTMLString:@"<html/>" baseURL:nil];
	}
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
	[[NSNotificationCenter defaultCenter] removeObserver:self 
																									name:kReachabilityChangedNotification 
																								object:nil];	
}

- (void)viewWillAppear:(BOOL)animated {
	if (delegate) {
		[headerView.upDown setEnabled:([delegate canLoadPreviousArticleTo:self.article] != nil) forSegmentAtIndex:0];
		[headerView.upDown setEnabled:([delegate canLoadNextArticleTo:self.article] != nil) forSegmentAtIndex:1];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


- (void)dealloc {
	[super dealloc];
}

- (IBAction)showActionSheet {
	UIActionSheet *actionSheet;
	if (allowArticleSaving) {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@""
																							delegate:self 
																		 cancelButtonTitle:NSLocalizedString(@"CancelBtnTitle", @"") 
																destructiveButtonTitle:nil
																		 otherButtonTitles:
									 NSLocalizedString(@"EMailArticle", @""), 
									 NSLocalizedString(@"CopyURL", @""), 
									 /*NSLocalizedString(@"CopyContents", @""),*/ //TODO
									 NSLocalizedString(@"Save", @""), 
									 nil];
	}
	else {
		actionSheet = [[UIActionSheet alloc] initWithTitle:@""
																							delegate:self 
																		 cancelButtonTitle:NSLocalizedString(@"CancelBtnTitle", @"") 
																destructiveButtonTitle:nil
																		 otherButtonTitles:
									 NSLocalizedString(@"EMailArticle", @""), 
									 NSLocalizedString(@"CopyURL", @""), 
									 /*NSLocalizedString(@"CopyContents", @""),*/ //TODO
									 nil];
	}
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	//[actionSheet showInView:[[UIApplication sharedApplication] keyWindow]]; // this must be like this; using self.view would obscure lower buttons by TabBar
	UIViewController *vc = [[self navigationController] parentViewController];
	if ([vc isKindOfClass:[UITabBarController class]]) {
		UITabBarController *tbc = (UITabBarController *)vc;
		[actionSheet showFromTabBar:[tbc tabBar]];
	}
	[actionSheet release];
}

static double duration = 0.4;

- (IBAction)enterURLEditing {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:duration];
	rightButtonItem = [self.navigationItem.rightBarButtonItem retain];
	[rightButtonItem.customView setAlpha:0.0];
	UIView *emptyView = (UIView *)[[[NSBundle mainBundle] loadNibNamed:@"ArticleHeader" owner:nil options:nil] objectAtIndex:1];
	self.navigationItem.rightBarButtonItem = nil;
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:emptyView] autorelease];

	textFieldRect = headerView.textField.frame;
	[headerView.upDown setAlpha:0.0];
	[headerView.cancel setAlpha:1.0];
	[headerView.label setAlpha:1.0];
	[webView setAlpha:0.2];
	[headerView setFrame:CGRectMake(0, 0, 520, 44)];
	
	[UIView commitAnimations];

	//[webView reload];
}

- (int)topBarHeight {
	return self.navigationController.navigationBar.frame.size.height;
}

- (int)topBarWidth {
	return self.navigationController.navigationBar.frame.size.width;
}

- (IBAction)leaveURLEditing {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:duration];
	[headerView.upDown setAlpha:1.0];
	[headerView.cancel setAlpha:0.0];
	[headerView.label setAlpha:0.0];
	[webView setAlpha:1.0];
	[headerView setFrame:CGRectMake(0, 0, [self topBarWidth] - 40, [self topBarHeight])]; //280, 44
	[headerView.textField setFrame:CGRectMake(0, 6, headerView.frame.size.width - 81, 31)];

	self.navigationItem.leftBarButtonItem = nil;
	self.navigationItem.rightBarButtonItem = rightButtonItem;
	[rightButtonItem.customView setAlpha:1.0];
	[UIView commitAnimations];
}

- (IBAction)cancelEditing {
	//ArticleHeaderView *headerView = (ArticleHeaderView *)self.navigationItem.titleView;
	[headerView.textField resignFirstResponder];
}

- (IBAction)upDownTapped {
	if (delegate) {
		if (headerView.upDown.selectedSegmentIndex == 0)
			//[delegate loadPreviousArticleTo:self.article];
			[self setArticle:[delegate canLoadPreviousArticleTo:self.article]];
		else
			//[delegate loadNextArticleTo:self.article];
		  [self setArticle:[delegate canLoadNextArticleTo:self.article]];
	}
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if ((article != nil) && (self.article.content != nil) && ![self.article.content isEqualToString:@""])
		return YES;
	
	BOOL result = [self.app isInternetAvailable];
	if (!result)
		[self.app warnAboutNoConnectivity];
	return result;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)_webView {
	if ((self.article.content == nil) || [self.article.content isEqualToString:@""]) {
		NSString *urlString = _webView.request.mainDocumentURL.absoluteString;
		headerView.textField.text = urlString;
	}

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.navigationItem.rightBarButtonItem.enabled = YES;
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case 0: { // e-mail
			if ([MFMailComposeViewController canSendMail]) {
				MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
				mailComposer.mailComposeDelegate = self;
				
				[mailComposer setSubject:[NSString stringWithFormat:NSLocalizedString(@"SendingArticle", @""), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]]];
				
				// Fill out the email body text
				NSString *emailBody = [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
				[mailComposer setMessageBody:emailBody isHTML:YES];
				
				[self presentModalViewController:mailComposer animated:YES];
				[mailComposer release];
			}
			break;
		}
		case 1: { // copy URL to pasteboard
			UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
			NSString *_url = [[[webView request] URL] absoluteString];
			[pasteboard setString:[_url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			break;
		}
		/*case 2: { // copy article to pasteboard
			UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
			[pasteboard setString:[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"]];
			break;
		}*/
		case 2:  { // save
			SavedArticle *a = [SavedArticle savedArticleWithArticle:self.article andChannel:self.channel];
			[a retain];
			[a setContent:[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"]];
			[a save];
			[a autorelease];
			break;
		}
		default: { // nothing
			break;
		}
			
	}
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	NSString *message;
	
	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled:
			message = @"";//message.text = @"EMailResultCancelled";
			break;
		case MFMailComposeResultSaved:
			message = @"EMailResultSavedAsDraft";
			break;
		case MFMailComposeResultSent:
			message = @"EMailResultSent";
			break;
		case MFMailComposeResultFailed:
			if ([error code] == MFMailComposeErrorCodeSaveFailed)
				message = @"EMailResultFailedToSaveAsDraft";
			else if ([error code] == MFMailComposeErrorCodeSendFailed)
				message = @"EMailResultSendFailure";
			else
				message = @"EMailResultUnknownError";
			break;
		default:
			message = @"";
			break;
	}
	
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == headerView.textField) {
		//lockURLUpdate = YES;
		[textField resignFirstResponder];
		[self loadURL:textField.text];
	}
	
	return YES;
}

@end


@implementation ArticleHeaderView
@synthesize upDown, cancel, label, textField;

@end


@implementation ArticleHeaderViewController

@end

