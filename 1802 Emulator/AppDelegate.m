//
//  AppDelegate.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/1/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

//#import <CocoaLumberjack/CocoaLumberjack.h>

#import "AppDelegate.h"
#import "MainWindowController.h"
#import "Log.h"


//static const DDLogLevel ddLogLevel = DDLogLevelVerbose;


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (strong) MainWindowController *mainWindowController;

@end



@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
//	NSNumber *foo;

//	[DDLog addLogger:[DDASLLogger sharedInstance]];
//	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindow"];

	[self.mainWindowController showWindow:self];
}


// Called when the user double-clicks or does a drag/drop.
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
	if( [filename hasSuffix:@".lst"] == NO )
	{
		return NO;
	}
	
	// Make sure file open modal goes away first
	[self.mainWindowController performSelector:@selector(openFile:) withObject:filename afterDelay:0.2];
	
	return YES;
}


- (void)openDocument:(id)sender
{
	LogDebug( @"Open document" );
	[self.mainWindowController openDocument];
}

- (void)showHelp:(id)sender
{
	NSURL *guideURL = [NSURL URLWithString:@"http://www.sgsw.com/emu1802/help"];
	[[NSWorkspace sharedWorkspace] openURL:guideURL];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// Insert code here to tear down your application
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

@end
