//
//  RegistersViewController.h
//  1802 Emulator
//
//  Created by Donald Meyer on 6/12/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CPU Emulation.h"



@interface RegistersViewController : NSViewController

- (void)updateCPUState:(const CPU*)cpu;
- (void)reset;

- (void)setDescription:(NSString*)desc forReg:(int)reg;
- (void)clearDescriptions;

@end
