//
//  LEDView.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 8/9/18.
//  Copyright © 2018 Donald Meyer. All rights reserved.
//

import Cocoa


class LEDView: NSImageView {

	private var onImage : NSImage
	private var offImage : NSImage

	var state : Bool {
		get {
			return self.image == onImage
		}
		set {
			self.image = newValue ? onImage : offImage
		}
	}

	init( diameter : CGFloat ) {
		onImage = LEDView.makeImage( diameter : diameter, color: .red)
		offImage = LEDView.makeImage(diameter: diameter, color: .gray)
		
		super.init(frame: NSRect(x: 0, y: 0, width: diameter, height: diameter))
		
		self.image = offImage
		
	}

	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	private static func makeImage( diameter : CGFloat, color: NSColor ) -> NSImage
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
