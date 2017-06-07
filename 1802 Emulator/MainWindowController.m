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
#import "ScratchpadRegistersView.h"
#import "RegistersViewController.h"
#import "_802_Emulator-Swift.h"

//static const DDLogLevel ddLogLevel = DDLogLevelDebug;


NS_ENUM( NSInteger, RunMode ) {
	RunModePause,
	RunModeStepping,
	RunModeRunning
};


@interface MainWindowController ()

//
// Status
//
@property (strong) IBOutlet RegistersViewController *registersViewController;
@property (weak) IBOutlet NSView *regView;

//
//
//
@property (weak) IBOutlet NSView *portsView;
@property (weak) IBOutlet NSView *sourceView;

//
// Timing
//
@property (weak) IBOutlet NSTextField *totalCyclesField;


@property (weak) IBOutlet NSTextField *breakpoint1Field;
@property (weak) IBOutlet NSButton *breakpoint1Checkbox;

@property (weak) IBOutlet NSTextField *breakpoint2Field;
@property (weak) IBOutlet NSButton *breakpoint2Checkbox;

@property (weak) IBOutlet NSButton *outputPort2Checkbox;

@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSTextField *symbolLabel;


//
// Buttons
//
@property (weak) IBOutlet NSButton *resetButton;
@property (weak) IBOutlet NSButton *stepButton;
@property (weak) IBOutlet NSButton *runButton;
@property (weak) IBOutlet NSButton *importButton;


@property (strong) AllIOPortsViewController *ioPorts;
@property (strong) TerminalWindowController *terminalWindowController;
@property (strong) SourceViewController *sourceViewController;

@property (strong) NSTimer *cycleTimer;

@property (strong) HexLoader *loader;

@property (nonatomic, strong) Symbol *currentSymbol;

@property (strong) Symbol *stepTrapSymbol;	// If set, step until symbol no longer matchs this one

@property (strong) NSMutableSet *stepIgnoreSymbols;

@property (nonatomic, assign) enum RunMode runmode;


@property (nonatomic, assign) BOOL liveSymbolUpdates;

@property (nonatomic, assign) BOOL useTerminalForIO;

@end




@implementation MainWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	CPU_makeAllPagesRAM();
	
	// Callback that we get when the CPU writes to an IO port.
	CPU_setOutputCallback( ocb, (__bridge void *)(self) );
	
	// Callback that we get when the CPU reades from an IO port.
	CPU_setInputCallback( icb, (__bridge void *)(self) );

	// Callback we get during the CPU fetch cycle that tells us an IO instruction is what will excute next.
	// This early warning allows us to trigger a breakpoint before the IO instruction executes.
	CPU_setIOTrapCallback( iotrap, (__bridge void *)(self) );

	self.registersViewController = [[RegistersViewController alloc] initWithNibName:@"RegistersView" bundle:nil];
//	self.registersViewController.view = self.regView;

	[self.regView addSubview:[self.registersViewController view]];
	
	
	//
	// IO Ports
	//
	AllIOPortsViewController *pv = [[AllIOPortsViewController alloc] init];
	NSLog( @"IO port view frame: %@", NSStringFromRect( pv.view.frame ) );
	
//	NSSize pre = pv.preferredContentSize;
//	[pv.view setFrameSize:pre];

	[self.portsView addSubview:pv.view];
	[pv setOutputPort:2 byte:22];
	[pv setOutputPort:7 byte:77];
	self.ioPorts = pv;

	
	//
	// Sourcecode View
	//
	self.sourceViewController = [[SourceViewController alloc] init];
	NSLog( @"Source view frame: %@", NSStringFromRect( self.sourceViewController.view.frame ) );
	NSView *svv = self.sourceViewController.view;
	self.sourceView.autoresizesSubviews = YES;
	
	NSRect r = self.sourceViewController.view.frame;
	r.size.width = self.sourceView.bounds.size.width;
	r.size.height = self.sourceView.bounds.size.height;
	self.sourceViewController.view.frame = r;
	
	[self.sourceView addSubview:svv];
	
	

	self.terminalWindowController = [[TerminalWindowController alloc] initWithWindowNibName:@"TerminalWindow"];
	self.terminalWindowController.window.delegate = self;


	CPU_reset();
	//	[self loadFile:@"/Users/don/Code/Cosmac 1802/FIG/FIG_Forth.lst"];
	[self loadFile:@"/Users/don/Code/Cosmac 1802/asm_src/slowq.lst"];
}


- (void)awakeFromNib
{
	[self.statusLabel setStringValue:@""];
	
	self.stepIgnoreSymbols = [[NSMutableSet alloc] init];
}


- (void)windowWillClose:(NSNotification *)notification
{
	if( notification.object == self.terminalWindowController.window )
	{
		LogDebug( @"Terminal close" );
		self.useTerminalForIO = NO;
	}
}


#pragma mark - IO Port Emulation


