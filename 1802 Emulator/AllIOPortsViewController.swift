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
	var ports : [IOPortView] = []
	
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
			pv.portNumLabel.stringValue = String(i)
			
			ports.append(pv)
			
			i -= 1
		}
	}
	
	
	func setOutputPort( _ port: Int, byte: UInt8 )
	{
		ports[port].outputField.stringValue = "18"
	}
	
	
	func readInputPort( _ port: Int ) -> UInt8
	{
		return 0
	}
	
	
	func shouldBreakOnPortRead( _ port: Int ) -> Bool
	{
		return false
	}


	func shouldBreakOnPortWrite( _ port: Int ) -> Bool
	{
		return false
	}
}
