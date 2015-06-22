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

@end



@implementation RegistersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
}


- (void)awakeFromNib
{
	[self.scratchpadView setDescription:@"DMA" forReg:0x00];

	[self.scratchpadView setDescription:@"Interupt PC" forReg:0x01];

	[self.scratchpadView setDescription:@"RP" forReg:0x02];
	[self.scratchpadView setDescription:@"Primitive PC" forReg:0x03];
	
	[self.scratchpadView setDescription:@"Scratch Accum" forReg:0x07];
	[self.scratchpadView setDescription:@"Scratch Accum" forReg:0x08];

	[self.scratchpadView setDescription:@"SP" forReg:0x09];
	
	[self.scratchpadView setDescription:@"IP" forReg:0x0A];
	[self.scratchpadView setDescription:@"W (CFA)" forReg:0x0B];

	[self.scratchpadView setDescription:@"PC for NEXT" forReg:0x0C];

	[self.scratchpadView setDescription:@"UP" forReg:0x0D];

	[self.scratchpadView setDescription:@"Interupt SP" forReg:0x0E];
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
	[self.pcField setStringValue:str];
	
	str = [NSString stringWithFormat:@"%02X", cpu->D];
	[self.dField setStringValue:str];
	
	str = [NSString stringWithFormat:@"%X", cpu->DF];
	[self.dfField setStringValue:str];

	str = [NSString stringWithFormat:@"%X", cpu->X];
	[self.xField setStringValue:str];

	str = [NSString stringWithFormat:@"%X", cpu->P];
	[self.pField setStringValue:str];

	str = [NSString stringWithFormat:@"%X", cpu->N];
	[self.nField setStringValue:str];
	
	str = [NSString stringWithFormat:@"%X", cpu->I];
	[self.iField setStringValue:str];

	str = [NSString stringWithFormat:@"%X", cpu->IE];
	[self.ieField setStringValue:str];

	str = [NSString stringWithFormat:@"%02X", cpu->T];
	[self.tField setStringValue:str];
}


@end
