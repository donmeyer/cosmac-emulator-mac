//
//  MainWindowController.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 6/12/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

import Cocoa

// #import "MainWindowController.h"
// #import "CPU Emulation.h"
// #import "HexLoader.h"
// #import "ScratchpadRegistersView.h"
// #import "RegistersViewController.h"
// #import "_802_Emulator-Swift.h"
//
// #import "Logging.h"

//static const DDLogLevel ddLogLevel = DDLogLevelDebug;


enum RunMode {
	case Pause
	case Stepping
	case Running
}


func ocb( userData : (Optional<UnsafeMutableRawPointer>), port : UInt8, data : UInt8 )
{
	//		LogVerbose( @"Output port %d  data 0x%02X  '%c'", port, data, data );
	
	let mvc : MainWindowController = unsafeBitCast(userData, to: MainWindowController.self)
	mvc.writeOutputPort( port: port, data:data )
}


class MainWindowController : NSWindowController, NSWindowDelegate {
	
	//
	// Status
	//
//	@property (strong) IBOutlet RegistersViewController *registersViewController;
//	@property (weak) IBOutlet NSView *regView;
	@IBOutlet weak var regView: NSView!
	
	//
	//
	//
	@IBOutlet weak var sourceView: NSView!
	@IBOutlet weak var portsView: NSView!
	
	//
	// Timing
	//
	@IBOutlet weak var totalCyclesField: NSTextField!
	
//	@property (weak) IBOutlet NSTextField *breakpoint1Field;
//	@property (weak) IBOutlet NSButton *breakpoint1Checkbox;
//
//	@property (weak) IBOutlet NSTextField *breakpoint2Field;
//	@property (weak) IBOutlet NSButton *breakpoint2Checkbox;
//
	
	@IBOutlet weak var symbolLabel: NSTextField!
	@IBOutlet weak var statusLabel: NSTextField!
	
	
	//
	// Buttons
	//
	@IBOutlet weak var stepButton: NSButton!
	@IBOutlet weak var resetButton: NSButton!
	@IBOutlet weak var runButton: NSButton!
	@IBOutlet weak var importButton: NSButton!
	
	
	var registersViewController : RegistersViewController = RegistersViewController.init(nibName: NSNib.Name(rawValue: "RegistersView"), bundle: nil)
	
	var ioPorts : AllIOPortsViewController = AllIOPortsViewController()
	
	var terminalWindowController : TerminalWindowController = TerminalWindowController.init(windowNibName:NSNib.Name(rawValue: "TerminalWindow"))
	
	var sourceViewController : SourceViewController = SourceViewController()
	
	var cycleTimer : Timer?
	
	var loader : HexLoader?
	
	var currentSymbol : Symbol?
	
	var stepTrapSymbol : Symbol?	// If set, step until symbol no longer matchs this one
	
	var stepIgnoreSymbols : NSMutableSet = []
	
	var runmode : RunMode = .Pause {
		didSet {
			switch runmode
			{
			case .Pause:
				self.resetButton.isEnabled = true
				self.importButton.isEnabled = true
				self.stepButton.isEnabled = true
				self.runButton.title = "Run"
				
			case .Running:
				self.resetButton.isEnabled = false
				self.importButton.isEnabled = false
				self.stepButton.isEnabled = false
				self.runButton.title = "Pause"
				
			case .Stepping:
				break
			}
		}
	}
	
	
	var liveSymbolUpdates : Bool = true
	
	var useTerminalForIO : Bool = false
	
	
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		CPU_makeAllPagesRAM();
		
		
		// Callback that we get when the CPU writes to an IO port.
		CPU_setOutputCallback( ocb, Unmanaged.passUnretained(self).toOpaque() )
		
		// Callback that we get when the CPU reades from an IO port.
//		CPU_setInputCallback( icb, (__bridge void *)(self) );
		
