//
//  Logging.h
//  1802 Emulator
//
//  Created by Donald Meyer on 6/11/17.
//  Copyright © 2017 Donald Meyer. All rights reserved.
//

#import <Foundation/Foundation.h>


#define LogDebug( fmt, ... )	[Logging logDebug:__FILE__ line:__LINE__ format:fmt, ##  __VA_ARGS__]

#define LogVerbose( fmt, ... )	[Logging logInfo:__FILE__ line:__LINE__ format:fmt, ##  __VA_ARGS__]

#define LogWarn( fmt, ... )	[Logging logDefault:__FILE__ line:__LINE__ format:fmt, ##  __VA_ARGS__]

#define LogError( fmt, ... )	[Logging logError:__FILE__ line:__LINE__ format:fmt, ##  __VA_ARGS__]


@interface Logging : NSObject

+ (void)logInfo:(const char *)file line:(int)line format:(NSString*)format, ...;

+ (void)logDebug:(const char *)file line:(int)line format:(NSString*)format, ...;

+ (void)logDefault:(const char *)file line:(int)line format:(NSString*)format, ...;

+ (void)logError:(const char *)file line:(int)line format:(NSString*)format, ...;


@end
