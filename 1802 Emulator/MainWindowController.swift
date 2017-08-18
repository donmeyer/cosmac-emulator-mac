//
//  MainWindowController.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 6/12/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

import Cocoa
import os.log



enum RunMode {
	case Pause
	case Stepping
	case Running
}


let mainwin_log = OSLog(subsystem: "com.sgsw.1802emulator", category: "MainWindow")



func ocb( userData : (Optional<UnsafeMutableRawPointer>), port : UInt8, data : UInt8 )
{
	os_log( "Output port %d  data 0x%02X  '%c'", log:mainwin_log, port, data, data )
	let mvc : MainWindowController = unsafeBitCast(userData, to: MainWindowController.self)
	mvc.writeOutputPort( port: Int(port), data:data )
}


func icb( userData : (Optional<UnsafeMutableRawPointer>), port : UInt8 ) -> UInt8
{
	os_log( "Input port %d", port )
	let mvc : MainWindowController = unsafeBitCast(userData, to: MainWindowController.self)
	return mvc.readInputPort( port: Int(port) )
}


func iotrap( userData : (Optional<UnsafeMutableRawPointer>), inputPort : CInt, outputPort : CInt )
{
	let mvc : MainWindowController = unsafeBitCast(userData, to: MainWindowController.self)
	mvc.handleIOTrap( inputPort:Int(inputPort), outputPort:Int(outputPort) )
}


class MainWindowController : NSWindowController, NSWindowDelegate {
	
	//
	// Status
	//
	@IBOutlet weak var regView: NSView!
	
	//
	//
	//
	@IBOutlet weak var sourceView: NSView!
	@IBOutlet weak var portsView: NSView!
	var registersViewController : RegistersViewController = RegistersViewController.init(nibName: NSNib.Name(rawValue: "RegistersView"), bundle: nil)
	
	var ioPorts : AllIOPortsViewController = AllIOPortsViewController()
	
	
	//
	// Timing
	//
	@IBOutlet weak var totalCyclesField: NSTextField!
	
	
	@IBOutlet weak var breakpoint1Field: NSTextField!
	@IBOutlet weak var breakpoint1Checkbox: NSButton!
	
	@IBOutlet weak var breakpoint2Field: NSTextField!
	@IBOutlet weak var breakpoint2Checkbox: NSButton!
	
	
	@IBOutlet weak var symbolLabel: NSTextField!
	@IBOutlet weak var statusLabel: NSTextField!
	
	
	//
	// Buttons
	//
	@IBOutlet weak var stepButton: NSButton!
	@IBOutlet weak var resetButton: NSButton!
	@IBOutlet weak var runButton: NSButton!
	@IBOutlet weak var importButton: NSButton!
	
	
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
		CPU_setInputCallback( icb, Unmanaged.passUnretained(self).toOpaque() )
		
		// Callback we get during the CPU fetch cycle that tells us an IO instruction is what will excute next.
		// This early warning allows us to trigger a breakpoint before the IO instruction executes.
		CPU_setIOTrapCallback( iotrap, Unmanaged.passUnretained(self).toOpaque() )
		
		self.regView.addSubview(self.registersViewController.view)
		
		
		//
		// IO Ports
		//
		os_log( "IO port view frame: %@", log: mainwin_log, NSStringFromRect( self.regView.frame ) )
		
		self.portsView.addSubview(self.ioPorts.view)
		self.ioPorts.setOutputPort(2, byte:22)
		self.ioPorts.setOutputPort(7, byte:77)
		
		//
		// Sourcecode View
		//
		let svv = self.sourceViewController.view;
		self.sourceView.autoresizesSubviews = true
		
