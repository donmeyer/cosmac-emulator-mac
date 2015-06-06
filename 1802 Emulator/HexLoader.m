//
//  HexLoader.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/3/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>

#import "HexLoader.h"


@interface HexLoader ()

@property (nonatomic, strong) NSString *listingString;

@property (nonatomic, assign) long byteCount;	// Count of bytes written to memory.

@property (nonatomic, strong) void (^writeBlock)(long addr, unsigned char byte);
	
@end



@implementation HexLoader


- (id)initWithListingString:(NSString*)listingString
{
	self = [super init];
	if( self )
	{
		_listingString = listingString;
	}
	
	return self;
}


- (id)initWithListingPath:(NSString*)path
{
	NSError *error;
	NSString *s = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:&error];
	if( s == nil )
	{
		// Error reading file
		DDLogWarn( @"Unable to load listing" );
	}
	
	DDLogDebug( @"File %@ is a string of len %lu", path, [s length] );
	
	return [self initWithListingString:s];
}



- (BOOL)load:(void (^)(long addr, unsigned char byte))writeBlock
{
	if( self.listingString == nil )
	{
		return NO;
	}
	
	self.writeBlock = writeBlock;
	
	// Now we parse the string one line at a time.
	NSArray *lines = [self.listingString componentsSeparatedByString:@"\n"];
	
	for( __strong NSString *line in lines )
	{
		// Remove leading and trailing whitespace and newlines.
		line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if( [line length] > 0 )
		{
			if( [self processListingLine:line] == NO )
			{
				return NO;
			}
		}
	}
	
	return YES;
}


- (BOOL)processListingLine:(NSString*)line
{
	// We expect listing lines to look like:  "AA55 12FC;"
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([0-9a-fA-F]{4})\\s+([0-9a-fA-F]+)\\s*\\;.*"
																		   options:NSRegularExpressionDotMatchesLineSeparators
																			 error:&error];
	NSAssert( ( regex != nil && error == nil ), @"Error build regex: %@", error );
	
//	NSUInteger matchCount = [regex numberOfMatchesInString:line options:0 range:NSMakeRange(0, line.length)];	
//	DDLogVerbose( @"Regex=%@, matchcount=%lu", regex, matchCount );

	NSTextCheckingResult *result = [regex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
	DDLogVerbose( @"Match Result %@", result );
	if( result )
	{
		NSUInteger num = [result numberOfRanges];	// This is the number of capture groups plus the full match as rnage 0.
		DDLogVerbose( @"Number of ranges=%lu", (unsigned long)num );

		NSRange range;
		NSString *cap;

		// First capture group, the address
		range = [result rangeAtIndex:0];
		cap = [line substringWithRange:range];
		DDLogVerbose( @"Range 1 capture '%@'", cap );

		unsigned hexAddr;
		if( [[NSScanner scannerWithString:cap] scanHexInt:&hexAddr] == NO )
		{
			// This is odd
			DDLogError( @"Found hex address '%@' but failed to parse it!", cap );
			return NO;
		}
	
		range = [result rangeAtIndex:2];
		cap = [line substringWithRange:range];
		DDLogVerbose( @"Range 2 capture '%@'", cap );
		
		// Now find each pair of digits.
		NSRange digitRange;
		digitRange.length = 2;
		for( int i=0; i<cap.length; i+=2 )
		{
			digitRange.location = i;
			NSString *digitPair = [cap substringWithRange:digitRange];
			DDLogVerbose( @"Digit pair '%@'", digitPair );
			
			unsigned hexByte;
			if( [[NSScanner scannerWithString:digitPair] scanHexInt:&hexByte] == NO )
			{
				// This is odd
				DDLogError( @"Found hex pair '%@' but failed to parse it!", cap );
				return NO;
			}
			
			// Call back to the write block (typically this would write to memory).
			self.writeBlock( hexAddr, hexByte );
			
			hexAddr++;
			
			self.byteCount++;
		}
	}
	
	// Success is either a valid line parsed, or no match found.
	return YES;
}



#if 0
NSError *error = nil;
NSUInteger matchCount = NSNotFound;
NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9a-fA-F]{4}\\s+([0-9a-fA-F]+)\\s*\\;.*" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
if (regex && !error){
	matchCount = [regex numberOfMatchesInString:<#searchString#> options:0 range:NSMakeRange(0, <#searchString#>.length)];
}
#endif

@end
