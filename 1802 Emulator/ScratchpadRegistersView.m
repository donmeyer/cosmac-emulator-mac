//
//  ScratchpadRegistersView.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/7/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import "ScratchpadRegistersView.h"

#import "CPU Emulation.h"



#define COLOR_DEBUG		0

#define VERT_INSET		20
#define HORIZ_INSET		20



@interface ScratchpadRegistersView ()

@property (nonatomic, assign) CPU cpu;
@property (nonatomic, assign) CPU prevCPU;

@property (nonatomic, strong) NSDictionary *tagAttr;
@property (nonatomic, assign) NSSize tagSize;

@property (nonatomic, strong) NSDictionary *labelAttr;
@property (nonatomic, assign) NSSize labelSize;

@property (nonatomic, strong) NSDictionary *regAttr;
@property (nonatomic, strong) NSDictionary *regAttrDelta;
@property (nonatomic, assign) NSSize regSize;

@property (nonatomic, strong) NSDictionary *descAttr;
@property (nonatomic, assign) NSSize descSize;

@property (nonatomic, assign) CGFloat rowHeight;

@property (strong) NSMutableDictionary *descDict;

@end



@implementation ScratchpadRegistersView

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if( self )
	{
		_descDict = [[NSMutableDictionary alloc] init];
		[self calcFonts];
	}
	
	return self;
}


- (void)awakeFromNib
{
	[super awakeFromNib];

	self.descDict = [[NSMutableDictionary alloc] init];
	[self calcFonts];
}


- (void)calcFonts
{
	NSFont *font = [NSFont fontWithName:@"Helvetica" size:12.0];
	NSFont *font2 = [NSFont fontWithName:@"Times" size:12.0];
	
	NSSize fs;
	
	// Tags
	self.tagAttr = @{ NSFontAttributeName : font,
						NSForegroundColorAttributeName : [NSColor darkGrayColor] };
	fs = [@"M" sizeWithAttributes:self.tagAttr];
	self.tagSize = NSMakeSize( fs.width * 4,fs.height );
	
	// Labels
	self.labelAttr = @{ NSFontAttributeName : font,
						NSForegroundColorAttributeName : [NSColor blackColor] };
	fs = [@"M" sizeWithAttributes:self.labelAttr];
	self.labelSize = NSMakeSize( fs.width * 2,fs.height );
	
	// Register values
	self.regAttr = @{ NSFontAttributeName : font,
					  NSForegroundColorAttributeName : [NSColor blackColor] };
	self.regAttrDelta = @{ NSFontAttributeName : font,
						   NSForegroundColorAttributeName : [NSColor redColor] };
	fs = [@"M" sizeWithAttributes:self.regAttr];
	self.regSize = NSMakeSize( fs.width * 4, fs.height );
	
	self.rowHeight = fs.height + 5;		// let's use the register value size as the row size...
	
	// Description
	self.descAttr = @{ NSFontAttributeName : font2,
					   NSForegroundColorAttributeName : [NSColor darkGrayColor] };
	fs = [@"M" sizeWithAttributes:self.descAttr];
	self.descSize = NSMakeSize( fs.width * 20, fs.height );	// TODO: this should be remainder of space
}



- (void)drawRect:(NSRect)dirtyRect
{
//    [super drawRect:dirtyRect];	// Not needed since we are a direct subclass of NSView
	
//	[[NSColor grayColor] set];
//	NSRectFill( dirtyRect );

	
//	NSString *dateString = @"rats and bats";
	
	[self drawTags];
	[self drawLabels];
	[self drawRegisters];
	[self drawDescs];
}


