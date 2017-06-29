//
//  ScratchpadRegistersView.h
//  1802 Emulator
//
//  Created by Donald Meyer on 6/7/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CPU Emulation.h"



@interface ScratchpadRegistersView : NSView

@property (nonatomic, strong) NSColor *changedColor;

- (void)setDescription:(NSString*)desc forReg:(int)reg;
- (void)clearDescriptions;

- (void)updateRegisters:(const CPU*)cpu;

@end
