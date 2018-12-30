//
//  Channel.m
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.05.09.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import "Channel.h"
#import <CFNetwork/CFNetwork.h>

#pragma mark Channel (Private) 

@interface Channel (Private)
- (void)addArticlesToList:(NSArray *)articles;
- (void)handleError:(NSError *)error;
@end

#pragma mark -
#pragma mark Channel

@implementation Channel

@synthesize title, url, data, feedConnection, /*currentParsedCharacterData, */currentParseBatch, currentElement, currentArticle, articles, 
oldArticles, articleIDs, reloading, delegate;

+ (id)channelNamed:(NSString *)name url:(NSString *)url {
	return [Channel channelNamed:name url:url data:nil];
}

+ (id)channelNamed:(NSString *)name url:(NSString *)url data:(NSData *)data {
	Channel *result = [[[super alloc] init] autorelease];
	result.title = [name copy];
	result.url = [url copy];
	result.data = [data copy];
	return result;
}

- (id)init {
	self = [super init];
	[[NSNotificationCenter defaultCenter] addObserver:self 
																					 selector:@selector(articleChanged:) 
																							 name:kArticleChangedNotification 
																						 object:nil];	
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [self init];
	if (self != nil) {
		self.title = [[decoder decodeObjectForKey:@"title"] copy];
		self.url = [[decoder decodeObjectForKey:@"url"] copy];
		self.data = [[decoder decodeObjectForKey:@"data"] copy];
		[self.articles addObjectsFromArray:[decoder decodeObjectForKey:@"articles"]];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:self.title forKey:@"title"];
	[encoder encodeObject:self.url forKey:@"url"];
	[encoder encodeObject:self.data forKey:@"data"];
	[encoder encodeObject:self.articles forKey:@"articles"];
}

- (void)articleChanged:(NSNotification *)note {
	Article *a = [note object];
	if (a && [articles indexOfObject:a] != NSNotFound)
	{
		if (!lockChangesNotifications)
			[[NSNotificationCenter defaultCenter] postNotificationName:kChannelChangedNotification object:self]; 
	}
}

- (NSMutableArray *)articles {
	if (articles == NULL) {
		articles = [[[NSMutableArray alloc] init] retain];
	}
	return articles;
}

- (NSMutableArray *)oldArticles {
	if (oldArticles == NULL) {
		oldArticles = [[[NSMutableArray alloc] init] retain];
	}
	return oldArticles;
}

- (NSMutableDictionary *)articleIDs {
	if (articleIDs == NULL) {
		articleIDs = [[[NSMutableDictionary alloc] init] retain];
	}
	return articleIDs;
}

- (void)setURL:(NSString *)value {
	url = [value lowercaseString];
	
	// verifying if URL contains the http:// prefix
	if (![url hasPrefix:@"http://"])
		url = [NSString stringWithFormat:@"http://%@", url];
	
	[url retain];
	//[self reload];
}

/*- (NSMutableData *)data {
	if (data == nil)
		data = [NSMutableData data];
	
	return data;
}*/

- (void)initDictionary:(NSMutableDictionary *)dictionary withArray:(NSArray *)array {
	for (Article *a in array) {
		[dictionary setObject:a forKey:[a uniqueID]];
	}
}

- (void)reload {
	if (reloading)
		return;
	
	[self initDictionary:self.articleIDs withArray:self.articles];
	//[self.oldArticles removeAllObjects];
	//[self.oldArticles addObjectsFromArray:self.articles];
	[self.articles removeAllObjects];
	
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
	self.feedConnection = [[[NSURLConnection alloc] initWithRequest:urlRequest delegate:self] autorelease];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	reloading = YES;
}

