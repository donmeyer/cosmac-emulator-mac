//
//  _802_EmulatorTests.m
//  1802 EmulatorTests
//
//  Created by Donald Meyer on 6/1/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#include "CPU Emulation.h"



@interface _802_EmulatorTests : XCTestCase

@end


CPU *cpu;



@implementation _802_EmulatorTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
	
	CPU_makeReadWritePage( 0 );
	CPU_reset();

	cpu = CPU_getCPU_Unit_Test();
}


- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}



#pragma mark - Math Instructions

- (void)testSubtraction_1
{
	cpu->D = 0x20;
	
	const uint8_t pgm[] = { 0x75, 0x40 };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x1F, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );
}


- (void)testSubtraction_2
{
	cpu->D = 0xC1;
	
	const uint8_t pgm[] = { 0x75, 0x4A };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x88, @"D contents" );
	XCTAssertEqual( cpu->DF, 0, @"DF contents" );
}


- (void)testSubtraction_3
{
	cpu->D = 0x32;
	cpu->DF = 1;
	
	const uint8_t pgm[] = { 0x75, 0x64 };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x32, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );
}


- (void)testSubtraction_4
{
	cpu->D = 0xF2;
	cpu->DF = 1;
	
	const uint8_t pgm[] = { 0x75, 0x71 };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x7F, @"D contents" );
	XCTAssertEqual( cpu->DF, 0, @"DF contents" );
}



#pragma mark - Logic Instructions

- (void)testSHRC
{
	const uint8_t pgm[] = { 0x76 };
	CPU_writeToMemory( pgm, 0x0000, 1 );
	
	cpu->D = 0x81;
	cpu->DF = 1;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0xC0, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );


	CPU_reset();
	cpu->D = 0x80;
	cpu->DF = 1;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0xC0, @"D contents" );
	XCTAssertEqual( cpu->DF, 0, @"DF contents" );


	CPU_reset();
	cpu->D = 0x81;
	cpu->DF = 0;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x40, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );


	CPU_reset();
	cpu->D = 0x80;
	cpu->DF = 0;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x40, @"D contents" );
	XCTAssertEqual( cpu->DF, 0, @"DF contents" );
}



#pragma mark - IO Instructions

static void *ioUserdata;
static int ioPort;
static int ioData;

static void ocb( void *userData, uint8_t port, uint8_t data )
{
//	NSLog( @"Output port %d  data 0x%02X", port, data );
	ioUserdata = userData;
	ioPort = port;
	ioData = data;
}

- (void)testOutput
{
	const uint8_t pgm[] = { 0x61, 0x22 };
	CPU_writeToMemory( pgm, 0x0000, 2 );

	CPU_setOutputCallback( ocb, (void*)123 );

	CPU_step();
	
	XCTAssertEqual( ioUserdata, (void*)123, @"User Data" );
	XCTAssertEqual( ioPort, 1, @"Port" );
	XCTAssertEqual( ioData, 0x22, @"Data byte" );
}


- (void)testInput
{
	// TODO: Implement
}

@end
