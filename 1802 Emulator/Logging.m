//
//  Logging.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/11/17.
//  Copyright © 2017 Donald Meyer. All rights reserved.
//

#import "Logging.h"
#import <os/log.h>



@implementation Logging

+(void)initialize
{
	os_log_info( OS_LOG_DEFAULT, "Initialize!" );
}


+ (void)logInfo:(const char *)file line:(int)line format:(NSString*)format, ...
{
	va_list	args;
	va_start( args, format );
	
	NSString *s = [[NSString alloc] initWithFormat:format arguments:args];
	[Logging _log:OS_LOG_TYPE_INFO file:file line:line text:s];
	
	va_end( args );
}


+ (void)logDebug:(const char *)file line:(int)line format:(NSString*)format, ...
{
	va_list	args;
	va_start( args, format );
	
	NSString *s = [[NSString alloc] initWithFormat:format arguments:args];
	[Logging _log:OS_LOG_TYPE_DEBUG file:file line:line text:s];
	
	va_end( args );
}


+ (void)logDefault:(const char *)file line:(int)line format:(NSString*)format, ...
{
	va_list	args;
	va_start( args, format );
	
	NSString *s = [[NSString alloc] initWithFormat:format arguments:args];
	[Logging _log:OS_LOG_TYPE_DEFAULT file:file line:line text:s];
	
	va_end( args );
}


+ (void)logError:(const char *)file line:(int)line format:(NSString*)format, ...
{
	va_list	args;
	va_start( args, format );
	
	NSString *s = [[NSString alloc] initWithFormat:format arguments:args];
	[Logging _log:OS_LOG_TYPE_ERROR file:file line:line text:s];
	
	va_end( args );
}


+ (void)_log:(os_log_type_t)type file:(const char *)file line:(int)line text:(NSString*)text
{
	NSString *fname = [[NSString stringWithCString:file encoding:NSASCIIStringEncoding] lastPathComponent];
	
	NSString *s = [NSString stringWithFormat:@"[%@:%d] %@", fname, line, text];
	
	//	NSLog( @"NS -> %@", s );
	//	os_log_debug( OS_LOG_DEFAULT,"%@", s );
	os_log_with_type( OS_LOG_DEFAULT, type, "%@", s );
}


@end