- (void)drawTags
{
	NSRect rowRect = NSMakeRect( HORIZ_INSET, 0, self.tagSize.width, self.tagSize.height );
	
	int pc = self.cpu.P;
	int x = self.cpu.X;
	
	if( pc == x )
	{
		// Samed reg
		NSString *rowStr = [NSString stringWithFormat:@"PC X" ];
		rowRect.origin.y = VERT_INSET + ( pc * self.rowHeight );
		[rowStr drawInRect:rowRect withAttributes:self.tagAttr];
		
#if COLOR_DEBUG
		[[NSColor orangeColor] set];
		NSRectFill( rowRect );
#endif
	}
	else
	{
		NSString *rowStr = [NSString stringWithFormat:@"PC" ];
		rowRect.origin.y = VERT_INSET + ( pc * self.rowHeight );
		[rowStr drawInRect:rowRect withAttributes:self.tagAttr];
		
#if COLOR_DEBUG
		[[NSColor orangeColor] set];
		NSRectFill( rowRect );
#endif
		
		rowStr = [NSString stringWithFormat:@"X" ];
		rowRect.origin.y = VERT_INSET + ( x * self.rowHeight );
		[rowStr drawInRect:rowRect withAttributes:self.tagAttr];
		
#if COLOR_DEBUG
		[[NSColor orangeColor] set];
		NSRectFill( rowRect );
#endif
	}
}


- (void)drawLabels
{
	NSRect rowRect = NSMakeRect( HORIZ_INSET + self.tagSize.width + 6, 0, self.labelSize.width, self.tagSize.height );
	
	for( int i=0; i<CPU_NUM_REGS; i++ )
	{
		NSString *rowStr = [NSString stringWithFormat:@"R%X", i ];
		
		rowRect.origin.y = VERT_INSET + ( i * self.rowHeight );
		
#if COLOR_DEBUG
		[[NSColor greenColor] set];
		NSRectFill( rowRect );
#endif
		
		[rowStr drawInRect:rowRect withAttributes:self.labelAttr];
	}
}


- (void)drawRegisters
{
//	if( self.cpu == nil )
//	{
//		return;
//	}
	
	CGFloat x = HORIZ_INSET + self.tagSize.width + self.labelSize.width + 6 + 6;
	
	NSRect rowRect = NSMakeRect( x, 0, self.regSize.width, self.regSize.height );
	
	for( int i=0; i<CPU_NUM_REGS; i++ )
	{
		if( self.cpu.reg[i] != self.prevCPU.reg[i] )
		{
			[[NSColor yellowColor] setStroke];
		}
		else
		{
			[[NSColor blackColor] setStroke];
			
		}
		
		NSString *rowStr = [NSString stringWithFormat:@"%04X", self.cpu.reg[i] ];
		
		rowRect.origin.y = VERT_INSET + ( i * self.rowHeight );
		
#if COLOR_DEBUG
		[[NSColor yellowColor] set];
		NSRectFill( rowRect );
#endif
		
		if( self.cpu.reg[i] != self.prevCPU.reg[i] )
		{
			[rowStr drawInRect:rowRect withAttributes:self.regAttrDelta];
		}
		else
		{
			[rowStr drawInRect:rowRect withAttributes:self.regAttr];
		}
	}
}


- (void)drawDescs
{
	CGFloat x = HORIZ_INSET + self.tagSize.width + self.labelSize.width + 10 + self.regSize.width + 4;
	
	NSRect rowRect = NSMakeRect( x, 0, self.descSize.width, self.descSize.height );
	
	for( int i=0; i<CPU_NUM_REGS; i++ )
	{
		NSString *rowStr = self.descDict[@(i)];
		if( rowStr == nil )
		{
			rowStr = @"";
		}
		rowRect.origin.y = VERT_INSET + ( i * self.rowHeight );

#if COLOR_DEBUG
		[[NSColor brownColor] set];
		NSRectFill( rowRect );
#endif
		
		[rowStr drawInRect:rowRect withAttributes:self.descAttr];
	}
}


- (void)updateRegisters:(const CPU*)cpu
{
	self.prevCPU = self.cpu;	// Retain for delta comparison
	self.cpu = *cpu;
	[self setNeedsDisplay:YES];
}


- (void)setDescription:(NSString*)desc forReg:(int)reg
{
	self.descDict[@(reg)] = desc;
}



// Make the origin of the view the upper left corner, like iOS!
- (BOOL)isFlipped
{
	return YES;
}

@end
