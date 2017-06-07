//
//  SourceViewController.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 6/1/17.
//  Copyright © 2017 Donald Meyer. All rights reserved.
//

import Cocoa



fileprivate class SourceLine : NSObject
{
	let start : Int
	let length : Int
	let range : NSRange
	
	init( start: Int, length : Int)
	{
		self.range = NSMakeRange(start, length)
		
		self.start = start
		self.length = length
	}
}




class SourceViewController: NSViewController {

	private var textView: NSTextView!
	private var markerView: MarkerView!
	
	private var textScrollView: SynchroScrollView!
	private var markerScrollView: SynchroScrollView!
	
	fileprivate var lines = [SourceLine]()
	
	private var curHilight : Int? = nil		// Index of the curently hilighted line, if any
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		/* determine the size for the NSTextView */
		var vFrame : NSRect = self.view.frame
		
		vFrame = vFrame.insetBy(dx: 30, dy: 30)
		print( vFrame )
		
		
		let cFrame = NSMakeRect( vFrame.origin.x + 20, vFrame.origin.y, vFrame.size.width - 20, vFrame.size.height)
		print( cFrame )
		self._textSetup(cFrame: cFrame )
		
		
		let mFrame = NSMakeRect( vFrame.origin.x, vFrame.origin.y, 15, vFrame.size.height)
		print( mFrame )
		self._markersetup(cFrame: mFrame)
		
		
//		textScrollView?.setSynchronizedScrollView(scrollview: markerScrollView!)		// Frak, doing both causes infinite loop
		markerScrollView?.setSynchronizedScrollView(scrollview: textScrollView!)

	}
	
	
	func _textSetup( cFrame : NSRect )
	{
		//
		// Scroll view
		//
		let sv : SynchroScrollView = SynchroScrollView.init(frame: cFrame)
		let contentSize : NSSize = sv.contentSize
//		sv.borderType = .noBorder
		sv.hasVerticalScroller = true
//		sv.hasHorizontalScroller = false
		sv.autoresizingMask = NSAutoresizingMaskOptions(arrayLiteral: .viewWidthSizable, .viewHeightSizable)

//		sv.backgroundColor = NSColor.init(red: 0.8, green: 0.6, blue: 0.5, alpha: 1.0)
		
		
		//
		// Text view
		//
		let tv = NSTextView(frame: NSMakeRect(0, 0, contentSize.width, contentSize.height))
		
		tv.isEditable = false
		
//		tv.backgroundColor = NSColor.init(red: 0.6, green: 0.6, blue: 0.7, alpha: 1.0)
		
		tv.minSize = NSMakeSize( 0.0, contentSize.height )
		tv.maxSize = NSMakeSize( contentSize.width, CGFloat.greatestFiniteMagnitude )
		
		tv.isVerticallyResizable = true
		tv.isHorizontallyResizable = false
		
		tv.autoresizingMask = NSAutoresizingMaskOptions( arrayLiteral: .viewWidthSizable, .viewHeightSizable)
		
		tv.textContainer?.containerSize = NSMakeSize( contentSize.width, CGFloat.greatestFiniteMagnitude )
		tv.textContainer?.widthTracksTextView = true
		
		//
		// Add text view to the scroll view, and the scroll view to our view
		//
		sv.documentView = tv
		self.view.addSubview(sv)
		
		self.textView = tv
		self.textScrollView = sv
	}
	
	
	func _markersetup( cFrame: NSRect )
	{
		//
		// Scroll view - markers
		//
		let sv : SynchroScrollView = SynchroScrollView.init(frame: cFrame)
		
		sv.borderType = .noBorder
		sv.hasVerticalScroller = false
		sv.hasHorizontalScroller = false
		sv.autoresizingMask = NSAutoresizingMaskOptions(arrayLiteral: .viewHeightSizable)
		
		sv.backgroundColor = NSColor.init(red: 0.2, green: 0.2, blue: 0.9, alpha: 1.0)
		
		//
		// Add marker view
		//
//		let mrect = NSMakeRect(0, cFrame.origin.y, 10, cFrame.size.height)
		var mrect = cFrame
		mrect.size.height = 30
		let mv = MarkerView.init(frame: mrect)

		sv.documentView = mv

		self.markerScrollView = sv
		self.markerView = mv
		
		self.view.addSubview(sv)
	}
	
	
	/**
	 * Append a source line
	 */
	func append( line s: String )
	{
		
		let start = (textView?.textStorage?.length)!
		
		textView?.textStorage?.append( NSAttributedString.init(string: s) )
		textView?.textStorage?.append( NSAttributedString.init(string: "\n") )
		
		// Store the range of the line so we can hilght it as needed
		let len = (textView?.textStorage?.length)! - start
		lines.append( SourceLine( start: start, length: len ))
		
		// print( start, len )
	}
	
	
	/**
	 * Hilight a source line (show the current line)
	 *
	 * First line is index 0
	 */
	func hilight( line num : Int )
	{
		if let curHilight = self.curHilight
		{
			let range = lines[curHilight].range
			textView?.setTextColor(NSColor.textColor, range: range)
		}
		
		let range = lines[num].range
		
		textView?.scrollRangeToVisible(range)
		textView?.setTextColor(NSColor.red, range: range)
		
		self.curHilight = num
	}

	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		
