//
//  HexLoader.h
//  1802 Emulator
//
//  Created by Donald Meyer on 6/3/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import <Foundation/Foundation.h>




@interface Symbol : NSObject

@property (strong) NSString *name;
@property (assign) unsigned int addr;
@property (assign) unsigned int endAddr;

- (instancetype)initWithName:(NSString*)name addr:(unsigned int) addr;

@end



@interface SourceLine : NSObject

@property (strong) NSString *text;
@property (readonly, assign) unsigned int addr;
@property (readonly, assign) int lineNum;
@property (readonly) unsigned int endAddr;
@property (readonly) BOOL hasCode;

@end



@interface HexLoader : NSObject

@property (nonatomic, assign, readonly) long byteCount;	// Count of bytes written to memory.

@property (strong, readonly) NSMutableArray *symbols;


- (id)initWithListingPath:(NSString*)path;

- (id)initWithListingString:(NSString*)listingString;

- (BOOL)load:(void (^)(long addr, unsigned char byte))writeBlock;

- (SourceLine*)lineForAddr:(unsigned int)addr;

@end