static void ocb( void *userData, uint8_t port, uint8_t data )
{
	LogVerbose( @"Output port %d  data 0x%02X  '%c'", port, data, data );
	
	MainWindowController *mvc = (__bridge MainWindowController*)userData;
	[mvc writeOutputPort:port data:data];
	
}


static uint8_t icb( void *userData, uint8_t port )
{
//	LogDebug( @"Input port %d", port );
	
	MainWindowController *mvc = (__bridge MainWindowController*)userData;
	return [mvc readInputPort:port];
}


static void iotrap( void *userData, int inputPort, int outputPort )
{
	MainWindowController *mvc = (__bridge MainWindowController*)userData;
	[mvc handleIOTrap:inputPort outputPort:outputPort];
}


- (void)handleIOTrap:(int)inputPort outputPort:(int)outputPort
{
	if( inputPort > 0 )
	{
		if( [self.ioPorts shouldBreakOnPortRead:inputPort] )
		{
			NSString *s = [NSString stringWithFormat:@"Input Port %d", inputPort];
			[self doBreakpointWithTitle:s];
		}
	}
	
	if( outputPort > 0 )
	{
		if( [self.ioPorts shouldBreakOnPortWrite:outputPort] )
		{
			NSString *s = [NSString stringWithFormat:@"Output Port %d", outputPort];
			[self doBreakpointWithTitle:s];
		}
	}
}


- (void)writeOutputPort:(uint8_t)port data:(uint8_t)data
{
//	if( [self.ioPorts shouldBreakOnPortWrite:port] )
//	{
//		NSString *s = [NSString stringWithFormat:@"Output Port %d", port];
//		[self doBreakpointWithTitle:s];
//	}
	
	[self.ioPorts setOutputPort:port byte:data];
	
	if( self.useTerminalForIO )
	{
		if( port == 2 )
		{
			[self.terminalWindowController emitTerminalCharacter:data];
		}
	}
}



- (uint8_t)readInputPort:(uint8_t)port
{
//	if( [self.ioPorts shouldBreakOnPortRead:port] )
//	{
//		NSString *s = [NSString stringWithFormat:@"Input Port %d", port];
//		[self doBreakpointWithTitle:s];
//	}

	if( self.useTerminalForIO )
	{
		if( port == 3 )
		{
			if( [self.terminalWindowController hasCmdChar] )
			{
				return 0x81;
			}
			else
			{
				// If no characters, sleep a little bit. This way in a loop waiting for input we don't use a lot of host CPU cycles!
				// TODO: Make this configurable, so we can turn off the delay if so desired.
				[NSThread sleepForTimeInterval:0.050];
				return 0x80;
			}
		}
		
		if( port == 2 )
		{
			int c = (int) [self.terminalWindowController nextCommandChar];
			if( c >= 0 )
			{
				LogVerbose( @"Sending a character to Forth!" );
				return c;
			}
			else
			{
				LogWarn( @"Read char but none available" );
				return 0;
			}
		}
	}

	return [self.ioPorts readInputPort:port];
}



#pragma mark - Terminal Emulation

- (IBAction)openTerminal:(id)sender
{
	[self.terminalWindowController showWindow:self];
	self.useTerminalForIO = YES;
}



#pragma mark - Symbol Display

- (Symbol*)symbolForAddr:(unsigned int)addr
{
	for( Symbol *sym in self.loader.symbols )
	{
		if( addr >= sym.addr && addr <= sym.endAddr )
		{
			// Bingo
			return sym;
		}
	}
	
	return nil;
}


- (void)calcCurrentSymbol
{
	const CPU *cpu = CPU_getCPU();
	
	int pc = cpu->reg[cpu->P];
	
	if( self.currentSymbol )
	{
		if( pc >= self.currentSymbol.addr && pc <= self.currentSymbol.endAddr )
		{
			// No change
			return;
		}
	}
	
	self.currentSymbol = [self symbolForAddr:pc];
}



#pragma mark - State

- (void)updateState
{
	const CPU *cpu = CPU_getCPU();
	
	BOOL stepping = self.runmode != RunModeRunning;
	
	[self.registersViewController updateCPUState:cpu force:stepping];
	
	// We always update the current symbol, even if we don't always display it.
	[self calcCurrentSymbol];
	
	if( stepping || self.liveSymbolUpdates )
	{
		unsigned int pc = cpu->reg[cpu->P];
		
		SourceLine *line = [self.loader lineForAddr:pc];
		if( line )
		{
			LogVerbose( @":::: %4d : %@", line.lineNum, line.text );
			[self.sourceViewController hilightWithLine:line.lineNum-1];
		}

		if( self.currentSymbol )
		{
			int offset = pc - self.currentSymbol.addr;
			
			if( offset == 0 )
			{
				[self.symbolLabel setStringValue:[NSString stringWithFormat:@"%@", self.currentSymbol.name]];
			}
			else
			{
				[self.symbolLabel setStringValue:[NSString stringWithFormat:@"%@ + %u", self.currentSymbol.name, offset]];
			}
		}
		else
		{
			[self.symbolLabel setStringValue:@"------"];
		}
	}
}


