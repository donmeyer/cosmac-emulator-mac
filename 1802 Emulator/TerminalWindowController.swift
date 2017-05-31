//
//  TerminalWindowController.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 5/30/17.
//  Copyright © 2017 Donald Meyer. All rights reserved.
//

import Cocoa

class TerminalWindowController: NSWindowController {

	
	@IBOutlet weak var inputTextField: NSTextField!
	@IBOutlet var outputTextView: NSTextView!
	
	var terminalString = ""
	var cmdString = ""
	
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		
		outputTextView.font = NSFont.init(name: "Consolas", size: 11)
    }

	
	public func emitTerminalText( _ text : String )
	{
		terminalString.append( text )
		outputTextView.string = terminalString
		outputTextView.scrollToEndOfDocument(nil)
	}
	
	
	public func emitTerminalCharacter( _ c : UInt8 )
	{
		terminalString.append(Character.init(UnicodeScalar.init(c)))
		outputTextView.string = terminalString
		outputTextView.scrollToEndOfDocument(nil)
	}
	
	
	func hasCmdChar() -> Bool
	{
		return cmdString.lengthOfBytes(using: .ascii) > 0 ? true : false
	}
	
	
	/// returns -1 if none
	func nextCommandChar() -> Int
	{
		if cmdString.characters.count > 0
		{
			let z = Array( cmdString.unicodeScalars )
			cmdString.characters.removeFirst()
			return Int(z[0].value)
		}
		return -1
	}
	
	
	@IBAction func cmdEntered(_ sender: Any)
	{
		let field = sender as! NSTextField
		let buf = String.init(format: "%@\r", field.stringValue )
		cmdString = buf
		field.stringValue = ""
	}
	
}
