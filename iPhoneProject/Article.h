//
//  Article.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.06.01.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kArticleChangedNotification @"kArticleChangedNotification"

@interface Article : NSObject <NSCoding> {
	NSString *title;
	NSString *url;
	NSDate *stamp;
	NSMutableData *data;
	NSString *uniqueID;
	BOOL visited;
	NSString *content;
	NSString *stampStr;
	
	BOOL loading;
}
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSDate *stamp;
@property (nonatomic, copy) NSString *stampStr;
@property (nonatomic, copy, setter=setData:) NSMutableData *data;
@property (nonatomic, copy) NSString *uniqueID;
@property (nonatomic, copy, setter=setContent:) NSString *content;
@property (nonatomic, setter=setVisited:) BOOL visited;

+ (id)articleNamed:(NSString *)name url:(NSString *)url;
+ (id)articleNamed:(NSString *)name url:(NSString *)url stamp:(NSDate *)stamp;
+ (id)articleNamed:(NSString *)name url:(NSString *)url stamp:(NSDate *)stamp data:(NSData *)data;

- (NSComparisonResult)compareWith:(Article *)article;

@end

@interface ArticleGroup : NSObject <NSCoding> {
	NSDate *date;
	NSMutableArray *articles;
}
@property (nonatomic, retain) NSMutableArray *articles;
@property (nonatomic, retain) NSDate *date;

@end

