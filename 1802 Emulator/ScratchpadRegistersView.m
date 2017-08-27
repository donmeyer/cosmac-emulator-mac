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
#define HORIZ_INSET		12



@interface ScratchpadRegistersView ()

@property (nonatomic, assign) CPU cpu;
@property (nonatomic, assign) CPU prevCPU;

@property (nonatomic, strong) NSDictionary *tagAttr;
@property (nonatomic) CGRect tagRect;

@property (nonatomic, strong) NSDictionary *labelAttr;
@property (nonatomic) CGRect labelRect;

@property (nonatomic, strong) NSDictionary *regAttr;
@property (nonatomic, strong) NSDictionary *regAttrDelta;
@property (nonatomic) CGRect regRect;

@property (nonatomic, strong) NSDictionary *descAttr;
@property (nonatomic) CGRect descRect;
@property (strong) NSMutableDictionary *descDict;

@property (nonatomic, assign) CGFloat rowHeight;

@end



@implementation ScratchpadRegistersView

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if( self )
	{
		_descDict = [[NSMutableDictionary alloc] init];
		
		_changedColor = [NSColor redColor];
		
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

- (void)setChangedColor:(NSColor *)changedColor
{
	_changedColor = changedColor;
	[self calcFonts];
}


- (void)calcFonts
{
	NSFont *font = [NSFont fontWithName:@"Helvetica" size:12.0];
	NSFont *font2 = [NSFont fontWithName:@"Times" size:12.0];
	
	NSSize fs;
	CGFloat x;
	
	// Tags
	self.tagAttr = @{ NSFontAttributeName : font,
						NSForegroundColorAttributeName : [NSColor darkGrayColor] };
	fs = [@"M" sizeWithAttributes:self.tagAttr];
	self.tagRect = NSMakeRect( HORIZ_INSET, 0, fs.width * 4,fs.height );
	
	// Labels
	self.labelAttr = @{ NSFontAttributeName : font,
						NSForegroundColorAttributeName : [NSColor blackColor] };
	fs = [@"M" sizeWithAttributes:self.labelAttr];
	self.labelRect = NSMakeRect( HORIZ_INSET + self.tagRect.size.width + 6, 0, fs.width * 2,fs.height );
	
	// Register values
	self.regAttr = @{ NSFontAttributeName : font,
					  NSForegroundColorAttributeName : [NSColor blackColor] };
	self.regAttrDelta = @{ NSFontAttributeName : font,
						   NSForegroundColorAttributeName : self.changedColor };
	fs = [@"M" sizeWithAttributes:self.regAttr];
	x = HORIZ_INSET + self.tagRect.size.width + self.labelRect.size.width + 6 + 6;
	self.regRect = NSMakeRect( x, 0, fs.width * 4, fs.height );
	
	self.rowHeight = fs.height + 5;		// let's use the register value size as the row size...
	
	// Description
	self.descAttr = @{ NSFontAttributeName : font2,
					   NSForegroundColorAttributeName : [NSColor darkGrayColor] };
	fs = [@"M" sizeWithAttributes:self.descAttr];
//	self.descSize = NSMakeSize( fs.width * 20, fs.height );	// TODO: this should be remainder of space
	x = HORIZ_INSET + self.tagRect.size.width + self.labelRect.size.width + 10 + self.regRect.size.width + 4;
	CGFloat w = self.frame.size.width - x - 4;
	self.descRect = NSMakeRect( x, 0, w, fs.height );
}



- (void)drawRect:(NSRect)dirtyRect
{
//    [super drawRect:dirtyRect];	// Not needed since we are a direct subclass of NSView
	
#if COLOR_DEBUG
	[[NSColor blueColor] set];
	NSRectFill( dirtyRect );
#endif
	
	[self drawTags];
	[self drawLabels];
	[self drawRegisters];
	[self drawDescs];
}


- (void)drawTags
{
	int pc = self.cpu.P;
	int x = self.cpu.X;
	
	CGRect rowRect = self.tagRect;
	
	if( pc == x )
	{
		// Same reg
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
	CGRect rowRect = self.labelRect;
	
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
	
	NSRect rowRect = self.regRect;
	
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
	NSRect rowRect = self.descRect;
	
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

- (void)clearDescriptions
{
	for( int reg=0; reg<CPU_NUM_REGS; reg++ )
	{
		[self setDescription:@"" forReg:reg];
	}
}


// Make the origin of the view the upper left corner, like iOS!
- (BOOL)isFlipped
{
	return YES;
}

@end
