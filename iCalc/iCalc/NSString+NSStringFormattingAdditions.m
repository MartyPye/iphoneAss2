//
//  NSString+NSStringFormattingAdditions.m
//  iCalc
//
//  Created by Marty Pye on 29/10/13.
//  Copyright (c) 2013 Florian Heller. All rights reserved.
//

#import "NSString+NSStringFormattingAdditions.h"

@implementation NSString (NSStringFormattingAdditions)

+ (NSString*) stringByRemovingLeadingZerosFromString:(NSString*)aString;
{
    NSArray *floatStringComps = [aString componentsSeparatedByString:@"."];
    
    // the string doesn't have a decimal point
    if (floatStringComps.count == 1) {
        return [NSString stringWithFormat:@"%i", [aString integerValue]];
    }
    
    else {
        NSString *intPart = [floatStringComps objectAtIndex:0];
        int intValue = [intPart integerValue];
        NSString *newString = [[[NSString stringWithFormat:@"%i", intValue] stringByAppendingString:@"."] stringByAppendingString:[floatStringComps objectAtIndex:1]];
        return newString;
    }
}


+ (NSString*) stringByRemovingDanglingZerosFromDecimalString:(NSString*)aString;
{
    NSArray *floatStringComps = [aString componentsSeparatedByString:@"."];
    
    // the string doesn't have a decimal point
    if (floatStringComps.count == 1) {
        return aString;
    }
    
    else {
        
        NSString *decimal = [floatStringComps objectAtIndex:1];
        // e.g 123.01000
        //           *
        int indexOfFirstZero = 0;
        for (int i = decimal.length - 1; i >= 0; i--) {
            if ([decimal characterAtIndex:i] != '0') {
                indexOfFirstZero = i+1;
                break;
            }
        }
        
        if (indexOfFirstZero == 0) {
            // 123
            return [floatStringComps objectAtIndex:0];
        }
        
        else if (indexOfFirstZero != decimal.length) {
            // 01
            NSString *newDecimal = [decimal substringToIndex:indexOfFirstZero];
            // 123.
            NSString *intPlusDot = [[floatStringComps objectAtIndex:0] stringByAppendingString:@"."];
            
            // 123.01
            return [intPlusDot stringByAppendingString:newDecimal];
        }
        
        // e.g 123.0001
        else {
            // 123.0001
            return aString;
        }
        

    }
}

@end
