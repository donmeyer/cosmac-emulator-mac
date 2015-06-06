//
//  AppDelegate.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/1/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>

#import "AppDelegate.h"



@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end



@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
//	NSNumber *foo;

	[DDLog addLogger:[DDASLLogger sharedInstance]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
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
