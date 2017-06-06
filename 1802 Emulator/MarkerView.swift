//
//  MarkerView.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 6/5/17.
//  Copyright © 2017 Donald Meyer. All rights reserved.
//

import Cocoa




class MarkerView : NSView
{
	var pos : CGFloat?
	
	
	override init(frame frameRect: NSRect)
	{
		super.init(frame: frameRect)
	}
	
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	
	func setBlip( pos: CGFloat )
	{
		self.pos = pos
		self.setNeedsDisplay(bounds)
	}
	
	
	override func draw(_ dirtyRect: NSRect)
	{
		super.draw( dirtyRect )
		
		NSColor.green.setFill()
		NSRectFill(bounds)
		
		if let pos = pos
		{
			let gc = NSGraphicsContext.current()?.cgContext
			gc?.setLineWidth(1.0)
			gc?.setFillColor(NSColor.red.cgColor)
			
			let rect = NSMakeRect(2, pos, 8, 8)
			gc?.fillEllipse(in: rect)
		}
	}
}
