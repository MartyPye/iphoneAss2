//
//  BasicCalculator.m
//  iCalc
//
//  Created by Florian Heller on 10/22/10.
//  Modified by Chat Wacharamanotham on 11.11.13.
//  Copyright 2010 RWTH Aachen University. All rights reserved.
//

#import "BasicCalculator.h"

@interface BasicCalculator()

@property (strong) ResultManager *resultManager;

@end


#pragma mark - Object Lifecycle
@implementation BasicCalculator


- (id)init
{
	self = [super init];
	if (self != nil) {
		self.lastOperand = [NSNumber numberWithInt:0];
		self.delegate = nil;
		self.rememberLastResult = YES;
        self.lastResult = [[NSNumber alloc] init];
        self.resultManager = [[ResultManager alloc] init];
        
        // add observer
        [self addObserver:self.resultManager forKeyPath:@"lastResult"
                             options:NSKeyValueObservingOptionNew
                             context:nil];
        
        [self restoreState];
        
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


#pragma mark - Method implementation

// ----------------------------------------------------------------------------------------------------
// Set our lastOperand cache to be another operand
// ----------------------------------------------------------------------------------------------------
- (void)setFirstOperand:(NSNumber*)anOperand;
{
	self.lastOperand = anOperand;
}


// ----------------------------------------------------------------------------------------------------
// This method performs an operation with the given operation and the second operand. 
// After the operation is performed, the result is written to lastOperand
// ----------------------------------------------------------------------------------------------------
- (void)performOperation:(BCOperator)operation withOperand:(NSNumber*)operand andStoreResultInHistory:(BOOL)shouldStoreResult;
{
	NSNumber *result;
    switch (operation) {
        case BCOperatorAddition:
            result = [NSNumber numberWithDouble:([self.lastOperand doubleValue] + [operand doubleValue])];
            self.lastOperand = result;
            break;
        case BCOperatorSubtraction:
            result = [NSNumber numberWithDouble:([self.lastOperand doubleValue] - [operand doubleValue])];
            self.lastOperand = result;
            break;
        case BCOperatorMultiplication:
            result = [NSNumber numberWithDouble:([self.lastOperand doubleValue] * [operand doubleValue])];
            self.lastOperand = result;
            break;
        case BCOperatorDivision:
            if ([operand doubleValue] == 0) {
                result = [NSDecimalNumber notANumber];
            }
            else {
                result = [NSNumber numberWithDouble:([self.lastOperand doubleValue] / [operand doubleValue])];
            }
            self.lastOperand = result;
            break;
        default:
            break;
    }
    
    // store result in the history
    if (shouldStoreResult) {
        BOOL resultIsNumber = ![result isEqualToNumber:[NSDecimalNumber notANumber]];
        if (resultIsNumber) {
            // at this point, KVO fires. Result manager is informed
            self.lastResult = result;
        }
    }
	
	[self notifyDelegateOfResult:result];
}

// ----------------------------------------------------------------------------------------------------
// This method clears everything (for the moment)
// ----------------------------------------------------------------------------------------------------
- (void)reset;
{
	self.lastOperand = [NSNumber numberWithInt:0];
}

// ----------------------------------------------------------------------------------------------------
// The following method is shamelessly modified from http://www.programmingsimplified.com/c/source-code/c-program-for-prime-number
// ----------------------------------------------------------------------------------------------------
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

- (void) goToPreviousResult;
{
    // get the next result from history
    NSNumber *previousResult = [self.resultManager getPreviousResult];
    
    [self setFirstOperand:previousResult];
    [self notifyDelegateOfResult:previousResult];
}

-(void) goToNextResult;
{
    // get the next result from history
    NSNumber *nextResult = [self.resultManager getNextResult];
    
    [self setFirstOperand:nextResult];
    [self notifyDelegateOfResult:nextResult];
}

- (NSUInteger) currentPositionInHistory;
{
    NSUInteger currentPositionInHistory;
    currentPositionInHistory = [self.resultManager currentPositionInHistory];
    return currentPositionInHistory;
}

// ----------------------------------------------------------------------------------------------------
// Returns the current size of the result history
// ----------------------------------------------------------------------------------------------------
- (NSUInteger) historySize;
{
    return [self.resultManager historySize];
}

// ----------------------------------------------------------------------------------------------------
// Saves the state of the calculator to NSUserDefaults
// ----------------------------------------------------------------------------------------------------
- (void) saveState;
{
    [[NSUserDefaults standardUserDefaults] setObject:self.lastResult forKey:@"lastResult"];
    [[NSUserDefaults standardUserDefaults] setObject:self.lastOperand forKey:@"lastOperand"];
    
    // forward saveState to result manager
    [self.resultManager saveState];

}

- (void) restoreState;
{
    self.lastResult     = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastResult"];
    self.lastOperand    = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastOperand"];
    
    // forward restore to result manager
    [self.resultManager restoreState];
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
