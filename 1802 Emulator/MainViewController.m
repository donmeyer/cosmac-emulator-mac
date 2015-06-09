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


@property ( strong) NSTimer *cycleTimer;

@end



@implementation MainViewController

#pragma mark - View Lifecycle


static void ocb( void *userData, uint8_t port, uint8_t data )
{
	DDLogDebug( @"Output port %d  data 0x%02X  '%c'", port, data, data );
}


-(instancetype)init
{
	self = [super init];
	if( self )
	{
		
	}
	
	return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.

	CPU_makeAllPagesRAM();
	
	CPU_setOutputCallback( ocb, (__bridge void *)(self) );
	
	[self.registersView setDescription:@"Rats" forReg:0x00];

	[self.registersView setDescription:@"UP" forReg:0x0D];
}


-(void)viewWillAppear
{
	[super viewWillAppear];
	
}



#pragma mark - State

- (void)updateState
{
	const CPU *cpu = CPU_getCPU();
	
	NSString *pcStr = [NSString stringWithFormat:@"%04X", cpu->reg[cpu->P]];
	[self.programCounter setStringValue:pcStr];

	[self.registersView updateRegisters:cpu];
}


- (void)startCycleTimer
{
	self.cycleTimer = [NSTimer timerWithTimeInterval:0.00001 target:self selector:@selector(performStep:) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:self.cycleTimer forMode:NSDefaultRunLoopMode];
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

	[self startCycleTimer];
}


- (void)performStep:(NSTimer*)timer
{
	CPU_step();
	[self updateState];
}


- (IBAction)pauseAction:(id)sender
{
	DDLogDebug( @"Pause" );

	[self.cycleTimer invalidate];
}



- (IBAction)resetAction:(id)sender
{
	DDLogDebug( @"Reset" );
	CPU_reset();
	[self updateState];
}


- (IBAction)importAction:(id)sender
{
	CPU_reset();

	[self browseForListingWithCompletion:^(NSURL *url) {
		// Do this next runloop to let the file chooser go away!
		dispatch_async( dispatch_get_main_queue(), ^(void){
			if( url )
			{
				//	HexLoader *loader = [[HexLoader alloc] initWithListingPath:@"/Users/don/Code/Cosmac_1802/toggleQ.lst"];
				//	HexLoader *loader = [[HexLoader alloc] initWithListingPath:@"/Users/don/Code/Cosmac_1802/FIG-Forth/FIG_Forth.lst"];
//				HexLoader *loader = [[HexLoader alloc] initWithListingPath:@"/Users/don/Dropbox/Documents/RCA 1802/FIG_2/FIG311.LST"];
				
				HexLoader *loader = [[HexLoader alloc] initWithListingPath:[url path]];
				
				[loader load:^(long addr, unsigned char byte)
				 {
					 CPU_writeByteToMemory( byte, addr);
				 }];
				
				DDLogDebug( @"Listing loaded into memory, %lu bytes", loader.byteCount );
				
				[self updateState];
			}
			else
			{
				DDLogDebug( @"No file chosen" );
			}
		});
	}];
}


#pragma mark Ask For File

/**
 * Ask the user for a file which is then read into a string.
 * The string is passed to the completion block.
 */
- (void)browseForListingWithCompletion:(void(^)(NSURL *url))completion
{
	NSArray *allowedFileTypes = @[@"lst"];
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseFiles:YES];
	[panel setAllowedFileTypes:allowedFileTypes];
	
	[panel beginSheetModalForWindow:[self.view window]
				  completionHandler:^(NSInteger result) {
					  
					  if( result != NSFileHandlingPanelOKButton ) {
						  return;
					  }
					  
					  NSURL *url = [panel.URLs firstObject];
					  
					  // If a completion block (and there really shhould be, else what's the point?) call it with the filename.
					  if (completion) {
						  completion( url );
					  }
				  }];
}


@end
