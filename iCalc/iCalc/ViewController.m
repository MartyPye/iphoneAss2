//
//  ViewController.m
//  iCalc
//
//  Created by Florian Heller on 10/5/12.
//  Copyright (c) 2012 Florian Heller. All rights reserved.
//

// Define operation identifiers
#define OP_NOOP	0
#define OP_ADD	11
#define OP_SUB	12
#define OP_MULT 13
#define OP_DIV  14

#import "ViewController.h"
#import "NSString+NSStringFormattingAdditions.h"

@interface ViewController ()
{
	// The following variables do not need to be exposed in the public interface
	// that's why we define them in this class extension in the implementation file.
	double firstOperand;
	unsigned char currentOperation;
	BOOL textFieldShouldBeCleared;
    BOOL lastButtonPressWasPoint;
    BOOL lastButtonPressWasOperator;
    BOOL lastButtonPressWasNumber;
    BOOL lastButtonPressWasResult;
    UIButton *lastToggledOperator;
    // used for the swipe gesture
    NSUInteger decimalPointCounter;
    // saves exact value so that decreasing and increasing decimalPoint counter doesn't loose precision
    double currentResult;
    
}

@end

@implementation ViewController

#pragma mark - Object Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
	currentOperation = OP_NOOP;
	textFieldShouldBeCleared = NO;
    
    // swipe gesture recognizers
    // NOTE: Observe how target-action is established in the code below. This is equivalent to dragging connections in the Interface Builder.
    UISwipeGestureRecognizer *leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipeRecognizer.numberOfTouchesRequired = 1;
    
    UISwipeGestureRecognizer *rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] init];
    rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    rightSwipeRecognizer.numberOfTouchesRequired = 1;
    [rightSwipeRecognizer addTarget:self action:@selector(handleGesture:)];
    
    [self.view addGestureRecognizer:leftSwipeRecognizer];
    [self.view addGestureRecognizer:rightSwipeRecognizer];
    
}


#pragma mark - handle gestures
- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer;
{
    // ignore other gesture recognizer
    if (![gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]])
    {
        return;
    }
    
    UISwipeGestureRecognizer *swipeRecognizer = (UISwipeGestureRecognizer *)gestureRecognizer;
    
    switch (swipeRecognizer.direction)
    {
        case UISwipeGestureRecognizerDirectionLeft:
        {
            NSLog(@"left swipe");
            if (decimalPointCounter < 6) decimalPointCounter++;
            break;
        }
        case UISwipeGestureRecognizerDirectionRight:
        {
            NSLog(@"right swipe");
            if (decimalPointCounter > 0) decimalPointCounter--;
            break;
        }
        default:
            break;
    }
    
    [self updateTextField];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - UI response operations
/*	This method get's called whenever an operation button is pressed
 *	The sender object is a pointer to the calling button in this case. 
 *	This way, you can easily change the buttons color or other properties
 */
- (IBAction)operationButtonPressed:(UIButton *)sender;
{
    // toggle the selected operation button
    sender.selected = YES;
    if (lastToggledOperator != nil && lastToggledOperator != sender) {
        lastToggledOperator.selected = NO;
    }
    lastToggledOperator = sender;
	// Have a look at the tag-property of the buttons calling this method
	
	// Once a button is pressed, we check if the first operand is zero
	// If so, we can start a new calculation, otherwise, we replace the first operand with the result of the operation
    lastButtonPressWasPoint = NO;
    lastButtonPressWasResult = NO;
	if (firstOperand == 0. && currentResult == 0.)
	{
		firstOperand = [self.numberTextField.text doubleValue];
		currentOperation = sender.tag;
	}
    
    else if (firstOperand == 0.)
    {
        firstOperand = currentResult;
		currentOperation = sender.tag;
    }
    
    // only execute operation if previous button pressed was a number
	else if (lastButtonPressWasNumber)
	{
        if (!([self.numberTextField.text doubleValue] == 0 && currentOperation == OP_DIV)) {
            firstOperand = [self executeOperation:currentOperation withArgument:firstOperand andSecondArgument:[self.numberTextField.text doubleValue]];
            currentResult = firstOperand;
            currentOperation = sender.tag;
            [self updateTextField];
//            self.numberTextField.text = [NSString stringWithFormat:@"%.6f",firstOperand];
//            self.numberTextField.text = [NSString removeDanglingZerosFromDecimalString:self.numberTextField.text];
        }
        
        else {
            self.numberTextField.text = @"Error";
            [self resetCalculator];
        }
        
        lastButtonPressWasNumber = NO;
	}
    
    else if (lastButtonPressWasOperator) {
        currentOperation = sender.tag;
    }
	textFieldShouldBeCleared = YES;
    lastButtonPressWasOperator = YES;
}

