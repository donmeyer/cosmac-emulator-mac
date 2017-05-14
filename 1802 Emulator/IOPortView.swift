//
//  IOPortView.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 5/5/17.
//  Copyright © 2017 Donald Meyer. All rights reserved.
//

import Cocoa

class IOPortView: NSViewController {
	@IBOutlet weak var portNumLabel: NSTextField!

	@IBOutlet weak var inputField: NSTextField!
	@IBOutlet weak var outputField: NSTextField!
	@IBOutlet weak var inoutBreak: NSButton!
	@IBOutlet weak var outputBreak: NSButton!
	
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
