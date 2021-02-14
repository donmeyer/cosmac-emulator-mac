//
//  MainWindowController.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 6/12/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

import Cocoa
import os.log



/// If this is set to more than one, live updates suffer from an aliasing issue since we only update every n instructions.
let CPUStepsPerTimerTick = 1

let timerInterval = 0.000_008_988 * Double(CPUStepsPerTimerTick)
// Clock was 1.78Mhz
// 561.79ns per clock
// times 8 gives 4.494us per cpu cycle
// 8.988us per normal instruction cycle (2 CPU cycles)
//
// About 21us per timer cycle is about as fast as my Mac will go

enum RunMode {
	case Pause				// Not running
	case Stepping			// Single stepping
	case Running			// Running free
	case Breaking			// Breakpoint hit, should stop running
	case BreakpointResume	// Resuming `run` from a breakpoint.
}


let mainwin_log = OSLog(subsystem: "com.sgsw.1802emulator", category: "MainWindow")

/**
 Callback for the CPU port output operation.

 This is called from 'C'.

 - parameters:
   - userData: Optional opaque user data pointer passed back from the CPU emulation engine.
   - port: CPU port number
   - data: The data byte being sent out the port
*/
func ocb( userData : (Optional<UnsafeMutableRawPointer>), port : UInt8, data : UInt8 )
{
	os_log( "Output port %d  data 0x%02X  '%c'", log:mainwin_log, port, data, data )
	let mvc : MainWindowController = unsafeBitCast(userData, to: MainWindowController.self)
	mvc.writeOutputPort( port: Int(port), data:data )
}


/**
 Callback for the CPU port input operation.

 This is called from 'C'.

 - parameters:
   - userData: Optional opaque user data pointer passed back from the CPU emulation engine.
   - port: CPU port number

 - returns: The byte being read from the CPU port
 */
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


