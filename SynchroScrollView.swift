//
//  SynchroScrollView.swift
//  1802 Emulator
//
//  Created by Donald Meyer on 6/2/17.
//  Copyright © 2017 Donald Meyer. All rights reserved.
//

import Cocoa



class SynchroScrollView: NSScrollView {
	weak var synchronizedScrollView : NSScrollView? = nil   // not retained
	
	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		
		// Drawing code here.
	}
	
	
	
	func setSynchronizedScrollView( scrollview : NSScrollView )
	{
		//		var synchronizedContentView : NSView
		
		// stop an existing scroll view synchronizing
		self.stopSynchronizing()
	 
		// don't retain the watched view, because we assume that it will
		// be retained by the view hierarchy for as long as we're around.
		synchronizedScrollView = scrollview
	 
		// get the content view of the
		let synchronizedContentView = synchronizedScrollView!.contentView
	 
		// Make sure the watched view is sending bounds changed
		// notifications (which is probably does anyway, but calling
		// this again won't hurt).
		synchronizedContentView.postsBoundsChangedNotifications = true
	 
		// a register for those notifications on the synchronized content view.
		NotificationCenter.default.addObserver(self, selector: #selector(synchronizedViewContentBoundsDidChange), name: NSNotification.Name.NSViewBoundsDidChange, object: synchronizedContentView )
	}
	
	
	func synchronizedViewContentBoundsDidChange( notification: NSNotification )
	{
		// get the changed content view from the notification
		let changedContentView : NSClipView = notification.object as! NSClipView
		
		// get the origin of the NSClipView of the scroll view that
		// we're watching
		let changedBoundsOrigin : NSPoint = changedContentView.documentVisibleRect.origin
		
		//		Swift.print( "marker bounds", self.documentView!.bounds )
		Swift.print( "clip view (doc rec, visible rect)", changedContentView.documentRect, changedContentView.documentVisibleRect )
		
		// HACK - try to make the size of this view match
		var br = self.documentView!.bounds
		//		br.size.height = changedContentView.documentView!.bounds.size.height	//
		br.size.height = changedContentView.documentRect.size.height	//
		self.documentView!.bounds = br
		
		// get our current origin
		let curOffset : NSPoint = self.contentView.bounds.origin
		var newOffset : NSPoint = curOffset
		
		// scrolling is synchronized in the vertical plane
		// so only modify the y component of the offset
		newOffset.y = changedContentView.documentVisibleRect.size.height - changedBoundsOrigin.y;
	 
		// if our synced position is different from our current
		// position, reposition our content view
		if !NSEqualPoints( curOffset, changedBoundsOrigin )
		{
			// note that a scroll view watching this one will
			// get notified here
			self.contentView.scroll( to: newOffset )
			
			// we have to tell the NSScrollView to update its
			// scrollers
			self.reflectScrolledClipView(self.contentView)
		}
	}
	
	
	func stopSynchronizing()
	{
		if let synchronizedScrollView = synchronizedScrollView
		{
			let synchronizedContentView = synchronizedScrollView.contentView
		 
			// remove any existing notification registration
			NotificationCenter.default.removeObserver( self,
			                                           name : NSNotification.Name.NSViewBoundsDidChange,
			                                           object : synchronizedContentView )
		 
			// set synchronizedScrollView to nil
			self.synchronizedScrollView = nil
		}
	}
	
}