		// Callback we get during the CPU fetch cycle that tells us an IO instruction is what will excute next.
		// This early warning allows us to trigger a breakpoint before the IO instruction executes.
//		CPU_setIOTrapCallback( iotrap, (__bridge void *)(self) );
		
		self.regView.addSubview(self.registersViewController.view)
		
		
		//
		// IO Ports
		//
//		LogDebug( "IO port view frame: %@", NSStringFromRect( pv.view.frame ) );
		
		//	NSSize pre = pv.preferredContentSize;
		//	[pv.view setFrameSize:pre];
		
		self.portsView.addSubview(self.ioPorts.view)
		self.ioPorts.setOutputPort(2, byte:22)
		self.ioPorts.setOutputPort(7, byte:77)
		
		//
		// Sourcecode View
		//
		let svv = self.sourceViewController.view;
		self.sourceView.autoresizesSubviews = true
		
		var r : NSRect = self.sourceViewController.view.frame
//		LogDebug( @"Source view frame: %@", NSStringFromRect( r ) );
		r.size.width = self.sourceView.bounds.size.width
		r.size.height = self.sourceView.bounds.size.height
		self.sourceViewController.view.frame = r;
		
		self.sourceView.addSubview(svv)
		
		
		self.terminalWindowController.window?.delegate = self
		
		
		CPU_reset();
		//	[self loadFile:@"/Users/don/Code/Cosmac 1802/FIG/FIG_Forth.lst"];
		self.loadFile(path: "/Users/don/Code/Cosmac 1802/asm_src/slowq.lst")
		
		self.setDescriptionsForForth()
	}
	
	
	
	override func awakeFromNib() {
		self.statusLabel.stringValue = ""
		
//		self.stepIgnoreSymbols = [[NSMutableSet alloc] init];
	}
	
	
	func windowWillClose(_ notification: Notification)
	{
		if notification.object as! NSWindow == self.terminalWindowController.window
		{
//			LogDebug( "Terminal close" );
			self.useTerminalForIO = false
		}
	}
	
	
	
	func setDescriptionsForForth()
	{
		self.registersViewController.setDescription("DMA", forReg:0x00)
		
		
		self.registersViewController.setDescription("Interupt PC", forReg:0x01)
		
		self.registersViewController.setDescription("RP", forReg:0x02)
		self.registersViewController.setDescription("Primitive PC", forReg:0x03)
		
		self.registersViewController.setDescription("Scratch Accum", forReg:0x07)
		self.registersViewController.setDescription("Scratch Accum", forReg:0x08)
		
		self.registersViewController.setDescription("SP", forReg:0x09)
		
		self.registersViewController.setDescription("IP", forReg:0x0A)
		self.registersViewController.setDescription("W (CFA)", forReg:0x0B)
		
		self.registersViewController.setDescription("PC for NEXT", forReg:0x0C)
		
		self.registersViewController.setDescription("UP", forReg:0x0D)
		
		self.registersViewController.setDescription("Interrupt SP", forReg:0x0E)
	}
	
	
	
