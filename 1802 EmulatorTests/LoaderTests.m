//
//  LoaderTests.m
//  1802 Emulator
//
//  Created by Donald Meyer on 6/5/15.
//  Copyright (c) 2015 Donald Meyer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "HexLoader.h"



@interface LoaderTests : XCTestCase

@end



@implementation LoaderTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}


- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



- (void)testLine_1
{
    XCTAssert(YES, @"Pass");
	
	do this with 1, 2, and 3 digit pairs
	NSString *line = @"AA55 12FC;";

	HexLoader *loader = [[HexLoader alloc] initWithListingString:line];
	
	int byteCount = 0;
	[loader load:(void (^)(long addr, unsigned char byte))
	{
		if( byteCount == 0 )
		{
			XCTAssertEqual( addr, 0xAA55, @"Address match" );
			XCTAssertEqual( byte, 0x12, @"Data match" );
		}
		else if( byteCount == 1 )
		{
			XCTAssertEqual( addr, 0xAA56, @"Address match" );
			XCTAssertEqual( byte, 0xFC, @"Data match" );
		}
		
		byteCount++;
	}];
	
	XCTAssertEqual( byteCount, 2, @"Byte count" );
}


@end
