//
//  iCalc_Tests.m
//  iCalc Tests
//
//  Created by Marty Pye on 29/10/13.
//  Copyright (c) 2013 Florian Heller. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+NSStringFormattingAdditions.h"

@interface iCalc_Tests : XCTestCase

@end

@implementation iCalc_Tests

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

- (void) testDanglingDecimalZeroes
{
    //test if dangling decimal point is handled by floatValue
    NSString *danglingDecimal = @"123.01000000010";
    NSString *test = [NSString removeDanglingZerosFromDecimalString:danglingDecimal];
    XCTAssertTrue([test isEqualToString:@"123.0100000001"], "dangling decimal not handled correctly");
}

- (void)testLeadingZerosRemoval
{
    
    NSString *intString = @"0000123";
    NSString *floatString = @"00123.0000";
    intString = [NSString removeLeadingZerosFromString:intString];
    floatString = [NSString removeLeadingZerosFromString:floatString];
    XCTAssertTrue([intString isEqualToString: @"123"], @"Zeros were not removed correctly from int");
    XCTAssertTrue([floatString isEqualToString: @"123.0000"], @"Zeros were not removed correctly from float");
    
    
}

@end