//	#pragma mark - IO Port Emulation
	
	
//
//
//	static uint8_t icb( void *userData, uint8_t port )
//{
//	//	LogDebug( @"Input port %d", port );
//
//	MainWindowController *mvc = (__bridge MainWindowController*)userData;
//	return [mvc readInputPort:port];
//	}
//
//
//	static void iotrap( void *userData, int inputPort, int outputPort )
//{
//	MainWindowController *mvc = (__bridge MainWindowController*)userData;
//	[mvc handleIOTrap:inputPort outputPort:outputPort];
//	}
//
//
//	- (void)handleIOTrap:(int)inputPort outputPort:(int)outputPort
//	{
//	if( inputPort > 0 )
//	{
//	if( [self.ioPorts shouldBreakOnPortRead:inputPort] )
//	{
//	NSString *s = [NSString stringWithFormat:@"Input Port %d", inputPort];
//	[self doBreakpointWithTitle:s];
//	}
//	}
//
//	if( outputPort > 0 )
//	{
//	if( [self.ioPorts shouldBreakOnPortWrite:outputPort] )
//	{
//	NSString *s = [NSString stringWithFormat:@"Output Port %d", outputPort];
//	[self doBreakpointWithTitle:s];
//	}
//	}
//	}
	
	
	func writeOutputPort( port : uint8, data : uint8 )
	{
	//	if( [self.ioPorts shouldBreakOnPortWrite:port] )
	//	{
	//		NSString *s = [NSString stringWithFormat:@"Output Port %d", port];
	//		[self doBreakpointWithTitle:s];
	//	}
	
		self.ioPorts.setOutputPort( Int(port), byte:data )
	
		if self.useTerminalForIO == true
		{
			if port == 2
			{
				self.terminalWindowController.emitTerminalCharacter(data)
			}
		}
	}
	
	
	func readInputPort( port : uint8 ) -> uint8
	{
	//	if( [self.ioPorts shouldBreakOnPortRead:port] )
	//	{
	//		NSString *s = [NSString stringWithFormat:@"Input Port %d", port];
	//		[self doBreakpointWithTitle:s];
	//	}
	
		if self.useTerminalForIO == true
		{
			if port == 3
			{
				if self.terminalWindowController.hasCmdChar()
				{
					return 0x81
				}
				else
				{
					// If no characters, sleep a little bit. This way in a loop waiting for input we don't use a lot of host CPU cycles!
					// TODO: Make this configurable, so we can turn off the delay if so desired.
					Thread.sleep(forTimeInterval: 0.050)
					return 0x80;
				}
			}
	
			if port == 2
			{
				let c = self.terminalWindowController.nextCommandChar()
				if c >= 0
				{
//					LogVerbose( @"Sending a character to Forth!" );
					return uint8(c)
				}
				else
				{
//					LogWarn( @"Read char but none available" );
					return 0
				}
			}
		}
	
		return self.ioPorts.readInputPort(Int(port))
	}
	
	
	
//	#pragma mark - Terminal Emulation
	
	@IBAction func openTerminal(_ sender: Any) {
		self.terminalWindowController.showWindow(self)
		self.useTerminalForIO = true
	}
	
	
	
//	#pragma mark - Symbol Display
	
	func symbolForAddr( _ addr : uint16 ) -> Symbol?
	{
		if let loader = self.loader
		{
			if let symbols = loader.symbols
			{
				for sym in symbols
				{
					let s = sym as! Symbol
					if addr >= s.addr && addr <= s.endAddr
					{
						// Bingo
						return s
					}
				}
			}
		}
	
		return nil
	}
	
	
	func calcCurrentSymbol()
	{
		let cpu = CPU_getCPU()
		
		let x = 1
//		let pc : uint16 = (cpu?.pointee.reg[x])!
//
//		if let sym = self.currentSymbol
//		{
//			if pc >= sym.addr && pc <= sym.endAddr
//			{
//				// No change
//				return;
//			}
//
//			self.currentSymbol = self.symbolForAddr(pc)
//		}
	}
	
	
	
