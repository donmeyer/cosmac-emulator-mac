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



@end



@implementation RegistersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
}


- (void)awakeFromNib
{
	[self.scratchpadView setDescription:@"zero" forReg:0x00];
	
	[self.scratchpadView setDescription:@"UP" forReg:0x0D];
}


- (void)updateCPUState:(const CPU*)cpu
{
	[self.scratchpadView updateRegisters:cpu];


	NSString *pcStr = [NSString stringWithFormat:@"%04X", cpu->reg[cpu->P]];
	[self.pcField setStringValue:pcStr];
	
	NSString *dStr = [NSString stringWithFormat:@"%02X", cpu->D];
	[self.dField setStringValue:dStr];
	
	NSString *dfStr = [NSString stringWithFormat:@"%X", cpu->DF];
	[self.dfField setStringValue:dfStr];
}


@end
