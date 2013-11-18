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
{
    NSOperationQueue *myQueue;
    NSMutableArray *operationQueues;
}

- (id)init
{
	self = [super init];
	if (self != nil) {
		self.lastOperand = [NSNumber numberWithInt:0];
		self.delegate = nil;
        self.lastResult = [[NSNumber alloc] init];
        self.resultManager = [[ResultManager alloc] init];
        
        // add observer
        [self addObserver:self.resultManager forKeyPath:@"lastResult"
                             options:NSKeyValueObservingOptionNew
                             context:nil];
        
        //[self restoreState];
        
        
        // Initialize the queue and set the maximum concurrent operation limit
        myQueue = [[NSOperationQueue alloc] init];
        myQueue.name = @"Check Prime Queue";
        myQueue.MaxConcurrentOperationCount = 3;
        
        operationQueues = [[NSMutableArray alloc] init];
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
        BOOL resultIsNumber = result && ![result isEqualToNumber:[NSDecimalNumber notANumber]] && ![result isEqual:[NSNull null]];
        if (resultIsNumber) {
            
            NSLog(@"Store number: %@", result);
            
            // at this point, KVO fires. Result manager is informed
            self.lastResult = result;
        }
    }
	
	[self notifyDelegateOfResult:result];
	
    [_delegate willPrimeCheckNumber:self.lastOperand];
    //[self checkByGCD];
    //[self checkByOpQueue];
    //BOOL res = [self checkPrimeAllowCancel:[self.lastOperand integerValue]];
    [self checkPerserveOrder];
    
    
}

// ----------------------------------------------------------------------------------------------------
// This method clears everything (for the moment)
// ----------------------------------------------------------------------------------------------------
- (void)reset;
{
	self.lastOperand = [NSNumber numberWithInt:0];
}


// ----------------------------------------------------------------------------------------------------
// Get the previous result from the result manager
// ----------------------------------------------------------------------------------------------------
- (void) goToPreviousResult;
{
    // get the next result from history
    NSNumber *previousResult = [self.resultManager getPreviousResult];
    // proceed only if the result is not nil
    if (previousResult)
    {
        [self setFirstOperand:previousResult];
        [self notifyDelegateOfResult:previousResult];
    }
}


// ----------------------------------------------------------------------------------------------------
// Get the next result from the result manager
// ----------------------------------------------------------------------------------------------------
-(void) goToNextResult;
{
    // get the next result from history
    NSNumber *nextResult = [self.resultManager getNextResult];
    // proceed only if the result is not nil
    if (nextResult)
    {
        [self setFirstOperand:nextResult];
        [self notifyDelegateOfResult:nextResult];
    }
}


// ----------------------------------------------------------------------------------------------------
// Get the current position in history from the result manager.
// ----------------------------------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------------------------------
// Restore the state of the calculator from NSUserDefaults
// ----------------------------------------------------------------------------------------------------
- (void) restoreState;
{
    self.lastResult     = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastResult"];
    self.lastOperand    = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastOperand"];
    
    // forward restore to result manager
    [self.resultManager restoreState];
}


// ----------------------------------------------------------------------------------------------------
// Notify the delegate of the result
// ----------------------------------------------------------------------------------------------------
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
        sleep(1);    // uncomment this line to make the execution significantly longer for a more dramatic effect :D
        
    }
    if (checkValue == theInteger)
    {
        result = YES;
    }
    
    return result;
}


// -----------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark part 2
 // NOTE: you may change the signature of the following methods. Just keep the given name as a substring.
// -----------------------------------------------------------------------------------------------------------------