- (IBAction)resultButtonPressed:(id)sender {
	
    lastButtonPressWasNumber = NO;
    lastButtonPressWasOperator = NO;
	// Just calculate the result
    if (!lastButtonPressWasResult) {
        if (!([self.numberTextField.text doubleValue] == 0 && currentOperation == OP_DIV)) {
            double result = [self executeOperation:currentOperation withArgument:firstOperand andSecondArgument:[self.numberTextField.text doubleValue]];
            currentResult = result;
            [self updateTextField];
//            self.numberTextField.text = [NSString stringWithFormat:@"%.6f",result];
            // remove dangling decimal zeros
            // self.numberTextField.text = [NSString removeDanglingZerosFromDecimalString:self.numberTextField.text];
        }
        
        else {
            self.numberTextField.text = @"Error";
        }
        
        [self resetCalculator];
    }

}

- (IBAction)numberEntered:(UIButton *)sender {
    
    lastButtonPressWasOperator = NO;
    lastButtonPressWasResult = NO;
	// If the textField is to be cleared, just replace it with the pressed number
	if (textFieldShouldBeCleared)
	{
		self.numberTextField.text = [NSString stringWithFormat:@"%i",sender.tag];
		textFieldShouldBeCleared = NO;
	}
	// otherwise, append the pressed number to what is already in the textField
	else {
		self.numberTextField.text = [self.numberTextField.text stringByAppendingFormat:@"%i", sender.tag];
	}
    
    // remove unnecessary leading zeros
    self.numberTextField.text = [NSString removeLeadingZerosFromString:self.numberTextField.text];
    lastButtonPressWasNumber = YES;
}

- (IBAction)decimalPointEntered:(UIButton *) sender;
{
    lastButtonPressWasOperator = NO;
    lastButtonPressWasNumber = NO;
    if (!lastButtonPressWasPoint) {
        self.numberTextField.text = [self.numberTextField.text stringByAppendingString:@"."];
        lastButtonPressWasPoint = YES;
    }
}

// The parameter type id says that any object can be sender of this method.
// As we do not need the pointer to the clear button here, it is not really important.
- (IBAction)clearDisplay:(id)sender {
    lastButtonPressWasNumber = NO;
    lastButtonPressWasOperator = NO;
    lastButtonPressWasPoint = NO;
	firstOperand = 0;
    currentResult = 0;
	currentOperation = OP_NOOP;
	self.numberTextField.text = @"0";
    lastToggledOperator.selected = NO;
}

#pragma mark - General Methods
// This method returns the result of the specified operation
// It is placed here since it is needed in two other methods
- (double)executeOperation:(char)operation withArgument:(double)firstArgument andSecondArgument:(double)secondArgument;
{
	switch (operation) {
		case OP_ADD:
			return firstArgument + secondArgument;
			break;
		case OP_SUB:
			return firstArgument - secondArgument;
            break;
        case OP_MULT:
            return firstArgument * secondArgument;
            break;
        case OP_DIV:
            return firstArgument / secondArgument;
		default:
			return NAN;
			break;
	}
}

- (void) resetCalculator;
{
    // Reset the internal state
    currentOperation = OP_NOOP;
    firstOperand = 0.;
    lastToggledOperator.selected = NO;
    textFieldShouldBeCleared = YES;
    lastButtonPressWasResult = YES;
}

- (void) updateTextField;
{
    switch (decimalPointCounter) {
        case 0:
            self.numberTextField.text = [NSString stringWithFormat:@"%.0f", currentResult];
            break;
        case 1:
            self.numberTextField.text = [NSString stringWithFormat:@"%.1f", currentResult];
            break;
        case 2:
            self.numberTextField.text = [NSString stringWithFormat:@"%.2f", currentResult];
            break;
        case 3:
            self.numberTextField.text = [NSString stringWithFormat:@"%.3f", currentResult];
            break;
        case 4:
            self.numberTextField.text = [NSString stringWithFormat:@"%.4f", currentResult];
            break;
        case 5:
            self.numberTextField.text = [NSString stringWithFormat:@"%.5f", currentResult];
            break;
        case 6:
            self.numberTextField.text = [NSString stringWithFormat:@"%.6f", currentResult];
            break;
        default:
            break;
    }
}

- (BOOL)prefersStatusBarHidden;
{
    return YES;
}
@end
