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
	@IBOutlet private weak var portNumLabel: NSTextField!

	@IBOutlet private weak var inputField: NSTextField!
	@IBOutlet private weak var outputField: NSTextField!
	@IBOutlet private weak var inoutBreak: NSButton!
	@IBOutlet private weak var outputBreak: NSButton!
	
	private var outValue : UInt8 = 0
	
	enum Format {
		case hex
		case decimal
	}
	
	var format : Format = .hex
	
	var shouldBreakOnPortRead : Bool {
		get {
			return inoutBreak.state == .on ? true : false
		}
	}
	
	var shouldBreakOnPortWrite : Bool {
		get {
			return outputBreak.state == .on ? true : false
		}
	}
	
	var portNum : Int {
		set {
			portNumLabel.stringValue = String(newValue)
		}
		
		get {
			return portNumLabel.integerValue
		}
	}
	
	override open func viewDidLoad()
	{
        super.viewDidLoad()
        // Do view setup here.
		
		inoutBreak.state = NSControl.StateValue(rawValue: 0)
		outputBreak.state = NSControl.StateValue(rawValue: 0)
    }
	
	
	func setOutputPort( byte: UInt8 )
	{
		outValue = byte
		outputField.stringValue = String.init(format: "0x%02X", outValue) as String
	}
	
	
	func readInputPort() -> UInt8
	{
		return UInt8(inputField.integerValue)
	}
	
}
