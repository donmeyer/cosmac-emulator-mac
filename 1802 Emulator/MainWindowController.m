//
//  MainWindowController.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/12/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import "MainWindowController.h"
#import "CPU Emulation.h"
#import "HexLoader.h"
#import "RegistersView.h"



static const DDLogLevel ddLogLevel = DDLogLevelVerbose;



@interface MainWindowController ()

//
// Status
//
@property (weak) IBOutlet NSTextField *programCounter;
@property (weak) IBOutlet NSTextField *dLabel;
@property (weak) IBOutlet NSTextField *dfLabel;

//
// Registers
//
@property (weak) IBOutlet NSBox *registersBox;
@property (weak) IBOutlet RegistersView *registersView;


//
// Timing
//
@property (weak) IBOutlet NSTextField *totalCyclesField;


@property (weak) IBOutlet NSTextField *breakpoint1Field;
@property (weak) IBOutlet NSButton *breakpoint1Checkbox;

@property (weak) IBOutlet NSTextField *breakpoint2Field;
@property (weak) IBOutlet NSButton *breakpoint2Checkbox;

@property (weak) IBOutlet NSButton *outputPort2Checkbox;

@property (weak) IBOutlet NSTextField *stastusLabel;
@property (weak) IBOutlet NSTextField *symbolLabel;

@property ( strong) NSTimer *cycleTimer;


@property (strong) HexLoader *loader;

@end




@implementation MainWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	CPU_makeAllPagesRAM();
	
	CPU_setOutputCallback( ocb, (__bridge void *)(self) );
	
	CPU_setInputCallback( icb, (__bridge void *)(self) );
}


- (void)awakeFromNib
{
	[self.registersView setDescription:@"Rats" forReg:0x00];
	
	[self.registersView setDescription:@"UP" forReg:0x0D];
	
	[self.stastusLabel setStringValue:@""];
}



#pragma mark - View Lifecycle


static void ocb( void *userData, uint8_t port, uint8_t data )
{
	DDLogDebug( @"Output port %d  data 0x%02X  '%c'", port, data, data );
	
	MainWindowController *mvc = (__bridge MainWindowController*)userData;
	
	if( mvc.outputPort2Checkbox.state == NSOnState )
	{
		[mvc.stastusLabel setStringValue:@"Breakpoint: Output Port 2"];
		
		[mvc.cycleTimer invalidate];
	}
}



static uint8_t icb( void *userData, uint8_t port )
{
	DDLogDebug( @"Input port %d", port );
	
	MainWindowController *mvc = (__bridge MainWindowController*)userData;
	
	if( port == 3 )
	{
		return 0x81;
	}
	
	if( port == 2 )
	{
		return 0x0D;
	}
	
	return 0;
}


- (NSString*)symbolForAddr:(unsigned int)addr
{
	for( Symbol *sym in self.loader.symbols )
	{
		if( addr >= sym.addr )
		{
			// Bingo
			return sym.name;
		}
	}
	
	return @"none";
}




#pragma mark - State

- (void)updateState
{
	const CPU *cpu = CPU_getCPU();
	
	NSString *pcStr = [NSString stringWithFormat:@"%04X", cpu->reg[cpu->P]];
	[self.programCounter setStringValue:pcStr];
	
	NSString *dStr = [NSString stringWithFormat:@"%02X", cpu->D];
	[self.dLabel setStringValue:dStr];
	
	NSString *dfStr = [NSString stringWithFormat:@"%X", cpu->DF];
	[self.dfLabel setStringValue:dfStr];
	
	[self.registersView updateRegisters:cpu];
	
	NSString *symName = [self symbolForAddr:cpu->reg[cpu->P]];
	[self.symbolLabel setStringValue:symName];
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
	
	[self.stastusLabel setStringValue:@"Running"];
	
	[self startCycleTimer];
}


- (void)performStep:(NSTimer*)timer
{
	const CPU *cpu = CPU_getCPU();
	
	if( self.breakpoint1Checkbox.state == NSOnState )
	{
		NSString *s = self.breakpoint1Field.stringValue;
		unsigned hexAddr;
		if( [[NSScanner scannerWithString:s] scanHexInt:&hexAddr] == YES )
		{
			if( hexAddr == cpu->reg[cpu->P] )
			{
				[self.stastusLabel setStringValue:@"Breakpoint: Adder 1"];
				
				[self.cycleTimer invalidate];
			}
		}
	}
	
	CPU_step();
	[self updateState];
}





- (IBAction)resetAction:(id)sender
{
	DDLogDebug( @"Reset" );
	
	[self.stastusLabel setStringValue:@"Reset"];
	
	CPU_reset();
	[self updateState];
}


- (IBAction)importAction:(id)sender
{
	[self openDocument];
}



#pragma mark Ask For File

- (void)openDocument
{
	CPU_reset();
	
	[self browseForListingWithCompletion:^(NSURL *url) {
		// Do this next runloop to let the file chooser go away!
		dispatch_async( dispatch_get_main_queue(), ^(void){
			if( url )
			{
				[self loadFile:[url path]];
			}
			else
			{
				DDLogDebug( @"No file chosen" );
			}
		});
	}];
}

- (void)loadFile:(NSString*)path
{
	//	HexLoader *loader = [[HexLoader alloc] initWithListingPath:@"/Users/don/Code/Cosmac_1802/toggleQ.lst"];
	//	HexLoader *loader = [[HexLoader alloc] initWithListingPath:@"/Users/don/Code/Cosmac_1802/FIG-Forth/FIG_Forth.lst"];
	//				HexLoader *loader = [[HexLoader alloc] initWithListingPath:@"/Users/don/Dropbox/Documents/RCA 1802/FIG_2/FIG311.LST"];
	
	self.loader = [[HexLoader alloc] initWithListingPath:path];
	
	[self.loader load:^(long addr, unsigned char byte)
	 {
		 CPU_writeByteToMemory( byte, addr);
	 }];
	
	DDLogDebug( @"Listing loaded into memory, %lu bytes", self.loader.byteCount );
	
	[self updateState];
}


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
	
	[panel beginSheetModalForWindow:[self window]
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

- (IBAction)pauseAction:(id)sender
{
	DDLogDebug( @"Pause" );
	
//	[self.stastusLabel setStringValue:@"Paused"];
//	
//	[self.cycleTimer invalidate];
}

@end
