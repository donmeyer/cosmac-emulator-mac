//
//  HexLoader.h
//  1802 Emulator
//
//  Created by Donald Meyer on 6/3/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import <Foundation/Foundation.h>




@interface Symbol : NSObject

@property (readonly, strong) NSString *name;
@property (readonly, assign) UInt16 addr;
@property (assign) UInt16 endAddr;

- (instancetype)initWithName:(NSString*)name addr:(UInt16) addr;

@end



@interface SourceLine : NSObject

@property (readonly, strong) NSString *text;
@property (readonly, assign) UInt16 addr;
@property (readonly, assign) int lineNum;
@property (readonly) UInt16 endAddr;
@property (readonly) BOOL hasCode;

@end



@interface HexLoader : NSObject

@property (nonatomic, assign, readonly) long byteCount;	// Count of bytes written to memory.

@property (strong, readonly) NSMutableArray<Symbol*> *symbols;
@property (strong, readonly) NSMutableArray<SourceLine*> *sourceLines;


- (id)initWithListingPath:(NSString*)path;

- (id)initWithListingString:(NSString*)listingString;

- (BOOL)load:(void (^)(long addr, unsigned char byte))writeBlock;

- (SourceLine*)lineForAddr:(UInt16)addr;

@end