- (void)dealloc {
	[self.feedConnection cancel];
	[[NSNotificationCenter defaultCenter] removeObserver:self 
																							 name:kArticleChangedNotification 
																						 object:nil];	
	[title release];
	[url release];
	[data release];
	[self.articles release];
	[self.oldArticles release];
	[self.articleIDs release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Channel (private)

// Handle errors in the download or the parser by showing an alert to the user. This is a very
// simple way of handling the error, partly because this application does not have any offline
// functionality for the user. Most real applications should handle the error in a less obtrusive
// way and provide offline functionality to the user.
//
- (void)handleError:(NSError *)error {
	NSString *errorMessage = [error localizedDescription];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"ChannelErrorTitle", @""), self.title]
																											message:errorMessage
																										 delegate:nil
																						cancelButtonTitle:@"OK"
																						otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

static NSUInteger const kSizeOfArticleBatch = 10;

// The secondary (parsing) thread calls addArticlesToList: on the main thread with batches of
// parsed objects. The batch size is set via the kSizeOfArticleBatch constant.
//
- (void)addArticlesToList:(NSArray *)_articles {
	
	assert([NSThread isMainThread]);
	
	//[self willChangeValueForKey:@"articles"];
	[self.articles addObjectsFromArray:_articles];
	//[self didChangeValueForKey:@"articles"];
	if (delegate)
		[delegate articlesChangedInChannel:self];
}



#pragma mark -
#pragma mark NSURLConnection delegate methods

// The following are delegate methods for NSURLConnection. Similar to callback functions, this is
// how the connection object, which is working in the background, can asynchronously communicate back
// to its delegate on the thread from which it was started - in this case, the main thread.
//
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	// check for HTTP status code for proxy authentication failures
	// anything in the 200 to 299 range is considered successful,
	// also make sure the MIMEType is correct:
	//
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	int statusCode = [httpResponse statusCode];
	NSString *mime = [response MIMEType];
	if (((statusCode/100) == 2) && ([mime isEqual:@"application/atom+xml"] || [mime isEqual:@"application/rss+xml"])) {
		self.data = [NSMutableData data];
	} 
	else {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:
															NSLocalizedString(@"HTTPError", @"Error message displayed when receving a connection error.")
																												 forKey:NSLocalizedDescriptionKey];
		NSError *error = [NSError errorWithDomain:@"HTTP" code:[httpResponse statusCode] userInfo:userInfo];
		[self handleError:error];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)_data {
	[data appendData:_data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
	reloading = NO;
	if ([error code] == kCFURLErrorNotConnectedToInternet) {
		// if we can identify the error, we can present a more precise message to the user.
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject: NSLocalizedString(@"No Connection Error", @"Error message displayed when not connected to the Internet.") forKey:NSLocalizedDescriptionKey];
		NSError *noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain
																										 code:kCFURLErrorNotConnectedToInternet
																								 userInfo:userInfo];
		[self handleError:noConnectionError];
	} else {
		// otherwise handle the error generically
		[self handleError:error];
	}
	self.feedConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	self.feedConnection = nil;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;   
	reloading = NO;

	// Spawn a thread to fetch the article data so that the UI is not blocked while the
	// application parses the XML data.
	//
	// IMPORTANT! - Don't access UIKit objects on secondary threads.
	//
	[NSThread detachNewThreadSelector:@selector(parseChannelData:)
													 toTarget:self
												 withObject:data];
	self.data = nil;
}

- (void)parseChannelData:(NSData *)_data {
	// You must create a autorelease pool for all secondary threads.
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	self.currentParseBatch = [NSMutableArray array];
	//self.currentParsedCharacterData = [NSMutableString string];
	//
	// It's also possible to have NSXMLParser download the data, by passing it a URL, but this is
	// not desirable because it gives less control over the network, particularly in responding to
	// connection errors.
	//
	NSString *s = [[NSString alloc] initWithData:_data encoding:NSASCIIStringEncoding];
	NSLog(@"%@", s);
	[s release];
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:_data];
	[parser setDelegate:self];
	[parser parse];
	
	// depending on the total number of articles parsed, the last batch might not have been a
	// "full" batch, and thus not been part of the regular batch transfer. So, we check the count of
	// the array and, if necessary, send it to the main thread.
	//
	if ([self.currentParseBatch count] > 0) {
		[self performSelectorOnMainThread:@selector(addArticlesToList:)
													 withObject:self.currentParseBatch
												waitUntilDone:NO];
	}
	self.currentParseBatch = nil;
	self.currentArticle = nil;
	//self.currentParsedCharacterData = nil;
	[parser release];        
	[pool release];
}

#pragma mark -
#pragma mark stack

- (void)pushElement:(NSString *)name withAttributes:(NSDictionary *)attrs {
	xmlElement *newElement = [xmlElement xmlElement:name withAttributes:attrs];
	newElement.prevElement = self.currentElement;
	self.currentElement = newElement;
	NSLog(@"push %@", name, NULL);
	[self.currentElement.currentParsedCharacterData setString:@""];
}

- (xmlElement *)popElement {
	xmlElement *el = self.currentElement.prevElement;
	NSString *nm = self.currentElement.name;
	[self.currentElement release];
	self.currentElement = el;
	NSLog(@"pop %@", nm, NULL);
	return self.currentElement;
}


