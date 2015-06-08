//
//  MainViewController.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/5/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>

#import "MainViewController.h"

#import "CPU Emulation.h"
#import "HexLoader.h"
#import "RegistersView.h"



@interface MainViewController ()

//
// Status
//
@property (weak) IBOutlet NSTextField *programCounter;


//
// Registers
//
@property (weak) IBOutlet NSBox *registersBox;
@property (weak) IBOutlet RegistersView *registersView;


//
// Timing
//
@property (weak) IBOutlet NSTextField *totalCyclesField;

@end



@implementation MainViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
}


-(void)viewWillAppear
{
	[super viewWillAppear];
	
}



#pragma mark - State

- (void)updateState
{
	const CPU *cpu = CPU_getCPU();
	
	[self.programCounter setIntegerValue:cpu->reg[cpu->P]];
}



#pragma mark - Actions

- (IBAction)stepAction:(id)sender
{
	DDLogDebug( @"Step" );
	CPU_step();
	[self updateState];
}


- (IBAction)runAction:(id)sender
{
	DDLogDebug( @"Run" );

	NSTimer *timer = [NSTimer timerWithTimeInterval:0.001 target:self selector:@selector(performStep:) userInfo:nil repeats:YES];

	[[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}


- (void)performStep:(NSTimer*)timer
{
	CPU_step();
	[self updateState];
}



static void ocb( void *userData, uint8_t port, uint8_t data )
{
	DDLogDebug( @"Output port %d  data 0x%02X  '%c'", port, data, data );
}


- (IBAction)pauseAction:(id)sender
{
	DDLogDebug( @"Pause" );

	CPU_makeAllPagesRAM();
	
	CPU_setOutputCallback( ocb, (__bridge void *)(self) );
	
//	HexLoader *loader = [[HexLoader alloc] initWithListingPath:@"/Users/don/Code/Cosmac_1802/toggleQ.lst"];
//	HexLoader *loader = [[HexLoader alloc] initWithListingPath:@"/Users/don/Code/Cosmac_1802/FIG-Forth/FIG_Forth.lst"];
	HexLoader *loader = [[HexLoader alloc] initWithListingPath:@"/Users/don/Dropbox/Documents/RCA 1802/FIG_2/FIG311.LST"];
	
	[loader load:^(long addr, unsigned char byte)
	 {
		 CPU_writeByteToMemory( byte, addr);
	 }];
	
	DDLogDebug( @"Listing loaded into memory, %lu bytes", loader.byteCount );
	
	[self updateState];
}



- (IBAction)resetAction:(id)sender
{
	DDLogDebug( @"Reset" );
	CPU_reset();
	[self updateState];
}


@end
