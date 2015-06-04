//
//  HexLoader.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/3/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import "HexLoader.h"



@implementation HexLoader

#if 0
NSError *error = nil;
NSUInteger matchCount = NSNotFound;
NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9a-fA-F]{4}\\s+([0-9a-fA-F]+)\\s*\\;.*" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
if (regex && !error){
	matchCount = [regex numberOfMatchesInString:<#searchString#> options:0 range:NSMakeRange(0, <#searchString#>.length)];
}



NSString *line = @"AA55 12FC;";
NSError *error = nil;
NSUInteger matchCount = NSNotFound;
NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([0-9a-fA-F]{4})\\s+([0-9a-fA-F]+)\\s*\\;.*" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
if( regex && ! error )
{
	matchCount = [regex numberOfMatchesInString:line options:0 range:NSMakeRange(0, line.length)];
}
MMLog( @"Regex=%@", regex );


NSTextCheckingResult *result;
result = [regex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
MMLogVerbose( @"Date Result %@", result );
if( result )
{
	NSUInteger num = [result numberOfRanges];
	NSRange range = [result rangeAtIndex:1];
	NSString *cap = [line substringWithRange:range];
	MMLog( @"num=%lu   cap = '%@'", (unsigned long)num, cap );
	
	range = [result rangeAtIndex:2];
	cap = [line substringWithRange:range];
	MMLog( @"num=%lu   cap = '%@'", (unsigned long)num, cap );
}
#endif


@end