#pragma mark -
#pragma mark NSXMLParser delegate methods

static NSString * const kEntryElementName = @"entry";
static NSString * const kItemElementName = @"item";
static NSString * const kLinkElementName = @"link";
static NSString * const kTitleElementName = @"title";
static NSString * const kUpdatedElementName = @"updated";
static NSString * const kPubDateElementName = @"pubDate";
static NSString * const kContentElementName = @"content";

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	lockChangesNotifications = YES;
	if (delegate)
		[delegate channelWillLoad:self];
	self.currentElement = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	lockChangesNotifications = NO;
	if (delegate)
		[delegate channelDidFinishLoading:self];
	
	xmlElement *el = self.currentElement;
	// should be null
	if (el) {
		// show stack error
	}
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
	namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
		attributes:(NSDictionary *)attributeDict {
	
	[self pushElement:elementName withAttributes:attributeDict];
	
	if ([elementName isEqualToString:kEntryElementName] || [elementName isEqualToString:kItemElementName]) {
		Article *article = [[Article alloc] init];
		self.currentArticle = article;
		[article release];
	} 
	else if ((self.currentArticle != nil) && [elementName isEqualToString:kLinkElementName]) {
		NSString *link = [attributeDict valueForKey:@"href"];
		NSString *rel = [attributeDict valueForKey:@"rel"];
		if (link && ![link isEqualToString:@""] && (!rel || (rel && [rel isEqualToString:@"alternate"]))) {
			self.currentArticle.url = link;
			if (!self.currentArticle.uniqueID || [self.currentArticle.uniqueID isEqualToString:@""])
				self.currentArticle.uniqueID = link;
		}
	} 
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {     
	
	if ([elementName isEqualToString:[self.currentElement name]]) {

		if ([elementName isEqualToString:kEntryElementName] || [elementName isEqualToString:kItemElementName]) {
			if (self.currentArticle) {
				[self.currentParseBatch addObject:self.currentArticle];
				Article *a = [self.articleIDs objectForKey:[self.currentArticle uniqueID]];
				self.currentArticle.visited = (a != nil) && a.visited && [self.currentArticle.stampStr isEqualToString:a.stampStr];
				[self.articleIDs setObject:self.currentArticle forKey:self.currentArticle.uniqueID];
				parsedArticleCounter++;
				if ([self.currentParseBatch count] >= 10) {
					[self performSelectorOnMainThread:@selector(addArticlesToList:)
																 withObject:self.currentParseBatch
															waitUntilDone:NO];
					self.currentParseBatch = [NSMutableArray array];
				}
			}
		} 
		else if ([elementName isEqualToString:kTitleElementName]) {
			if (self.currentArticle)
				self.currentArticle.title = self.currentElement.currentParsedCharacterData;
		} 
		else if ([elementName isEqualToString:kContentElementName]) {
			if (self.currentArticle)
				self.currentArticle.content = self.currentElement.currentParsedCharacterData;
		} 
		else if ([elementName isEqualToString:kLinkElementName]) {
			if (self.currentArticle) {
				if (self.currentElement.currentParsedCharacterData && ![self.currentElement.currentParsedCharacterData isEqualToString:@""])
					self.currentArticle.url = self.currentElement.currentParsedCharacterData;
				if (!self.currentArticle.uniqueID || [self.currentArticle.uniqueID isEqualToString:@""])
					self.currentArticle.uniqueID = self.currentElement.currentParsedCharacterData;
			}
		} 
		else if ([elementName isEqualToString:kUpdatedElementName] || [elementName isEqualToString:kPubDateElementName]) {
			if (self.currentArticle) {
				//self.currentArticle.stamp = [self.dateFormatter dateFromString:self.currentParsedCharacterData];
				self.currentArticle.stampStr = self.currentElement.currentParsedCharacterData;
			}
			else {
				// kUpdatedElementName can be found outside an entry element (i.e. in the XML header)
				// so don't process it here.
			}
			
		} 

		[self popElement];
		
	}
		
}

// This method is called by the parser when it find parsed character data ("PCDATA") in an element.
// The parser is not guaranteed to deliver all of the parsed character data for an element in a single
// invocation, so it is necessary to accumulate character data until the end of the element is reached.
//
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (self.currentElement) {
		[self.currentElement.currentParsedCharacterData appendString:string];
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	// Pass the error to the main thread for handling.
	[self performSelectorOnMainThread:@selector(handleError:) withObject:parseError waitUntilDone:NO];
}


@end