//	#pragma mark - State
	
	func updateState()
	{
		let cpu = CPU_getCPU()
	
		let stepping = self.runmode != .Running
	
		// We always update the current symbol, even if we don't always display it.
		self.calcCurrentSymbol()
	
		if stepping || self.liveSymbolUpdates
		{
			self.registersViewController.updateCPUState(cpu)
	
			let cycles = CPU_getCycleCount()
			self.totalCyclesField.stringValue = String.init(format: "%lu", cycles)
	
//			let pc = cpu->reg[cpu->P];
			let pc = 0
			
			if let loader = self.loader
			{
				let line : SourceLine? = loader.line( forAddr: UInt32(pc) )
				if let line = line
				{
//					LogVerbose( @":::: %4d : %@", line.lineNum, line.text );
					let ln = line.lineNum - 1
					self.sourceViewController.hilight(line: Int(ln) )
				}
			}
	
			if let sym = self.currentSymbol
			{
				let offset = pc - sym.addr;
	
				if offset == 0
				{
					self.symbolLabel.stringValue = sym.name
				}
				else
				{
					self.symbolLabel.stringValue = String.init(format: "%@ + %u", sym.name, offset )
				}
			}
			else
			{
				self.symbolLabel.stringValue = "------"
			}
		}
	}
	
	
	func startCycleTimer()
	{
		self.runmode = .Running
		self.cycleTimer = Timer.init(timeInterval: 0.000001, target: self, selector: #selector(performStep), userInfo: nil, repeats: true)
		
		
		RunLoop.main.add(self.cycleTimer!, forMode: RunLoopMode.defaultRunLoopMode)
	}
	
	
	func setRunmode( _ runmode : RunMode)
	{
		self.runmode = runmode
	
		switch runmode
		{
			case .Pause:
				self.resetButton.isEnabled = true
				self.importButton.isEnabled = true
				self.stepButton.isEnabled = true
				self.runButton.title = "Run"
			
		case .Running:
			self.resetButton.isEnabled = false
			self.importButton.isEnabled = false
			self.stepButton.isEnabled = false
			self.runButton.title = "Pause"
			
		case .Stepping:
			break
		}
	}
	
	
	@objc func performStep( timer: Timer )
	{
		let cpu = CPU_getCPU()
	
//		if self.breakpoint1Checkbox.state == NSOnState
//		{
//			NSString *s = self.breakpoint1Field.stringValue;
//			unsigned hexAddr;
//			if( [[NSScanner scannerWithString:s] scanHexInt:&hexAddr] == YES )
//			{
//				if( hexAddr == cpu->reg[cpu->P] )
//				{
//					[self doBreakpointWithTitle:@"Address 1"];
//				}
//			}
//		}
		
		CPU_step()
	
		// This will update registers, calculate the curent symbol, etc.
		self.updateState()
	
	
		#if false
			// Hack
//			static int nestLevel = 0;
//			static NSString *lastSymbol;
//			if( cpu->reg[cpu->P] == 0x123 )
//			{
//				// Nest
//				nestLevel++;
//			}
//			else if( cpu->reg[cpu->P] == 0x509 )
//			{
//				// Un-Nest
//				nestLevel--;
//			}
//
//			if( [lastSymbol isEqualToString:self.currentSymbol] == NO )
//			{
//				LogDebug( @"---%d--- %@", nestLevel, self.currentSymbol );
//				lastSymbol = self.currentSymbol;
//			}
		#endif
	
		if let trapsym = self.stepTrapSymbol
		{
			if trapsym != self.currentSymbol
			{
				// Ok, new symbol. Is it one we ignore?
				if self.stepIgnoreSymbols.contains(self.currentSymbol)
				{
					// It is
					self.stepTrapSymbol = self.currentSymbol
				}
				else
				{
					// Break
//					LogDebug( @"Stopped on symbol %@", self.currentSymbol.name );
					self.doBreakpointWithTitle("Next Symbol")
				}
			}
		}
	}
	
	
	func doBreakpointWithTitle( _ title : String )
	{
		self.statusLabel.stringValue = String.init(format: "Breakpoint: %@", title)
	
		self.cycleTimer?.invalidate()
	
		self.setRunmode( .Pause )
	}
	
	
	
//	#pragma mark - Actions
	
	@IBAction func stepAction(_ sender: Any) {
//		LogDebug( @"Step" );
		self.runmode = .Stepping
		CPU_step()
	
		self.updateState()
	}
	
	
	@IBAction func stepNextSymbolAction(_ sender: Any) {
		self.stepTrapSymbol = self.currentSymbol
	
		self.startCycleTimer()
	}
	
	
	@IBAction func ignoreStepNextAction(_ sender: Any) {
		self.stepIgnoreSymbols.add(self.currentSymbol)
	
//		LogDebug( @"Add ignored symbol %@", self.currentSymbol.name );
		
		self.stepTrapSymbol = self.currentSymbol
	
		self.startCycleTimer()
	}
	
	
	
	@IBAction func runAction(_ sender: Any) {
		if self.runmode == .Running
		{
			// Pause
//			LogDebug( @"Pause" );
			
			self.statusLabel.stringValue = "Paused"
	
			self.cycleTimer?.invalidate()
	
			self.runmode = .Pause
	
			self.updateState()
		}
		else
		{
//			LogDebug( @"Run" );
			
			self.stepTrapSymbol = nil;
	
			self.statusLabel.stringValue = "Running"
	
			self.startCycleTimer()
		}
	}
	
	
	@IBAction func pauseAction(_ sender: Any) {
//		LogDebug( @"Pause" );
		
		self.statusLabel.stringValue = "Paused"
	
		self.cycleTimer?.invalidate()
	
		self.runmode = .Pause
	
		self.updateState()
	}
	
	
	@IBAction func resetAction(_ sender: Any) {
//		LogDebug( @"Reset" );
		
		self.statusLabel.stringValue = "Reset"
	
		CPU_reset()
	
		self.runmode = .Pause
	
		self.updateState()
	}
	
	
	@IBAction func importAction(_ sender: Any) {
		CPU_reset()
		self.openDocument(self)
	}
	
	
	
//	#pragma mark - Ask For File
	
	@IBAction func openDocument(_ sender: Any )
	{
		self.browseForListingWithCompletion { (url: URL?) in
			// Do this next runloop to let the file chooser go away!
			DispatchQueue.main.async {
				if let url = url
				{
					self.loadFile(path: url.path)
				}
				else
				{
//					LogDebug( @"No file chosen" );
				}
			}
		}
	}
	
	
	func loadFile( path: String )
	{
	//	HexLoader *loader = [[HexLoader alloc] initWithListingPath:@"/Users/don/Code/Cosmac_1802/toggleQ.lst"];
	//	HexLoader *loader = [[HexLoader alloc] initWithListingPath:@"/Users/don/Code/Cosmac_1802/FIG-Forth/FIG_Forth.lst"];
	//				HexLoader *loader = [[HexLoader alloc] initWithListingPath:@"/Users/don/Dropbox/Documents/RCA 1802/FIG_2/FIG311.LST"];
	
		self.loader = HexLoader.init(listingPath: path)
		
		self.loader?.load({ (addr: Int, byte : UInt8) in
			CPU_writeByteToMemory( byte, UInt16(addr) )
		})
		
//		LogDebug( @"Listing loaded into memory, %lu bytes", self.loader.byteCount );
		
		self.sourceViewController.clear()
	
		for line in (self.loader?.sourceLines)!  {
			let l = line as! SourceLine
			self.sourceViewController.append(line: l.text)
	//		LogVerbose( @"%d : %@", line.lineNum, line.text );
		}
	
		self.runmode = .Pause
	
		self.updateState()
	
		self.registersViewController.reset()
	}
	
	
	/**
	* Ask the user for a file which is then read into a string.
	* The string is passed to the completion block.
	*/
	func browseForListingWithCompletion( completion : @escaping (URL?) -> Void )
	{
		let allowedFileTypes = ["lst"]
		let panel = NSOpenPanel.init() //   openPanel];
	
		panel.allowsMultipleSelection = false
		panel.canChooseFiles = true
		panel.allowedFileTypes = allowedFileTypes
	
		panel.beginSheetModal(for: self.window!, completionHandler: { (modalResponse) in
			print( modalResponse )
			if modalResponse != NSApplication.ModalResponse.alertFirstButtonReturn
			{
				return
			}
	
			let url = panel.urls.first
	
			// If a completion block (and there really shhould be, else what's the point?) call it with the filename.
			completion( url )
		})
	}
	
}

