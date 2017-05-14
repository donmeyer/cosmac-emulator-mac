//
//  HexLoader.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/3/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//


#import "HexLoader.h"



//static const DDLogLevel ddLogLevel = DDLogLevelDebug;





@implementation Symbol

- (instancetype)initWithName:(NSString*)name addr:(unsigned int) addr
{
	self = [super init];
	if( self )
	{
		_name = name;
		_addr = addr;
		_endAddr = 0xFFFF;
	}
	
	return self;
}

@end





@interface HexLoader ()

@property (nonatomic, strong) NSString *listingString;

@property (nonatomic, assign) long byteCount;	// Count of bytes written to memory.

@property (nonatomic, strong) void (^writeBlock)(long addr, unsigned char byte);

@property (strong, readwrite) NSMutableArray *symbols;

@end



@implementation HexLoader


- (id)initWithListingString:(NSString*)listingString
{
	self = [super init];
	if( self )
	{
		_listingString = listingString;
		_symbols = [[NSMutableArray alloc] init];
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
		LogWarn( @"Unable to load listing" );
	}
	
	LogDebug( @"File %@ is a string of len %lu", path, [s length] );
	
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
				// Not a valid listing line, probably a symbol table line?
				[self processSymbolTableLine:line];
			}
		}
	}
	
	// Sort the symbols
	[self.symbols sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		if( [obj1 addr] < [obj2 addr] )
		{
			return NSOrderedAscending;
		}
		else if( [obj1 addr] > [obj2 addr] )
		{
			return NSOrderedDescending;
		}
		else
		{
			return NSOrderedSame;
		}
	}];
	
	
	// Fill in the end address for each symbol
	Symbol *prevSym = nil;
	for( Symbol *sym in self.symbols )
	{
		if( prevSym != nil && sym.addr > prevSym.addr )
		{
			prevSym.endAddr = sym.addr - 1;
		}
		
		prevSym = sym;
	}
	
	return YES;
}



- (BOOL)processListingLine:(NSString*)line
{
	// We expect listing lines to look like:  "AA55 12FC;         0006  LOOP	DEC R2"  (symbol is optional)
	NSError *error = nil;
	
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([0-9a-fA-F]{4}) \\s+ ([0-9a-fA-F]+) \\s* \\;" options:NSRegularExpressionDotMatchesLineSeparators |  NSRegularExpressionAllowCommentsAndWhitespace error:&error];
	NSAssert( ( regex != nil && error == nil ), @"Error build regex: %@", error );
	
	//	NSUInteger matchCount = [regex numberOfMatchesInString:line options:0 range:NSMakeRange(0, line.length)];
	//	LogVerbose( @"Regex=%@, matchcount=%lu", regex, matchCount );
	
	LogVerbose( @"-------------------- Line: '%@'", line );

	NSTextCheckingResult *result;

	result = [regex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
	LogVerbose( @"Match Result %@", result );
	if( result )
	{
	
		NSUInteger num = [result numberOfRanges];	// This is the number of capture groups plus the full match as range 0.
		LogVerbose( @"Number of ranges=%lu", (unsigned long)num );
		
		// 0 - full match
		// 1 - Address
		// 2 - Code bytes as hex digits (optional)
		// 3 - Label (optional)
		// 4 - Source mnemonics (optional)
		
		NSRange range;
		NSString *cap;
		
		// First capture group, the address
		range = [result rangeAtIndex:1];
		cap = [line substringWithRange:range];
		LogVerbose( @"Range 1 (addr) capture '%@'", cap );
		
		unsigned hexAddr;
		if( [[NSScanner scannerWithString:cap] scanHexInt:&hexAddr] == NO )
		{
			// This is odd
			LogError( @"Found hex address '%@' but failed to parse it!", cap );
			return NO;
		}

		range = [result rangeAtIndex:2];
		cap = [line substringWithRange:range];
		LogVerbose( @"Range 2 (opcodes) capture '%@'", cap );
		
		// Now find each pair of digits and handle them.
		BOOL parseRC = [self _parseOpcodePairs:cap atHexAddress:hexAddr];
		if( parseRC == NO )
		{
			return NO;
		}
	}
	
	return NO;
}



/// Parse hex pairs from the given string and write the bytes to the write block.
/// Returns NO if there was a problem,
- (BOOL)_parseOpcodePairs:(NSString*)cap atHexAddress:(unsigned)hexAddr
{
	NSRange digitRange;
	digitRange.length = 2;
	for( int i=0; i<cap.length; i+=2 )
	{
		digitRange.location = i;
		NSString *digitPair = [cap substringWithRange:digitRange];
		LogVerbose( @"Digit pair '%@'", digitPair );
		
		unsigned hexByte;
		if( [[NSScanner scannerWithString:digitPair] scanHexInt:&hexByte] == NO )
		{
			// This is odd
			LogError( @"Found hex pair '%@' but failed to parse it!", cap );
			return NO;
		}
		
		// Call back to the write block (typically this would write to memory).
		self.writeBlock( hexAddr, hexByte );
		
		hexAddr++;
		
		self.byteCount++;
	}
	
	return YES;
}


- (void)_parseSource:(NSString*)string
{
	// The line number, optional symbol, and optional asm source.

	
}


- (BOOL)processSymbolTableLine:(NSString*)line
{
	// We expect symbol lines to look like:  "FOO : 12FC"
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(.+) : ([0-9a-fA-F]{4}).*"
																		   options:NSRegularExpressionDotMatchesLineSeparators
																			 error:&error];
	NSAssert( ( regex != nil && error == nil ), @"Error build regex: %@", error );
	
//	NSUInteger matchCount = [regex numberOfMatchesInString:line options:0 range:NSMakeRange(0, line.length)];	
//	LogVerbose( @"Regex=%@, matchcount=%lu", regex, matchCount );

	NSTextCheckingResult *result = [regex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
	LogVerbose( @"Symbol Match Result %@", result );
	if( result )
	{
		NSUInteger num = [result numberOfRanges];	// This is the number of capture groups plus the full match as rnage 0.
		LogVerbose( @"Number of ranges=%lu", (unsigned long)num );

		NSRange range;
		NSString *cap;

		// First capture group, the name
		range = [result rangeAtIndex:1];
		cap = [line substringWithRange:range];
		LogVerbose( @"Range 1 capture '%@'", cap );

		NSString *name = cap;
	
		// Second capture group, the address
		range = [result rangeAtIndex:2];
		cap = [line substringWithRange:range];
		LogVerbose( @"Range 2 capture '%@'", cap );
		
		unsigned hexAddr;
		if( [[NSScanner scannerWithString:cap] scanHexInt:&hexAddr] == NO )
		{
			// This is odd
			LogError( @"Found hex address '%@' but failed to parse it!", cap );
			return NO;
		}
		
		// Add entry to table
		Symbol *sym = [[Symbol alloc] initWithName:name addr:hexAddr];
		[self.symbols addObject:sym];
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
