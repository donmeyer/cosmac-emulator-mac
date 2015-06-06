//
//  MainViewController.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/5/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import "MainViewController.h"



@interface MainViewController ()

@property (weak) IBOutlet NSTextField *foo;

@end



@implementation MainViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
}


-(void)viewWillAppear
{
	[super viewWillAppear];
	
	self.foo.objectValue = @"Rats";
}



#pragma mark - Actions

- (IBAction)stepAction:(id)sender
{
	NSLog( @"Step" );
}


- (IBAction)runAction:(id)sender
{
	NSLog( @"Run" );
}


- (IBAction)pauseAction:(id)sender
{
	NSLog( @"Pause" );
}



- (IBAction)resetAction:(id)sender
{
	NSLog( @"Reset" );
}


@end
