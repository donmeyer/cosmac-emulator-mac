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
		
		var i = 7
		while( i >= 0 )
		{
			let pv = IOPortView.init()
			
			var r = pv.view.frame
			r.origin.y = yPos
			pv.view.frame = r
			yPos += r.size.height
			
			print( "IO port view frame:", NSStringFromRect( pv.view.frame ) )
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

//	func inLabel() -> NSTextField
//	{
//		let label = NSTextField.init()
//		label.isEditable = false
//		label.isBordered = false
//		label.drawsBackground = false
//		label.stringValue = "In"
//		label.sizeToFit()
//		return label
//	}
	
	func setOutputPort( _ port: Int, byte: UInt8 )
	{
		assert( ports[port] != nil, "Port out of range 1-7" )
		ports[port]!.setOutputPort(byte: byte)
	}
	
	
	func readInputPort( _ port: Int ) -> UInt8
	{
		assert( ports[port] != nil, "Port out of range 1-7" )
		return ports[port]!.readInputPort()
	}
	
	
	func shouldBreakOnPortRead( _ port: Int ) -> Bool
	{
		assert( ports[port] != nil, "Port out of range 1-7" )
		return ports[port]!.shouldBreakOnPortRead
	}


	func shouldBreakOnPortWrite( _ port: Int ) -> Bool
	{
		assert( ports[port] != nil, "Port out of range 1-7" )
		return ports[port]!.shouldBreakOnPortWrite
	}

}
