//
//  AppDelegate.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 7/2/17.
//  Copyright © 2017 Donald Meyer. All rights reserved.
//

//import Foundation
import Cocoa



@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	var window: NSWindow?
	
	var mainWindowController : MainWindowController?
	
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		
		self.mainWindowController = MainWindowController.init(windowNibName:NSNib.Name(rawValue: "MainWindow"))
			
		self.mainWindowController?.showWindow( self )
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
	
	
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
	
	@objc func openFile( filename : String ) -> Bool
	{
		if filename.hasSuffix( ".lst" ) == false
		{
			return false
		}
		
		// Make sure file open modal goes away first
		self.mainWindowController?.perform(#selector(openFile), with: filename, afterDelay: 0.2)
		
		return true
	}
	
	
	func showHelp( sender : Any? )
	{
		let guideURL = URL( string: "http://www.sgsw.com/emu1802/help" )
		NSWorkspace.shared.open( guideURL! )
	}
	
}

