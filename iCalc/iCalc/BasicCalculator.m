//
//  BasicCalculator.m
//  iCalc
//
//  Created by Florian Heller on 10/22/10.
//  Modified by Chat Wacharamanotham on 11.11.13.
//  Copyright 2010 RWTH Aachen University. All rights reserved.
//

#import "BasicCalculator.h"


#pragma mark Object Lifecycle
@implementation BasicCalculator


- (id)init
{
	self = [super init];
	if (self != nil) {
		self.lastOperand = [NSNumber numberWithInt:0];
		self.delegate = nil;
		self.rememberLastResult = YES;
	}
	return self;
}

- (void)dealloc
{
	//With synthesized setters, you set the object to nil to release it
	//If delegate would be just a simple ivar, we would call [delegate release];
	self.delegate = nil;
	self.lastOperand = nil;
}


#pragma mark Method implementation

// ----------------------------------------------------------------------------------------------------
//Set our lastOperand cache to be another operand
// ----------------------------------------------------------------------------------------------------
- (void)setFirstOperand:(NSNumber*)anOperand;
{
	self.lastOperand = anOperand;
}


// ----------------------------------------------------------------------------------------------------
// This method performs an operation with the given operation and the second operand. 
// After the operation is performed, the result is written to lastOperand
// ----------------------------------------------------------------------------------------------------
- (void)performOperation:(BCOperator)operation withOperand:(NSNumber*)operand;
{
	NSNumber *result;
    switch (operation) {
        case BCOperatorAddition:
            result = [NSNumber numberWithDouble:([self.lastOperand doubleValue] + [operand doubleValue])]; //this is autoreleased
            self.lastOperand = result; //Since NSNumber is immutable, no side-effects. Memory management is done in the setter
            break;
        case BCOperatorSubtraction:
            result = [NSNumber numberWithDouble:([self.lastOperand doubleValue] - [operand doubleValue])]; //this is autoreleased
            self.lastOperand = result; //Since NSNumber is immutable, no side-effects. Memory management is done in the setter
            break;
        case BCOperatorMultiplication:
            result = [NSNumber numberWithDouble:([self.lastOperand doubleValue] * [operand doubleValue])]; //this is autoreleased
            self.lastOperand = result; //Since NSNumber is immutable, no side-effects. Memory management is done in the setter
            break;
        case BCOperatorDivision:
            if ([operand doubleValue] == 0) {
                result = [NSDecimalNumber notANumber];
            }
            else {
                result = [NSNumber numberWithDouble:([self.lastOperand doubleValue] / [operand doubleValue])];
            }
            self.lastOperand = result; //Since NSNumber is immutable, no side-effects. Memory management is done in the setter
            break;
        default:
            break;
    }
    
    // TODO: add result to History
	
	[self notifyDelegateOfResult:result];
	

}


// This method clears everything (for the moment 
- (void)reset;
{
	self.lastOperand = [NSNumber numberWithInt:0];
}

// The following method is shamelessly modified from http://www.programmingsimplified.com/c/source-code/c-program-for-prime-number
- (BOOL)checkPrime:(NSInteger)theInteger;
{
    NSInteger checkValue;
    BOOL result;
        
    for (checkValue = 2 ; checkValue <= theInteger - 1 ; checkValue++)
    {
        if (theInteger % checkValue == 0)
        {
            result = NO;
            break;
        }
        
        // sleep(1);    // uncomment this line to make the execution significantly longer for a more dramatic effect :D
    }
    if (checkValue == theInteger)
    {
        result = YES;
    }
    
    return result;
}

- (void) notifyDelegateOfResult:(NSNumber*)theResult;
{
    // Now call the delegate method with the result. If the delegate is nil, this will just do nothing.
	if (_delegate != nil) {
		if ([_delegate respondsToSelector:@selector(operationDidCompleteWithResult:)])
		{
			[_delegate operationDidCompleteWithResult:theResult];
		}
		else {
			NSLog(@"WARNING: the BasicCalculator delegate does not implement operationDidCompleteWithResult:");
		}
	}
	else {
		NSLog(@"WARNING: the BasicCalculator delegate is nil");
	}
}


// -----------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark part 2
 // NOTE: you may change the signature of the following methods. Just keep the given name as a substring.
// -----------------------------------------------------------------------------------------------------------------

- (void)checkByGCD;
{
    // Task 2.2
}

- (void)checkByOpQueue;
{
    // Task 2.3
}

- (BOOL)checkPrimeAllowCancel:(NSInteger)theInteger;
{
    // Task 2.4 (extra credit)
}

- (void)checkPerserveOrder;
{
    // Task 2.5 (extra credit)
}

@end
