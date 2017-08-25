//
//  AllIOPortsViewController.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 5/16/17.
//  Copyright © 2017 Donald Meyer. All rights reserved.
//

// This view controller manages all of the IO ports.
// It does this by instantiating 7 IOPortView objects.



import Cocoa



class AllIOPortsViewController: NSViewController
{
	var ports = [Int : IOPortView]()
	
	var efButtons = [Int : NSButton]()
	
	lazy var inLabel = { () -> NSTextField in
		let label = NSTextField.init()
		label.isEditable = false
		label.isBordered = false
		label.drawsBackground = false
		label.font = NSFont.boldSystemFont(ofSize: 14)
		label.stringValue = "In"
		label.sizeToFit()
		return label
	}()
	
	lazy var outLabel = { () -> NSTextField in
		let label = NSTextField.init()
		label.isEditable = false
		label.isBordered = false
		label.drawsBackground = false
		label.font = NSFont.boldSystemFont(ofSize: 14)
		label.stringValue = "Out"
		label.sizeToFit()
		return label
	}()
	
	
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		var yPos : CGFloat = 0
		
		if #available(OSX 10.12, *) {
			let dia : CGFloat = 32.0
			let BGAP : CGFloat = 52
			print( self.view.frame )
			
			var x : CGFloat = ( self.view.frame.size.width - ( dia * 4) - ( BGAP * 3 ) ) / 2  //30.0
			
			let buttonY = yPos + 10
			
			self.efButtons[0] = self.makeEFButton(title: "EF1", diameter : dia, x:x, y:buttonY)
			x += BGAP
			self.efButtons[1] = self.makeEFButton(title: "EF2", diameter : dia, x:x, y:buttonY)
			x += BGAP
			self.efButtons[2] = self.makeEFButton(title: "EF3", diameter : dia, x:x, y:buttonY)
			x += BGAP
			self.efButtons[3] = self.makeEFButton(title: "EF4", diameter : dia, x:x, y:buttonY)
			x += BGAP
			
			yPos += 50
		} else {
			// Fallback on earlier versions
			// sadness
		}
		
		var i = 7
		while( i >= 0 )
		{
			let pv = IOPortView.init()
			
			var r = pv.view.frame
			r.origin.y = yPos
			pv.view.frame = r
			yPos += r.size.height
			
//FOOP			LogDebug( "IO port view frame:", NSStringFromRect( pv.view.frame ) )
			self.view.addSubview( pv.view )
			// Cannot set this until the view has been loaded!
			pv.portNum = i
			
			ports[i] = pv
			
			i -= 1
		}
		
		inLabel.setFrameOrigin( NSMakePoint(46, yPos+2) )
		self.view.addSubview(inLabel)

		outLabel.setFrameOrigin( NSMakePoint(156, yPos+2) )
		self.view.addSubview(outLabel)

//		var br = self.view.frame
//		br.size.height = yPos + 50
//		self.view.frame = br
		
//		self.preferredContentSize = NSMakeSize(300, yPos+50)
	}
	
	
	override func viewWillLayout() {
		super.viewWillLayout()
		print( self.view.frame )
	}
	
	@objc func efButtonAction( sender : Any? )
	{
		let button = sender as! NSButton
		switch( button )
		{
		case self.efButtons[0]!:
			CPU_setEF(0, Int32(button.state.rawValue))
		case self.efButtons[1]!:
			CPU_setEF(1, Int32(button.state.rawValue))
		case self.efButtons[2]!:
			CPU_setEF(2, Int32(button.state.rawValue))
		case self.efButtons[3]!:
			CPU_setEF(3, Int32(button.state.rawValue))
		default:
			print ("This cannot happen with only 4 EF buttons!")
		}
	}
	
	
	@objc func setOutputPort( _ port: Int, byte: UInt8 )
	{
		assert( ports[port] != nil, "Port out of range 1-7" )
		ports[port]!.setOutputPort(byte: byte)
	}
	
	
	@objc func readInputPort( _ port: Int ) -> UInt8
	{
		assert( ports[port] != nil, "Port out of range 1-7" )
		return ports[port]!.readInputPort()
	}
	
	
	@objc func shouldBreakOnPortRead( _ port: Int ) -> Bool
	{
		assert( ports[port] != nil, "Port out of range 1-7" )
		return ports[port]!.shouldBreakOnPortRead
	}


	@objc func shouldBreakOnPortWrite( _ port: Int ) -> Bool
	{
		assert( ports[port] != nil, "Port out of range 1-7" )
		return ports[port]!.shouldBreakOnPortWrite
	}
	
	
	/// Makes the button and adds it to the view at the specified point.
	private func makeEFButton( title: String, diameter : CGFloat, x: CGFloat, y: CGFloat ) -> NSButton
	{
//		let img = NSImage.init(named: NSImage.Name(rawValue: "onButtonEF"))
//		let img = NSImage.init(size: NSMakeSize(20, 20))
//		img!.resizingMode = .stretch
//		img.backgroundColor = NSColor.green
		
		let img = self.efButtonImage( diameter : diameter, color: NSColor.red)
		let button = NSButton.init(image: img, target: self, action: #selector(efButtonAction))
		button.isBordered = false
//		button.sizeToFit()
//		button = NSButton.init(title: "EF1", target: self, action: #selector(foo))
//		button.setButtonType(.pushOnPushOff)
//		button.image = img
		button.setFrameSize(img.size)
		button.setFrameOrigin( NSMakePoint(x, y) )
		button.title = title
		button.setButtonType(.toggle)
		button.alternateImage = self.efButtonImage( diameter : diameter, color: NSColor.green)
		self.view.addSubview(button)
		return button
	}
	
	
	private func efButtonImage( diameter : CGFloat, color: NSColor ) -> NSImage
	{
		//
		// Calculate the sizes
		//
		let size = CGSize.init( width: diameter, height: diameter )
		let rect = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
		
		let image = NSImage.init(size: size)
		image.lockFocus()
		
		let context = NSGraphicsContext.current!.cgContext
		
		context.setFillColor( NSColor.clear.cgColor )
		context.fill(rect)
		
		context.setFillColor( NSColor.black.cgColor )
		context.fillEllipse( in: rect );
		
		context.setFillColor( color.cgColor )
		let innerRect = rect.insetBy(dx: 1, dy: 1)
		context.fillEllipse( in: innerRect );
		
		image.unlockFocus()
		
		return image
	}
	
}
