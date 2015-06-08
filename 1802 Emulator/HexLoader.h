//
//  HexLoader.h
//  1802 Emulator
//
//  Created by Donald Meyer on 6/3/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface HexLoader : NSObject


@property (nonatomic, assign, readonly) long byteCount;	// Count of bytes written to memory.


- (id)initWithListingPath:(NSString*)path;

- (id)initWithListingString:(NSString*)listingString;

- (BOOL)load:(void (^)(long addr, unsigned char byte))writeBlock;

@end