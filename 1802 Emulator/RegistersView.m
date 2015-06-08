//
//  RegistersView.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/7/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import "RegistersView.h"



@implementation RegistersView

- (void)drawRect:(NSRect)dirtyRect
{
	//    [super drawRect:dirtyRect];	// Not needed since we are a direct subclass of NSView
	
    // Drawing code here.

	[[NSColor grayColor] set];
	NSRectFill( dirtyRect );

	
	NSString *dateString = @"rats and bats";
	
	
	NSFont *font = [NSFont fontWithName:@"Helvetica" size:12.0];
	NSMutableDictionary *ad = [[NSMutableDictionary alloc] init];
	[ad setObject:font forKey:NSFontAttributeName];
	
	NSSize fs = [@"RF" sizeWithAttributes:ad];
	
	NSRect rowRect = NSMakeRect( 20, 50, fs.width, 20 );
	
	for( int i=0; i<16; i++ )
	{
		NSString *rowStr = [NSString stringWithFormat:@"R%X", i ];
		
		rowRect.origin.y = 50 + ( i * ( fs.height + 5 ) );
		NSPoint rowPoint;
		rowPoint.x = 20;
		rowPoint.y = 50 + ( i * ( fs.height + 5 ) );
//		[rowStr drawInRect:rowRect withAttributes:ad];
		[rowStr drawAtPoint:rowPoint withAttributes:ad];
	}
}



// Origin of view is upper left corner
- (BOOL)isFlipped
{
	return YES;
}


@end
