//
//  ValueTableController.h
//  RSS Reader
//
//  Created by Mateusz Bajer on 10.05.23.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ValueTableControllerDelegate;
@interface ValueTableController : UITableViewController {
	id<ValueTableControllerDelegate> delegate;
	NSDictionary *values;
	id key;
}
@property (nonatomic, retain) NSDictionary *values;
@property (nonatomic, assign) id<ValueTableControllerDelegate> delegate;
@property (nonatomic, retain) id key;
@end

@protocol ValueTableControllerDelegate <NSObject>
@optional
- (void)valueChosen:(ValueTableController *)controller item:(id)key;
@end
