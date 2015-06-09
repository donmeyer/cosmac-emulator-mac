//
//  RegistersView.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/7/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import "RegistersView.h"

#import "CPU Emulation.h"



#define VERT_INSET		20
#define HORIZ_INSET		20



@interface RegistersView ()

@property (nonatomic, assign) const CPU *cpu;

@property (nonatomic, strong) NSDictionary *labelAttr;
@property (nonatomic, assign) NSSize labelSize;

@property (nonatomic, strong) NSDictionary *regAttr;
@property (nonatomic, assign) NSSize regSize;

@property (nonatomic, strong) NSDictionary *descAttr;
@property (nonatomic, assign) NSSize descSize;

@property (nonatomic, assign) CGFloat rowHeight;

@property (strong) NSMutableDictionary *descDict;

@end



@implementation RegistersView

-(instancetype)initWithFrame:(NSRect)frameRect
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
	self.descDict = [[NSMutableDictionary alloc] init];
	[self calcFonts];
}


- (void)calcFonts
{
	NSFont *font = [NSFont fontWithName:@"Helvetica" size:12.0];

	NSMutableDictionary *ad = [[NSMutableDictionary alloc] init];
	[ad setObject:font forKey:NSFontAttributeName];

	self.labelAttr = ad;
	self.regAttr = ad;
	self.descAttr = ad;

	NSSize fs = [@"M" sizeWithAttributes:self.labelAttr];
//	NSRect br = [font boundingRectForFont];
//	NSSize fs = br.size;
	
	self.labelSize = NSMakeSize( fs.width * 2,fs.height );
	self.regSize = NSMakeSize( fs.width * 4, fs.height );
	self.descSize = NSMakeSize( fs.width * 16, fs.height );	// TODO: this should be remainder of space

	self.rowHeight = fs.height + 5;
}



- (void)drawRect:(NSRect)dirtyRect
{
//    [super drawRect:dirtyRect];	// Not needed since we are a direct subclass of NSView
	
//	[[NSColor grayColor] set];
//	NSRectFill( dirtyRect );

	
//	NSString *dateString = @"rats and bats";
	
	[self drawLabels];
	[self drawRegisters];
	[self drawDescs];
}



- (void)drawLabels
{
	NSRect rowRect = NSMakeRect( HORIZ_INSET, 0, self.labelSize.width, self.labelSize.height );
	
	for( int i=0; i<CPU_NUM_REGS; i++ )
	{
		NSString *rowStr = [NSString stringWithFormat:@"R%X", i ];
		
		rowRect.origin.y = VERT_INSET + ( i * self.rowHeight );
		
		[[NSColor greenColor] set];
		NSRectFill( rowRect );
		
		[rowStr drawInRect:rowRect withAttributes:self.labelAttr];
	}
}


- (void)drawRegisters
{
	if( self.cpu == nil )
	{
		return;
	}
	
	CGFloat x = HORIZ_INSET + self.labelSize.width + 10;
	
	NSRect rowRect = NSMakeRect( x, 0, self.regSize.width, self.regSize.height );
	
	for( int i=0; i<CPU_NUM_REGS; i++ )
	{
		NSString *rowStr = [NSString stringWithFormat:@"%04X", self.cpu->reg[i] ];
		
		rowRect.origin.y = VERT_INSET + ( i * self.rowHeight );
		
		[[NSColor yellowColor] set];
		NSRectFill( rowRect );

		[rowStr drawInRect:rowRect withAttributes:self.labelAttr];
	}
}


- (void)drawDescs
{
	CGFloat x = HORIZ_INSET + self.labelSize.width + 10 + self.regSize.width + 10;
	
	NSRect rowRect = NSMakeRect( x, 0, self.descSize.width, self.descSize.height );
	
	for( int i=0; i<CPU_NUM_REGS; i++ )
	{
		NSString *rowStr = self.descDict[@(i)];
		if( rowStr == nil )
		{
			rowStr = @"";
		}
		rowRect.origin.y = VERT_INSET + ( i * self.rowHeight );
		[rowStr drawInRect:rowRect withAttributes:self.labelAttr];
	}
}


- (void)updateRegisters:(const CPU*)cpu
{
	self.cpu = cpu;
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