func accessError( userData : (Optional<UnsafeMutableRawPointer>), code : CPU_PageFaultCode, addr : UInt16, data : UInt8 )
{
	let mvc : MainWindowController = unsafeBitCast(userData, to: MainWindowController.self)
	mvc.handleAccessError(code: code, addr: addr, data: data)
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
	
	let ioPorts : AllIOPortsViewController = AllIOPortsViewController()
	
	
	
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
	@IBOutlet weak var stepNextSymbolButton: NSButton!
	
	@IBOutlet weak var ignoreSymbolButton: NSButton!
	
	
	var terminalWindowController : TerminalWindowController = TerminalWindowController.init(windowNibName:NSNib.Name(rawValue: "TerminalWindow"))
	
	var sourceViewController : SourceViewController = SourceViewController()
	
	var cycleTimer : Timer?
	
	var loader : HexLoader?
	
	var currentSymbol : Symbol?
	
	var stepTrapSymbol : Symbol?	// If set, step until symbol no longer matchs this one
	
	var stepIgnoreSymbols : NSMutableSet = []
	
	var runmode : RunMode = .Pause {
		didSet {
			os_log( "RunMode = %@", log : mainwin_log, type: .debug, String(describing: runmode ) )

			switch runmode
			{
			case .Pause,
				 .Breaking:
				self.resetButton.isEnabled = true
//				self.importButton.isEnabled = true
				self.stepButton.isEnabled = true
				self.stepNextSymbolButton.isEnabled = true
				self.ignoreSymbolButton.isEnabled = true
				self.runButton.title = "Run"
//				self.openItem.label = "Run"
//				self.openItem.image =
				
			case .Running:
				self.resetButton.isEnabled = false
//				self.importButton.isEnabled = false.
				self.stepButton.isEnabled = false
				self.stepNextSymbolButton.isEnabled = false
				self.ignoreSymbolButton.isEnabled = false
				self.runButton.title = "Pause"
				
			case .Stepping:
				break
				
			case .BreakpointResume:
				break
			}
		}
	}
	
	@IBOutlet weak var liveSymbolUpdatesCheckbox: NSButton!
	
	var liveSymbolUpdates : Bool = true
	
	@IBOutlet weak var liveSourceUpdatesCheckbox: NSButton!

	var liveSourceUpdates : Bool = true

	var useTerminalForIO : Bool = false
	
	
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		CPU_makeAllPagesRAM()
		
//		CPU_makeReadPage( 0 )
//		CPU_makeReadPage( 1 )
//		CPU_makeReadPage( 2 )
//		CPU_makeReadPage( 3 )
//		CPU_makeReadPage( 4 )
//		CPU_makeReadPage( 5 )
//		CPU_makeReadPage( 6 )
//		CPU_makeReadPage( 7 )
		
//		CPU_makeReadPage( 8 )
		
		// Callback that we get when the CPU writes to an IO port.
		CPU_setOutputCallback( ocb, Unmanaged.passUnretained(self).toOpaque() )
		
		// Callback that we get when the CPU reads from an IO port.
		CPU_setInputCallback( icb, Unmanaged.passUnretained(self).toOpaque() )
		
		// Callback we get during the CPU fetch cycle that tells us an IO instruction is what will excute next.
		// This early warning allows us to trigger a breakpoint before the IO instruction executes.
		CPU_setIOTrapCallback( iotrap, Unmanaged.passUnretained(self).toOpaque() )
		
		CPU_setPageFaultCallback( accessError, Unmanaged.passUnretained(self).toOpaque() )
		
		self.regView.addSubview(self.registersViewController.view)
		
		
		//
		// IO Ports
		//
		os_log( "IO port view frame: %@", log: mainwin_log, NSStringFromRect( self.portsView.frame ) )
		
//		self.ioPorts.view.autoresizingMask = .width
//		self.portsView.autoresizingMask = .width
//		self.portsView.autoresizesSubviews = true
		
		self.ioPorts.view.frame = CGRect.init(origin: CGPoint.zero, size: self.portsView.frame.size)
//		self.ioPorts.view.needsLayout = true
		os_log( "All IO ports view frame: %@", log: mainwin_log, NSStringFromRect( self.ioPorts.view.frame ) )
		self.portsView.addSubview(self.ioPorts.view)
//		self.ioPorts.setOutputPort(2, byte:22)
//		self.ioPorts.setOutputPort(7, byte:77)
		
		os_log( "All IO ports view frame: %@", log: mainwin_log, NSStringFromRect( self.ioPorts.view.frame ) )
		
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
		
		self.liveSymbolUpdatesCheckbox.state = self.liveSymbolUpdates ? .on : .off
		self.liveSourceUpdatesCheckbox.state = self.liveSourceUpdates ? .on : .off

		CPU_reset();
		//	[self loadFile:@"/Users/don/Code/Cosmac 1802/FIG/FIG_Forth.lst"];
		self.loadFile(path: "/Users/don/Code/Cosmac 1802/asm_src/slowq.lst")
		
		self.setDescriptionsForForth()
	}
	
	//what does the ignore symbol button do? need to clear on reset? or be shown?
	
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
	
	
	
	func handleAccessError( code : CPU_PageFaultCode, addr : uint16, data : uint8 )
	{
		var s : String
		s = "foo"
		switch code {
		case CPU_MemoryFaultWrite:
			s = "Write"
		case CPU_MemoryFaultRead:
			s = "read"
		case CPU_MemoryFaultReadNoPage:
			s = "read no page"
		case CPU_MemoryFaultWriteNoPage:
			s = "write no page"
		default:
			s = "???"
		}
		os_log( "Access error %@ at address 0x%04X", log : mainwin_log, type: .info, s, addr )
		self.doBreakpointWithTitle( "access error" )
	}
	
	
	// MARK: - IO Port Emulation
	
	/// This is called before the IO instruction is executed to give us a chance to break before the instruction executes.
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
	
	/// Called when an IO port is being written to.
	func writeOutputPort( port : Int, data : uint8 )
	{
//		if self.ioPorts.shouldBreakOnPortWrite(port)
//		{
//			self.doBreakpointWithTitle(String.init(format: "Output Port %d", port))
//		}
		
		if port == CPU_OUTPUT_PORT_Q
		{
			self.ioPorts.qLED = data != 0 ? true : false
			return
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
	
	
	/// Called when an IO port is being read from.
	func readInputPort( port : Int ) -> uint8
	{
//		if self.ioPorts.shouldBreakOnPortRead(port)
//		{
//			self.doBreakpointWithTitle(String.init(format: "Input Port %d", port))
//		}
//
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
	
	
	
	// MARK: - Terminal Emulation
	
	@IBAction func openTerminal(_ sender: Any) {
		self.terminalWindowController.showWindow(self)
		self.useTerminalForIO = true
	}
	
	
	
	// MARK: - Symbol Display
	
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
	
	
	
	// MARK: - State
	
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
			
			if let sym = self.currentSymbol
			{
				let pc = UInt16(CPU_getPC())
				let offset = pc - sym.addr;
				
				if offset == 0
				{
					self.symbolLabel.stringValue = sym.name
				}
				else
				{
					let symtext = String.init(format: "%@ + %u", sym.name, offset )
					self.symbolLabel.stringValue = symtext
					//					print( symtext)
				}
			}
			else
			{
				self.symbolLabel.stringValue = "------"
			}
		}

		// Multiple switches for updates, since the source code update is quite slow.
		if stepping || self.liveSourceUpdates
		{
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
		}
	}
	
	
	func startCycleTimer()
	{
		if self.runmode == .Breaking
		{
			self.runmode = .BreakpointResume
		}
		else
		{
			self.runmode = .Running
		}
		
		self.cycleTimer = Timer.init(timeInterval: timerInterval, target: self, selector: #selector(timerAction(timer:)), userInfo: nil, repeats: true)
		
		RunLoop.main.add(self.cycleTimer!, forMode: RunLoopMode.defaultRunLoopMode)
	}
	
	
	/// If the cycle timer is running, reset its time interval based on the state of live updates.
//	func rethinkCycleTimer()
//	{
		// If live updates, we do one step per runloop, so we cycle faster.
	
		// If not doing live updates
//	}
	
	
	func stopCycleTimer()
	{
		self.cycleTimer?.invalidate()
	}
	
	
	@objc func timerAction( timer: Timer )
	{
//		timerTicks += 1
		
		for _ in 1...CPUStepsPerTimerTick
		{
			// TODO: handle breakpoints properly!
			self.performRunStep()
			
			if self.runmode == .Breaking
			{
//				self.runmode = .Pause
				
				// This will update registers, calculate the curent symbol, etc.
				self.updateState()

				break
			}
		}
	}
	
	
	private func performRunStep()
	{
		if runmode == .BreakpointResume
		{
			self.runmode = .Running
		}
		else
		{
			CPU_checkIOTrap()
			
			if self.breakpoint1Checkbox.state == .on
			{
				// TODO: This is really slow, do this the right way!
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
			
			if let currentSymbol = self.currentSymbol
			{
				if let trapsym = self.stepTrapSymbol
				{
					// TODO: Slow also. Maybe we do something in the method that calculates the
					// current symbol such as set a flag when it changes?
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
		
		if runmode == .Running
		{
			CPU_step()
		}
		
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
		
		// This will update registers, calculate the current symbol, etc.
		self.updateState()
	}
	
	
	func doBreakpointWithTitle( _ title : String )
	{
		self.statusLabel.stringValue = String.init(format: "Breakpoint: %@", title)
		self.stopCycleTimer()
		self.runmode = .Breaking
	}
	
	
	
	// MARK: - Actions
	
	@IBAction func liveSymbolUpdateAction(_ sender: Any) {
		let button = sender as! NSButton
		self.liveSymbolUpdates = button.state == .on
	}
	
	@IBAction func liveSourceUpdateAction(_ sender: Any) {
		let button = sender as! NSButton
		self.liveSourceUpdates = button.state == .on
	}
	
	@IBAction func stepAction(_ sender: Any) {
		os_log( "Step", log: mainwin_log, type: .debug )
		
		self.runmode = .Stepping
		CPU_step()
		
		self.statusLabel.stringValue = "Stepping"
		
		self.updateState()
	}
	
	
	@IBAction func stepNextSymbolAction(_ sender: Any) {
		self.stepTrapSymbol = self.currentSymbol

		self.statusLabel.stringValue = "Running to next symbol"

		self.startCycleTimer()
	}
	
	
	@IBAction func ignoreStepNextAction(_ sender: Any) {
		if let currentSymbol = self.currentSymbol
		{
			self.stepIgnoreSymbols.add(currentSymbol)
	
			os_log( "Add ignored symbol %@", log: mainwin_log, type: .debug, currentSymbol.name )
		
			self.stepTrapSymbol = currentSymbol
		}

		self.statusLabel.stringValue = "Running to next symbol"

		self.startCycleTimer()
	}
	
	
	
	@IBAction func runAction(_ sender: Any) {
		if self.runmode == .Running
		{
			// Pause
			self.pauseAction(sender)
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
	
		self.stopCycleTimer()
	
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
	
	@IBAction func liveMenuAction(_ sender: Any) {
		self.liveSymbolUpdates = !self.liveSymbolUpdates
		self.liveSymbolUpdatesCheckbox.state = self.liveSymbolUpdates == true ? NSControl.StateValue.on : NSControl.StateValue.off
	}
	
	@IBAction func liveSourceMenuAction(_ sender: Any) {
		self.liveSourceUpdates = !self.liveSourceUpdates
		self.liveSourceUpdatesCheckbox.state = self.liveSourceUpdates == true ? NSControl.StateValue.on : NSControl.StateValue.off
	}
	
	override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		let action = menuItem.action
		
		if action == #selector(runAction(_:))
		{
			if self.runmode == .Running
			{
				return false
			}
		}
		else if action == #selector(stepAction(_:))
		{
			if self.runmode == .Running
			{
				return false
			}
		}
		else if action == #selector(pauseAction(_:))
		{
			if self.runmode != .Running
			{
				return false
			}
		}
		else if action == #selector(liveMenuAction(_:))
		{
			menuItem.state = self.liveSymbolUpdates == true ? NSControl.StateValue.on : NSControl.StateValue.off
		}
		else if action == #selector(liveSourceMenuAction(_:))
		{
			menuItem.state = self.liveSourceUpdates == true ? NSControl.StateValue.on : NSControl.StateValue.off
		}

		return true
	}
	
	
	// MARK: - Ask For File
	
	private func openDocument(_ sender: Any )
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
	
		CPU_reset()
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

