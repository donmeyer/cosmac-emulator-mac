//
//  IOPortView.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 5/5/17.
//  Copyright © 2017 Donald Meyer. All rights reserved.
//

// This view controller manages one IO port.


import Cocoa

open class IOPortView: NSViewController
{
	@IBOutlet weak var portNumLabel: NSTextField!

	@IBOutlet weak var inputField: NSTextField!
	@IBOutlet weak var outputField: NSTextField!
	@IBOutlet weak var inoutBreak: NSButton!
	@IBOutlet weak var outputBreak: NSButton!
	
	
	override open func viewDidLoad()
	{
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
