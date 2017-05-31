//
//  TerminalWindowController.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 5/30/17.
//  Copyright © 2017 Donald Meyer. All rights reserved.
//

import Cocoa

class TerminalWindowController: NSWindowController {

	@IBOutlet private weak var inputTextField: NSTextField!
	@IBOutlet private var outputTextView: NSTextView!
	
	private var cmdString = ""
	
	
	
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		
		outputTextView.font = NSFont.init(name: "Consolas", size: 11)
    }

	
	public func emitTerminalText( _ text : String )
	{
		let astr = NSAttributedString.init(string: text)
		outputTextView.textStorage?.append(astr)
		
		outputTextView.scrollToEndOfDocument(nil)
	}
	
	
	public func emitTerminalCharacter( _ c : UInt8 )
	{
		let s = String.init(format: "%c", c )
		let astr = NSAttributedString.init(string: s)
		outputTextView.textStorage?.append(astr)
		
		outputTextView.scrollToEndOfDocument(nil)
	}
	
	
	func hasCmdChar() -> Bool
	{
		return cmdString.characters.count > 0 ? true : false
	}
	
	
	/// returns -1 if none available.
	func nextCommandChar() -> Int
	{
		if self.hasCmdChar()
		{
			let z = Array( cmdString.unicodeScalars )
			cmdString.characters.removeFirst()
			return Int(z[0].value)
		}
		else
		{
			return -1
		}
	}
	
	
	@IBAction func cmdEntered(_ sender: Any)
	{
		let field = sender as! NSTextField
		
		let buf = String.init(format: "%@\r", field.stringValue )
		cmdString.append(buf)
		
		field.stringValue = ""
	}
	
}