- (void)checkByGCD;
{
    // Task 2.2
    //NSLog(@"Queue: lastOperand: %@", self.lastOperand);
    __block NSNumber* lastOperand = [self.lastOperand copy];
    
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
            // Check prime asynchronously
            BOOL result = [self checkPrime:[lastOperand integerValue]];
            // Notify the delegate in the main thread since UI updates must be perfomed there.
            dispatch_sync(dispatch_get_main_queue(), ^{
                // Now call the delegate method with the result. If the delegate is nil, this will just do nothing.
                if (_delegate != nil) {
                    if ([_delegate respondsToSelector:@selector(didPrimeCheckNumber:result:)])
                    {
                        [_delegate didPrimeCheckNumber:lastOperand result:result];
                    }
                    else {
                        NSLog(@"WARNING: the BasicCalculator delegate does not implement didPrimeCheckNumber:");
                    }
                }
                else {
                    NSLog(@"WARNING: the BasicCalculator delegate is nil");
                }
            });
    });
}

- (void)checkByOpQueue;
{
    // Task 2.3
    // Cancel all previous operations before performing a new one
    [myQueue cancelAllOperations];
    
    //NSLog(@"Queue: lastOperand: %@", self.lastOperand);
    __block NSNumber* lastOperand = [self.lastOperand copy];
    // Add an operation as a block to a queue
    [myQueue addOperationWithBlock: ^ {
        BOOL result = [self checkPrime:[lastOperand integerValue]];
        // Notify the delegate in the main thread since UI updates must be perfomed there.
        // Now call the delegate method with the result. If the delegate is nil, this will just do nothing.
        if (_delegate != nil) {
            if ([_delegate respondsToSelector:@selector(didPrimeCheckNumber:result:)])
            {
                [_delegate didPrimeCheckNumber:lastOperand result:result];
            }
            else {
                NSLog(@"WARNING: the BasicCalculator delegate does not implement didPrimeCheckNumber:");
            }
        }
        else {
            NSLog(@"WARNING: the BasicCalculator delegate is nil");
        }
    }];
}


- (BOOL)checkPrimeAllowCancel:(NSInteger)theInteger;
{
    NSOperation *executingOperation = [[myQueue operations] lastObject];
    [executingOperation cancel];
    __block BOOL result;
    NSOperation *operation = [[NSOperation alloc] init];
    operation.completionBlock = ^{
        result = [self checkPrime:theInteger];
        if (_delegate != nil) {
            if ([_delegate respondsToSelector:@selector(didPrimeCheckNumber:result:)])
            {
                [_delegate didPrimeCheckNumber:@(theInteger) result:result];
            }
            else {
                NSLog(@"WARNING: the BasicCalculator delegate does not implement didPrimeCheckNumber:");
            }
        }
        else {
            NSLog(@"WARNING: the BasicCalculator delegate is nil");
        }
    };
    [myQueue addOperation:operation];
    
    return YES;
}

- (void)checkPerserveOrder;
{
    // Task 2.5 (extra credit)
    
    __block NSNumber* lastOperand = [self.lastOperand copy];
    NSOperation *operation = [[NSOperation alloc] init];
    operation.completionBlock = ^{
            BOOL result = [self checkPrime:[lastOperand integerValue]];
            // Notify the delegate in the main thread since UI updates must be perfomed there.
            // Now call the delegate method with the result. If the delegate is nil, this will just do nothing.
        
        NSLog(@"The number %d is %@ prime", [lastOperand integerValue], result ? @"a" : @"not a"  );
            if (_delegate != nil) {
                if ([_delegate respondsToSelector:@selector(didPrimeCheckNumber:result:)])
                {
                    [_delegate didPrimeCheckNumber:lastOperand result:result];
                }
            else {
                NSLog(@"WARNING: the BasicCalculator delegate does not implement didPrimeCheckNumber:");
            }
        }
        else {
            NSLog(@"WARNING: the BasicCalculator delegate is nil");
        }
    };
    // add dependencies
    for (NSOperationQueue* q in operationQueues)
    {
         for(NSOperation* op in q.operations)
         {
             [operation addDependency:op];
         }
    }
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    queue.MaxConcurrentOperationCount = 1;
    [queue addOperation:operation];
    [operationQueues addObject:queue];
    
}

@end
