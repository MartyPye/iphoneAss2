//
//  NSString+NSStringFormattingAdditions.h
//  iCalc
//
//  Created by Marty Pye on 29/10/13.
//  Copyright (c) 2013 Florian Heller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSStringFormattingAdditions)

+ (NSString*) stringByRemovingLeadingZerosFromString:(NSString*)aString;
+ (NSString*) stringByRemovingDanglingZerosFromDecimalString:(NSString*)aString;

@end