//		self.append( line: "Howdy" )
//		self.append( line: "Line 2" )
//		self.append( line: "" )
//		self.append( line: "Mice" )
//		self.append( line: "" )
//		self.append( line: "" )
//		self.append( line: "" )
//		self.append( line: "Foo" )
//		self.append( line: "" )
//		self.append( line: "" )
//		self.append( line: "" )
//		self.append( line: "Bar" )
//		self.append( line: "door" )

		
//		self.textScrollView?.invalidateIntrinsicContentSize()
		
		// HACK
		let br = (self.textScrollView?.documentView?.bounds)!
//		self.markerScrollView?.documentView?.bounds = br
		print( "******************* new document view bounds for marker", br )
		//		self.markerScrollView?.bounds = (self.textScrollView?.bounds)!
		
		// Set marker view height manually. Does not work for bounds, but does for frame.
		var mvf = self.markerScrollView?.documentView?.frame
		mvf?.size.height = 366
//		self.markerScrollView?.documentView?.frame = mvf!
		
		let br0 = textView?.textStorage?.size()
		print( "******************* text storage size", br0! )
		
		let br9 = textView?.textContainer?.size
		print( "******************* text container size", br9! )
		
		let br3 = (self.textScrollView?.contentView.documentRect)!
		print( "***************************** text scrollview content doc rect", br3 )
		
		let br1 = (self.textScrollView?.bounds)!
		print( "******************* text scrollview bounds", br1 )
		
		let br2 = (self.markerScrollView?.bounds)!
		print( "******************* marker scrollview bounds", br2 )
	}
	
	
	override func viewDidAppear() {
		super.viewDidAppear()
		
		print( "========================  Did Appear  ==========================" )
		
		//		self.textView?.display()
		
		let br3 = (self.textScrollView?.contentView.documentRect)!
		print( "***************************** text scrollview content doc rect", br3 )
		
		let br9 = textView?.textContainer?.size
		print( "******************* text container size", br9! )
		
		DispatchQueue.main.async {
			let br3 = (self.textScrollView?.contentView.documentRect)!
			print( "**************************nrl text scrollview content doc rect", br3 )
		}
	}
	
	@IBAction func go1(_ sender: Any) {
		//		let range = NSRange.init(location: 0, length: 3)
		
		print( "========================  Go 1  ==========================" )
		
		let br7 = (self.textScrollView?.contentView.documentRect)!
		print( "******************************* text scrollview content doc rect", br7 )
		
		let br9 = textView?.textContainer?.size
		print( "******************* text container size", br9! )
		
		
		
//		let rr = textView?.firstRect(forCharacterRange: range, actualRange: nil)
//		print( rr! )
//		
//		let vrr = self.view.window?.convertFromScreen(rr!)
//		print( vrr! )
//		
//		markerView?.setBlip(pos: 6)
		
		
		let br0 = textView?.textStorage?.size()
		print( "******************* text storage size", br0! )
		
		let br3 = (self.textScrollView?.contentView.documentRect)!
		print( "************************************ text scrollview content doc rect", br3 )
		
		let br1 = (self.textScrollView?.bounds)!
		print( "******************* text scrollview bounds", br1 )
		
		let br2 = (self.markerScrollView?.bounds)!
		print( "******************* marker scrollview bounds", br2 )
	}

}