		var r : NSRect = self.sourceViewController.view.frame
		os_log( "Source view frame: %@", log: mainwin_log, NSStringFromRect( self.sourceViewController.view.frame ) )
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
	}
	
	
	func windowWillClose(_ notification: Notification)
	{
		if notification.object as? NSWindow == self.terminalWindowController.window
		{
			os_log( "Terminal close", log: mainwin_log, type: .debug )
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
	
	func handleIOTrap( inputPort : Int, outputPort: Int )
	{
		if inputPort > 0
		{
			if self.ioPorts.shouldBreakOnPortRead(inputPort)
			{
				let s = "Input Port \(inputPort)"
				self.doBreakpointWithTitle( s )
			}
		}
		
		if outputPort > 0
		{
			if self.ioPorts.shouldBreakOnPortWrite(outputPort)
			{
				let s = "Output Port \(outputPort)"
				self.doBreakpointWithTitle( s )
			}
		}
	}
	
	
	func writeOutputPort( port : Int, data : uint8 )
	{
		if self.ioPorts.shouldBreakOnPortWrite(port)
		{
			self.doBreakpointWithTitle(String.init(format: "Output Port %d", port))
		}
		
		self.ioPorts.setOutputPort( Int(port), byte:data )
	
		if self.useTerminalForIO == true
		{
			if port == 2
			{
				self.terminalWindowController.emitTerminalCharacter(data)
			}
		}
	}
	
	
	func readInputPort( port : Int ) -> uint8
	{
		if self.ioPorts.shouldBreakOnPortRead(port)
		{
			self.doBreakpointWithTitle(String.init(format: "Input Port %d", port))
		}
		
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
		let pc = CPU_getPC()
		if let sym = self.currentSymbol
		{
			if pc >= sym.addr && pc <= sym.endAddr
			{
				// No change
				return;
			}
		}
		self.currentSymbol = self.symbolForAddr(pc)
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
	
			let pc = UInt16(CPU_getPC())
			
			if let loader = self.loader
			{
				let line : SourceLine? = loader.line( forAddr: pc )
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
		if self.breakpoint1Checkbox.state == NSControl.StateValue.onState
		{
			let s = self.breakpoint1Field.stringValue
			var hexAddr : UInt32 = 0
			if Scanner.init(string: s).scanHexInt32(&hexAddr) == true
			{
				if hexAddr == CPU_getPC()
				{
					self.doBreakpointWithTitle("Address 1")
				}
			}
		}
		
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
		
		if let currentSymbol = self.currentSymbol
		{
			if let trapsym = self.stepTrapSymbol
			{
				if trapsym != currentSymbol
				{
					// Ok, new symbol. Is it one we ignore?
					if self.stepIgnoreSymbols.contains(currentSymbol)
					{
						// It is
						stepTrapSymbol = currentSymbol
					}
					else
					{
						// Break
						os_log( "Stopped on symbol %@", log: mainwin_log, type: .debug, currentSymbol.name )
						
						self.doBreakpointWithTitle("Next Symbol")
					}
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
		os_log( "Step", log: mainwin_log, type: .debug )
		
		self.runmode = .Stepping
		CPU_step()
	
		self.updateState()
	}
	
	
	@IBAction func stepNextSymbolAction(_ sender: Any) {
		self.stepTrapSymbol = self.currentSymbol
	
		self.startCycleTimer()
	}
	
	
	@IBAction func ignoreStepNextAction(_ sender: Any) {
		if let currentSymbol = self.currentSymbol
		{
			self.stepIgnoreSymbols.add(currentSymbol)
	
			os_log( "Add ignored symbol %@", log: mainwin_log, type: .debug, currentSymbol.name )
		
			self.stepTrapSymbol = currentSymbol
		}
		
		self.startCycleTimer()
	}
	
	
	
	@IBAction func runAction(_ sender: Any) {
		if self.runmode == .Running
		{
			// Pause
			os_log( "Pause", log: mainwin_log, type: .debug )
			
			self.statusLabel.stringValue = "Paused"
	
			self.cycleTimer?.invalidate()
	
			self.runmode = .Pause
	
			self.updateState()
		}
		else
		{
			os_log( "Run", log: mainwin_log, type: .debug )
			
			self.stepTrapSymbol = nil;
	
			self.statusLabel.stringValue = "Running"
	
			self.startCycleTimer()
		}
	}
	
	
	@IBAction func pauseAction(_ sender: Any) {
		os_log( "Pause", log: mainwin_log, type: .debug )
		
		self.statusLabel.stringValue = "Paused"
	
		self.cycleTimer?.invalidate()
	
		self.runmode = .Pause
	
		self.updateState()
	}
	
	
	@IBAction func resetAction(_ sender: Any) {
		os_log( "Reset", log: mainwin_log, type: .debug )
		
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
					os_log( "No file chosen", log: mainwin_log, type: .debug )
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
		
		if let loader = self.loader
		{
			loader.load({ (addr: Int, byte : UInt8) in
				CPU_writeByteToMemory( byte, UInt16(addr) )
			})
		
			os_log( "Listing loaded into memory, %lu bytes", log: mainwin_log, type: .info, loader.byteCount )
		
			self.sourceViewController.clear()
	
			for line in (self.loader?.sourceLines)!  {
				let l = line as! SourceLine
				self.sourceViewController.append(line: l.text)
	//			os_log( "%d : %@", log: mainwin_log, type: .debug, l.lineNum, l.text )
			}
		}
		else
		{
			// TODO: Should be a dialog alert
			os_log( "Failed to load file %@", log: mainwin_log, type: .error, path )
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
			
			if modalResponse == NSApplication.ModalResponse.OK
			{
				let url = panel.urls.first
				
				// If a completion block (and there really shhould be, else what's the point?) call it with the filename.
				completion( url )
			}
		})
	}
	
}

