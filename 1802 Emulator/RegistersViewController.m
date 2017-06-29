//
//  RegistersViewController.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/12/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import "RegistersViewController.h"
#import "CPU Emulation.h"
#import "ScratchpadRegistersView.h"




@interface RegistersViewController ()

@property (weak) IBOutlet ScratchpadRegistersView *scratchpadView;

@property (weak) IBOutlet NSTextField *pcField;
@property (weak) IBOutlet NSTextField *dField;

@property (weak) IBOutlet NSTextField *dfField;

@property (weak) IBOutlet NSTextField *iField;
@property (weak) IBOutlet NSTextField *nField;
@property (weak) IBOutlet NSTextField *xField;
@property (weak) IBOutlet NSTextField *pField;
@property (weak) IBOutlet NSTextField *ieField;
@property (weak) IBOutlet NSTextField *tField;

@property (weak) IBOutlet NSButton *liveUpdateCheckbox;

@property (nonatomic, strong) NSColor *changedColor;

@property (nonatomic, assign) CPU prevCPU;

@end



@implementation RegistersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
	
	self.changedColor = [NSColor blueColor];
	self.scratchpadView.changedColor = self.changedColor;
}


- (void)awakeFromNib
{
}


- (void)doField:(NSTextField*)field text:(NSString*)text changed:(BOOL)changed
{
	field.textColor = changed ?  self.changedColor : [NSColor blackColor];
	[field setStringValue:text];
}


- (void)updateCPUState:(const CPU*)cpu force:(BOOL)force
{
	if( ! force && self.liveUpdateCheckbox.state == 0 )
	{
		return;
	}

	[self.scratchpadView updateRegisters:cpu];


	NSString *str;
 
	str = [NSString stringWithFormat:@"%04X", cpu->reg[cpu->P]];
//	[self doField:self.pcField text:str changed:cpu->reg[cpu->P] != self.prevCPU.reg[cpu->P]];
	[self doField:self.pcField text:str changed:NO];
	
	str = [NSString stringWithFormat:@"%02X", cpu->D];
	[self doField:self.dField text:str changed:cpu->D != self.prevCPU.D];
	
	str = [NSString stringWithFormat:@"%X", cpu->DF];
	[self doField:self.dfField text:str changed:cpu->DF != self.prevCPU.DF];
	
	str = [NSString stringWithFormat:@"%X", cpu->X];
	[self doField:self.xField text:str changed:cpu->X != self.prevCPU.X];
	
	str = [NSString stringWithFormat:@"%X", cpu->P];
	[self doField:self.pField text:str changed:cpu->P != self.prevCPU.P];
	
	str = [NSString stringWithFormat:@"%X", cpu->N];
//	[self doField:self.nField text:str changed:cpu->N != self.prevCPU.N];
	[self doField:self.nField text:str changed:NO];
	
	str = [NSString stringWithFormat:@"%X", cpu->I];
//	[self doField:self.iField text:str changed:cpu->I != self.prevCPU.I];
	[self doField:self.iField text:str changed:NO];
	
	str = [NSString stringWithFormat:@"%X", cpu->IE];
	[self doField:self.ieField text:str changed:cpu->IE != self.prevCPU.IE];
	
	str = [NSString stringWithFormat:@"%02X", cpu->T];
	[self doField:self.tField text:str changed:cpu->T != self.prevCPU.T];
	
	self.prevCPU = *cpu;
}


/**
 * Clear the changed markers.
 */
- (void)reset
{
	[self updateCPUState:&_prevCPU force:YES];
}


- (void)setDescription:(NSString*)desc forReg:(int)reg
{
	[self.scratchpadView setDescription:desc forReg:reg];
}

- (void)clearDescriptions
{
	[self.scratchpadView clearDescriptions];
}



@end
