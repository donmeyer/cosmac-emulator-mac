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

// ADD 1-4
- (void)test_ADD_1
{
	cpu->D = 0x20;
	cpu->DF = 0;
	
	const uint8_t pgm[] = { 0xF4, 0x43 };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x63, @"D contents" );
	XCTAssertEqual( cpu->DF, 0, @"DF contents" );
}

// ADD 2-4
- (void)test_ADD_2
{
	cpu->D = 0xC1;
	cpu->DF = 0;
	
	const uint8_t pgm[] = { 0xF4, 0x4A };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x0B, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );
}


// ADD 3-4
- (void)test_ADD_3
{
	cpu->D = 0x40;
	cpu->DF = 1;
	
	const uint8_t pgm[] = { 0xF4, 0x21 };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x61, @"D contents" );
	XCTAssertEqual( cpu->DF, 0, @"DF contents" );
}


// ADD 4-4
- (void)test_ADD_4
{
	cpu->D = 0xC1;
	cpu->DF = 1;
	
	const uint8_t pgm[] = { 0xF4, 0x4A };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x0B, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );
}



// SD 1-4
- (void)testSubtraction_SD_1
{
	cpu->D = 0x0E;
	cpu->DF = 0;
	
	const uint8_t pgm[] = { 0xF5, 0x42 };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x34, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );
}

// SB 2-4
- (void)testSubtraction_SD_2
{
	cpu->D = 0x42;
	cpu->DF = 0;
	
	const uint8_t pgm[] = { 0xF5, 0x42 };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x00, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );
}


// SB 3-4
- (void)testSubtraction_SD_3
{
	cpu->D = 0x77;
	cpu->DF = 1;
	
	const uint8_t pgm[] = { 0xF5, 0x42 };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0xCB, @"D contents" );
	XCTAssertEqual( cpu->DF, 0, @"DF contents" );
}




// SDB 1-4
- (void)testSubtraction_SDB_1
{
	cpu->D = 0x20;
	cpu->DF = 0;
	
	const uint8_t pgm[] = { 0x75, 0x40 };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x1F, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );
}

// SDB 2-4
- (void)testSubtraction_SDB_2
{
	cpu->D = 0xC1;
	cpu->DF = 0;
	
	const uint8_t pgm[] = { 0x75, 0x4A };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x88, @"D contents" );
	XCTAssertEqual( cpu->DF, 0, @"DF contents" );
}


// SDB 3-4
- (void)testSubtraction_SDB_3
{
	cpu->D = 0x32;
	cpu->DF = 1;
	
	const uint8_t pgm[] = { 0x75, 0x64 };
	CPU_writeToMemory( pgm, 0x0000, 2 );
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x32, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );
}


// SDB 4-4
- (void)testSubtraction_SDB_4
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


- (void)test_SHL
{
	const uint8_t pgm[] = { 0xFE };
	CPU_writeToMemory( pgm, 0x0000, 1 );
	
	cpu->D = 0x81;
	cpu->DF = 1;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x02, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );


	CPU_reset();
	cpu->D = 0x01;
	cpu->DF = 1;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x02, @"D contents" );
	XCTAssertEqual( cpu->DF, 0, @"DF contents" );


	CPU_reset();
	cpu->D = 0x81;
	cpu->DF = 0;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x02, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );


	CPU_reset();
	cpu->D = 0x01;
	cpu->DF = 0;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x02, @"D contents" );
	XCTAssertEqual( cpu->DF, 0, @"DF contents" );
}


- (void)test_SHLC
{
	const uint8_t pgm[] = { 0x7E };
	CPU_writeToMemory( pgm, 0x0000, 1 );
	
	cpu->D = 0x81;
	cpu->DF = 1;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x03, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );


	CPU_reset();
	cpu->D = 0x01;
	cpu->DF = 1;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x03, @"D contents" );
	XCTAssertEqual( cpu->DF, 0, @"DF contents" );


	CPU_reset();
	cpu->D = 0x81;
	cpu->DF = 0;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x02, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );


	CPU_reset();
	cpu->D = 0x01;
	cpu->DF = 0;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x02, @"D contents" );
	XCTAssertEqual( cpu->DF, 0, @"DF contents" );
}


- (void)test_SHR
{
	const uint8_t pgm[] = { 0xF6 };
	CPU_writeToMemory( pgm, 0x0000, 1 );
	
	cpu->D = 0x81;
	cpu->DF = 1;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x40, @"D contents" );
	XCTAssertEqual( cpu->DF, 1, @"DF contents" );


	CPU_reset();
	cpu->D = 0x80;
	cpu->DF = 1;
	
	CPU_step();
	
	XCTAssertEqual( cpu->D, 0x40, @"D contents" );
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



- (void)test_SHRC
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
