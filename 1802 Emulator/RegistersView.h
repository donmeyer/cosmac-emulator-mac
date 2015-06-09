//
//  RegistersView.h
//  1802 Emulator
//
//  Created by Donald Meyer on 6/7/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CPU Emulation.h"



@interface RegistersView : NSView

- (void)setDescription:(NSString*)desc forReg:(int)reg;

- (void)updateRegisters:(const CPU*)cpu;

@end
