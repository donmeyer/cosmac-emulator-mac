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


@property (strong) NSTimer *cycleTimer;

@property (strong) HexLoader *loader;

@property (nonatomic, strong) Symbol *currentSymbol;

@property (strong) Symbol *stepTrapSymbol;	// If set, step until symbol no longer matchs this one

@property (strong) NSMutableSet *stepIgnoreSymbols;


@property (weak) IBOutlet NSTextField *cmdLineField;
@property (strong) IBOutlet NSTextView *terminalField;


@property (strong) NSMutableString *terminalString;

@property (strong) NSMutableString *cmdString;

@property (nonatomic, assign) enum RunMode runmode;


@property (nonatomic, assign) BOOL liveSymbolUpdates;

@end




@implementation MainWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	CPU_makeAllPagesRAM();
	
	CPU_setOutputCallback( ocb, (__bridge void *)(self) );
	
	CPU_setInputCallback( icb, (__bridge void *)(self) );
		
	self.registersViewController = [[RegistersViewController alloc] initWithNibName:@"RegistersView" bundle:nil];
//	self.registersViewController.view = self.regView;

	[self.regView addSubview:[self.registersViewController view]];


	CPU_reset();
//	[self loadFile:@"/Users/don/Code/Cosmac 1802/FIG/FIG_Forth.lst"];
	[self loadFile:@"/Users/don/Code/Cosmac 1802/asm_src/slowq.lst"];
	
	[self.cmdString setString:@".\r"];
}


- (void)awakeFromNib
{
	[self.statusLabel setStringValue:@""];
	
	self.stepIgnoreSymbols = [[NSMutableSet alloc] init];

	self.terminalString = [[NSMutableString alloc] init];

	self.cmdString = [[NSMutableString alloc] init];
	
	NSFont *font = [NSFont fontWithName:@"Consolas" size:11.0];
	self.terminalField.font = font;
}



#pragma mark - IO Port Emulation


static void ocb( void *userData, uint8_t port, uint8_t data )
{
	LogVerbose( @"Output port %d  data 0x%02X  '%c'", port, data, data );
	
	MainWindowController *mvc = (__bridge MainWindowController*)userData;
	
	if( port == 2 )
	{
		[mvc emitTerminalCharacter:data];
	}
	
	if( mvc.outputPort2Checkbox.state == NSOnState )
	{
		[mvc doBreakpointWithTitle:@"Output Port 2"];
	}
}


static uint8_t icb( void *userData, uint8_t port )
{
//	LogDebug( @"Input port %d", port );
	
	MainWindowController *mvc = (__bridge MainWindowController*)userData;
	
	if( port == 3 )
	{
		if( [mvc hasCmdChar] )
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
		int c = [mvc nextCommandChar];
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
	
	return 0;
}


#pragma mark - Terminal Emulation

- (void)emitTerminalText:(NSString*)text
{
	[self.terminalString appendString:text];
	[self.terminalField setString:self.terminalString];
	[self.terminalField scrollToEndOfDocument:nil];
}


- (void)emitTerminalCharacter:(char)c
{
	[self.terminalString appendFormat:@"%c", c];
	[self.terminalField setString:self.terminalString];
	
//	NSRange range;
	[self.terminalField scrollToEndOfDocument:nil];
}


- (BOOL)hasCmdChar
{
	return self.cmdString.length > 0 ? YES : NO;
}


/// returns -1 if none
- (int)nextCommandChar
{
	if( self.cmdString.length )
	{
		int c = [self.cmdString characterAtIndex:0];

		NSRange range;
		range.length = 1;
		range.location = 0;
		[self.cmdString deleteCharactersInRange:range];
		
		return c;
	}
	
	return -1;
}


- (IBAction)cmdEnteredAction:(id)sender
{
	NSTextField *field = (NSTextField*)sender;
	NSString *buf = [NSString stringWithFormat:@"%@\r", field.stringValue];
	[self.cmdString setString:buf];
	
	[field setStringValue:@""];
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
			LogDebug( @":::: %4d : %@", line.lineNum, line.text );
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
	[self openDocument];
}



#pragma mark - Ask For File

- (void)openDocument
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