- (void)startCycleTimer
{
	self.runmode = RunModeRunning;
	self.cycleTimer = [NSTimer timerWithTimeInterval:0.000001 target:self selector:@selector(performStep:) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:self.cycleTimer forMode:NSDefaultRunLoopMode];
}


- (void)setRunmode:(enum RunMode)runmode
{
	_runmode = runmode;
	
	switch (runmode)
	{
		case RunModePause:
			self.resetButton.enabled = YES;
			self.importButton.enabled = YES;
			self.stepButton.enabled = YES;
			self.runButton.title = @"Run";
			break;
			
		case RunModeRunning:
			self.resetButton.enabled = NO;
			self.importButton.enabled = NO;
			self.stepButton.enabled = NO;
			self.runButton.title = @"Pause";
			break;
			
		default:
			break;
	}
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
				[self doBreakpointWithTitle:@"Address 1"];
			}
		}
	}
	
	CPU_step();
	
	// This will update registers, calculate the curent symbol, etc.
	[self updateState];
	
	
#if 0
	// Hack
	static int nestLevel = 0;
	static NSString *lastSymbol;
	if( cpu->reg[cpu->P] == 0x123 )
	{
		// Nest
		nestLevel++;
	}
	else if( cpu->reg[cpu->P] == 0x509 )
	{
		// Un-Nest
		nestLevel--;
	}
	
	if( [lastSymbol isEqualToString:self.currentSymbol] == NO )
	{
		LogDebug( @"---%d--- %@", nestLevel, self.currentSymbol );
		lastSymbol = self.currentSymbol;
	}
#endif
	
	if( self.stepTrapSymbol )
	{
		if( self.stepTrapSymbol != self.currentSymbol )
		{
			// Ok, new symbol. Is it one we ignore?
			if( [self.stepIgnoreSymbols containsObject:self.currentSymbol] )
			{
				// It is
				self.stepTrapSymbol = self.currentSymbol;
			}
			else
			{
				// Break
				LogDebug( @"Stopped on symbol %@", self.currentSymbol.name );
				[self doBreakpointWithTitle:@"Next Symbol"];
			}
		}
	}
}


- (void)doBreakpointWithTitle:(NSString*)title
{
	[self.statusLabel setStringValue:[NSString stringWithFormat:@"Breakpoint: %@", title]];
	
	[self.cycleTimer invalidate];

	[self setRunmode:RunModePause];
}



#pragma mark - Actions

- (IBAction)stepAction:(id)sender
{
	LogDebug( @"Step" );
	self.runmode = RunModeStepping;
	CPU_step();
	
	[self updateState];
}


- (IBAction)stepNextSymbolAction:(id)sender
{
	self.stepTrapSymbol = self.currentSymbol;
	
	[self startCycleTimer];
}


- (IBAction)ignoreStepNextAction:(id)sender
{
	[self.stepIgnoreSymbols addObject:self.currentSymbol];

	LogDebug( @"Add ignored symbol %@", self.currentSymbol.name );

	self.stepTrapSymbol = self.currentSymbol;
	
	[self startCycleTimer];
}


- (IBAction)runAction:(id)sender
{
	if( self.runmode == RunModeRunning )
	{
		// Pause
		LogDebug( @"Pause" );
		
		[self.statusLabel setStringValue:@"Paused"];
		
		[self.cycleTimer invalidate];
		
		self.runmode = RunModePause;
		
		[self updateState];
	}
	else
	{
		LogDebug( @"Run" );
		
		self.stepTrapSymbol = nil;
		
		[self.statusLabel setStringValue:@"Running"];
		
		[self startCycleTimer];
	}
}


- (IBAction)pauseAction:(id)sender
{
	LogDebug( @"Pause" );
	
	[self.statusLabel setStringValue:@"Paused"];
	
	[self.cycleTimer invalidate];

	self.runmode = RunModePause;
	
	[self updateState];
}



- (IBAction)resetAction:(id)sender
{
	LogDebug( @"Reset" );
	
	[self.statusLabel setStringValue:@"Reset"];
	
	CPU_reset();
	
	self.runmode = RunModePause;
	
	[self updateState];
}


- (IBAction)importAction:(id)sender
{
	CPU_reset();
	[self openDocument:nil];
}



#pragma mark - Ask For File

- (IBAction)openDocument:(id)sender
{
	[self browseForListingWithCompletion:^(NSURL *url) {
		// Do this next runloop to let the file chooser go away!
		dispatch_async( dispatch_get_main_queue(), ^(void){
			if( url )
			{
				[self loadFile:[url path]];
			}
			else
			{
				LogDebug( @"No file chosen" );
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
	
	LogDebug( @"Listing loaded into memory, %lu bytes", self.loader.byteCount );
	
	[self.sourceViewController clear];
	
	for (SourceLine *line in self.loader.sourceLines) {
		[self.sourceViewController appendWithLine:line.text];
//		LogVerbose( @"%d : %@", line.lineNum, line.text );
	}
	
	self.runmode = RunModePause;
	
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

@end
