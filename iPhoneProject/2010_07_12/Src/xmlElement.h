//
//  xmlElement.h
//  kiedyforsa.pl
//
//  Created by Mateusz Bajer on 10.03.04.
//  Copyright 2010 ANTiSoftware. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface xmlElement : NSObject {
	xmlElement *prevElement;
	NSString *name;
	NSDictionary *attributes;
	NSMutableString *currentParsedCharacterData;
}
@property (nonatomic, retain) xmlElement *prevElement;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSDictionary *attributes;
@property (nonatomic, retain) NSMutableString *currentParsedCharacterData;

+ (id)xmlElement:(NSString *)name withAttributes:(NSDictionary *)attrs;

@end

