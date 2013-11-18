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
    BCOperator currentOperation;
    BCButtonType lastPressedButtonType;
	BOOL textFieldShouldBeCleared;
    UIButton *lastToggledOperator;
    NSUInteger lastPressedOperatorTag;
    
    // used for keeping track how many decimal points should be shown (swiping)
    int decimalPointPrecision;
    
    // saves exact value so that decreasing and increasing decimalPoint counter doesn't loose precision
    double currentResult;
    double tentativeOperand;
    
    
    
}

@property (weak, nonatomic) IBOutlet UIButton *plusButton;
@property (weak, nonatomic) IBOutlet UIButton *minusButton;
@property (weak, nonatomic) IBOutlet UIButton *multButton;
@property (weak, nonatomic) IBOutlet UIButton *divButton;
@property (weak, nonatomic) IBOutlet UILabel *leftArrowLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightArrowLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) IBOutlet UILabel *checkingPrimeLabel;


@end

@implementation ViewController

#pragma mark - Object Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.calculator = [[BasicCalculator alloc] init];
    
    self.calculator.delegate = self;
    
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
    
    // hide the spinner at start
    self.spinner.hidden = YES;
    
    
    [self restoreState];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - handle gestures

// ----------------------------------------------------------------------------------------------------
// Handles the swiping gesture
// ----------------------------------------------------------------------------------------------------
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
            
            // swiped left: "I want more decimal points"
        case UISwipeGestureRecognizerDirectionLeft:
        {
            NSLog(@"left swipe");
            if (decimalPointPrecision < 6) decimalPointPrecision++;
            break;
        }
            
            // swiped right: "I want less decimal points"
        case UISwipeGestureRecognizerDirectionRight:
        {
            NSLog(@"right swipe");
            if (decimalPointPrecision > 0) decimalPointPrecision--;
            break;
        }
        default:
            break;
    }
    
    // first restore textfield with full decimal precision, then apply appropriate rounding
    if (lastPressedButtonType == NumberButton) {
        self.numberTextField.text = [NSString stringWithFormat:@"%f", tentativeOperand];
    }
    else {
        self.numberTextField.text = [NSString stringWithFormat:@"%f", currentResult];
    }
    [self applyRoundingToTextfield];
}

#pragma mark - UI response operations


// ----------------------------------------------------------------------------------------------------
// Gets called when an operation button is pressed.
// ----------------------------------------------------------------------------------------------------
- (IBAction)operationButtonPressed:(UIButton *)sender;
{
    // toggle the selected operation button
    [self deselectAllButtons];
    sender.selected = YES;
    lastToggledOperator = sender;
    lastPressedOperatorTag = lastToggledOperator.tag;
    
    // A new sum should be started
    if ([self.calculator.lastOperand doubleValue] == 0) {
        // set first operand to Number in textfield
        NSNumber *firstOperand = [NSNumber numberWithDouble:[self.numberTextField.text doubleValue]];
        [self.calculator setFirstOperand:firstOperand];
        currentOperation = [self getOperatorFromButton:sender];
    }
    
    
    // when an operation should be performed with the previous result
	else if (lastPressedButtonType == NumberButton)	{
        NSNumber *secondOperand = [NSNumber numberWithDouble:[self.numberTextField.text doubleValue]];
        [self.calculator performOperation:currentOperation withOperand:secondOperand andStoreResultInHistory:NO];
	}
    
    currentOperation = [self getOperatorFromButton:sender];
    
	textFieldShouldBeCleared = YES;
    lastPressedButtonType = OperatorButton;
}

// ----------------------------------------------------------------------------------------------------
// Gets called when the result button is pressed
// ----------------------------------------------------------------------------------------------------
- (IBAction)resultButtonPressed:(id)sender {
    
    NSNumber *secondOperand = [NSNumber numberWithDouble:[self.numberTextField.text doubleValue]];
    
    // make sure multiple consecutive result button pressing is ignored
    if (lastPressedButtonType != ResultButton) {
        
        [self.calculator performOperation:currentOperation withOperand:secondOperand andStoreResultInHistory:YES];
        
        [self resetCalculator];
    }
    
    lastPressedButtonType = ResultButton;
    [self updateArrowLabels];
    
}


// ----------------------------------------------------------------------------------------------------
// Gets called when a number is entered
// ----------------------------------------------------------------------------------------------------
- (IBAction)numberEntered:(UIButton *)sender {
    
    // deselect all the operator buttons
    [self deselectAllButtons];
    
	// If it's a new sum, just replace it with the pressed number
	if (textFieldShouldBeCleared) {
		self.numberTextField.text = [NSString stringWithFormat:@"%i",sender.tag];
		textFieldShouldBeCleared = NO;
	}
	// otherwise, append the pressed number to what is already in the textField
	else {
		self.numberTextField.text = [self.numberTextField.text stringByAppendingFormat:@"%i", sender.tag];
	}
    
    // this makes sure the full number is stored (e.g. 5.65656) and can be restored after swiping of decimal points.
    tentativeOperand = [self.numberTextField.text doubleValue];
    
    // remove unnecessary leading zeros
    self.numberTextField.text = [NSString stringByRemovingLeadingZerosFromString:self.numberTextField.text];
    
    lastPressedButtonType = NumberButton;
}


// ----------------------------------------------------------------------------------------------------
// Gets called when a decimal point is entered
// ----------------------------------------------------------------------------------------------------
- (IBAction)decimalPointEntered:(UIButton *) sender;
{
    if (lastPressedButtonType != PointButton) {
        self.numberTextField.text = [self.numberTextField.text stringByAppendingString:@"."];
    }
    lastPressedButtonType = PointButton;
    //    [self saveState];
}


// ----------------------------------------------------------------------------------------------------
// Gets called when C is pressed
// ----------------------------------------------------------------------------------------------------
- (IBAction)clearDisplay:(UIButton*)sender {
    lastPressedButtonType = ClearButton;
    
    // clear the first Operand
    [self.calculator setFirstOperand:0];
    currentResult = 0;
	currentOperation = BCOperatorNoOperation;
    
	self.numberTextField.text = @"0";
    [self deselectAllButtons];
}


// ----------------------------------------------------------------------------------------------------
// Gets called when an arrow button is pressed
// ----------------------------------------------------------------------------------------------------
- (IBAction)arrowPressed:(UIButton*)sender
{
    // right arrow
    if (sender.tag == 15) {
        [self.calculator goToNextResult];
    }
    
    // left arrow
    else {
        [self.calculator goToPreviousResult];
    }
    
    [self updateArrowLabels];
}


#pragma mark - General Methods
- (void) resetCalculator;
{
    // Reset the internal state
    currentOperation = BCOperatorNoOperation;
    [self.calculator reset];
    lastToggledOperator.selected = NO;
    //    [self saveState];
    textFieldShouldBeCleared = YES;
}

// ----------------------------------------------------------------------------------------------------
// applies the appropriate rounding to the textfield
// ----------------------------------------------------------------------------------------------------
- (void) applyRoundingToTextfield;
{
    switch (decimalPointPrecision) {
        case 0:
            self.numberTextField.text = [NSString stringWithFormat:@"%.0f", [self.numberTextField.text doubleValue]];
            break;
        case 1:
            self.numberTextField.text = [NSString stringWithFormat:@"%.1f", [self.numberTextField.text doubleValue]];
            break;
        case 2:
            self.numberTextField.text = [NSString stringWithFormat:@"%.2f", [self.numberTextField.text doubleValue]];
            break;
        case 3:
            self.numberTextField.text = [NSString stringWithFormat:@"%.3f", [self.numberTextField.text doubleValue]];
            break;
        case 4:
            self.numberTextField.text = [NSString stringWithFormat:@"%.4f", [self.numberTextField.text doubleValue]];
            break;
        case 5:
            self.numberTextField.text = [NSString stringWithFormat:@"%.5f", [self.numberTextField.text doubleValue]];
            break;
        case 6:
            self.numberTextField.text = [NSString stringWithFormat:@"%.6f", [self.numberTextField.text doubleValue]];
            break;
        default:
            break;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@", self.numberTextField.text] forKey:@"NumberTextField"];
}

// ----------------------------------------------------------------------------------------------------
// Gets called before app is terminated, saves all relevant values, and forwards to calculator
// ----------------------------------------------------------------------------------------------------
- (void) saveState;
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:currentResult] forKey:@"CurrentResult"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:tentativeOperand] forKey:@"TentativeOperand"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@", self.numberTextField.text] forKey:@"NumberTextField"];
    [[NSUserDefaults standardUserDefaults] setInteger:lastPressedOperatorTag forKey:@"LastPressedOperatorTag"];
    [[NSUserDefaults standardUserDefaults] setInteger:decimalPointPrecision forKey:@"decimalPointPrecision"];
    [[NSUserDefaults standardUserDefaults] setInteger:lastPressedButtonType forKey:@"LastPressedButtonType"];
    [[NSUserDefaults standardUserDefaults] setInteger:currentOperation forKey:@"CurrentOperation"];
    
    [[NSUserDefaults standardUserDefaults] setBool:lastToggledOperator.selected forKey:@"LastToggledOperatorSelected"];
    
    [self.calculator saveState];
}

// ----------------------------------------------------------------------------------------------------
// Gets called when app is resumed, restores all relevant values, and forwards to calculator
// ----------------------------------------------------------------------------------------------------
- (void) restoreState;
{
    currentResult               = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentResult"];
    tentativeOperand            = [[NSUserDefaults standardUserDefaults] integerForKey:@"TentativeOperand"];
    self.numberTextField.text   = [[NSUserDefaults standardUserDefaults] stringForKey:@"NumberTextField"];
    lastPressedOperatorTag      = [[NSUserDefaults standardUserDefaults] integerForKey:@"LastPressedOperatorTag"];
    decimalPointPrecision       = [[NSUserDefaults standardUserDefaults] integerForKey:@"decimalPointPrecision"];
    lastPressedButtonType       = [[NSUserDefaults standardUserDefaults] integerForKey:@"LastPressedButtonType"];
    currentOperation            = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentOperation"];
    
    // restore the state of the operators, if they were pressed before closing.
    BOOL anOperatorWasPressed = [[NSUserDefaults standardUserDefaults] boolForKey:@"LastToggledOperatorSelected"];
    if (anOperatorWasPressed) {
        switch (lastPressedOperatorTag) {
            case 11:
                self.plusButton.selected = YES;
                currentOperation = BCOperatorAddition;
                break;
            case 12:
                self.minusButton.selected = YES;
                currentOperation = BCOperatorSubtraction;
                break;
            case 13:
                self.multButton.selected = YES;
                currentOperation = BCOperatorMultiplication;
                break;
            case 14:
                self.divButton.selected = YES;
                currentOperation = BCOperatorDivision;
                break;
            default:
                break;
        }
        textFieldShouldBeCleared = YES;
    }
    
    [self.calculator restoreState];
    
    [self updateArrowLabels];
}

// ----------------------------------------------------------------------------------------------------
// Deselects all the buttons
// ----------------------------------------------------------------------------------------------------
- (void) deselectAllButtons;
{
    lastToggledOperator.selected = NO;
    self.minusButton.selected = NO;
    self.plusButton.selected = NO;
    self.multButton.selected = NO;
    self.divButton.selected = NO;
}

// ----------------------------------------------------------------------------------------------------
// Update the arrow labels with appropriate values
// ----------------------------------------------------------------------------------------------------
- (void) updateArrowLabels;
{
    NSUInteger currentPositionInHistory = [self.calculator currentPositionInHistory];
    
    //NSLog(@"Current pos in history: %d", currentPositionInHistory);
    self.leftArrowLabel.text = [NSString stringWithFormat:@"%i", currentPositionInHistory];
    self.rightArrowLabel.text = [NSString stringWithFormat:@"%i", [self.calculator historySize] - 1 - currentPositionInHistory];
    if ([self.calculator historySize] == 0)
        self.rightArrowLabel.text = [NSString stringWithFormat:@"%i", 0];
}

- (BOOL)prefersStatusBarHidden;
{
    return YES;
}


// ----------------------------------------------------------------------------------------------------
// Detects the operator from the button tag
// ----------------------------------------------------------------------------------------------------
- (BCOperator) getOperatorFromButton: (UIButton *)theButton;
{
    BCOperator theOperator = BCOperatorNoOperation;
    switch (theButton.tag) {
        case OP_ADD:
            theOperator = BCOperatorAddition;
            break;
        case OP_SUB:
            theOperator = BCOperatorSubtraction;
            break;
        case OP_MULT:
            theOperator = BCOperatorMultiplication;
            break;
        case OP_DIV:
            theOperator = BCOperatorDivision;
            break;
        default:
            break;
    }
    return theOperator;
}

#pragma mark - Basic calculator delegate methods
// ----------------------------------------------------------------------------------------------------
// called by the BasicCalculator whenever it has finished calculating a result
// ----------------------------------------------------------------------------------------------------
- (void) operationDidCompleteWithResult:(NSNumber *)result;
{
    // keep this value with full precision, so swiping can be performed without precision loss
    currentResult = [result doubleValue];
    
    // update textfield with the result;
    BOOL resultIsNaN = [result isEqualToNumber:[NSDecimalNumber notANumber]];
    if (resultIsNaN) {
        self.numberTextField.text = @"Error";
        [self resetCalculator];
    }
    else {
        self.numberTextField.text = [NSString stringWithFormat:@"%@", result];
        // apply appropriate rounding to textfield
        [self applyRoundingToTextfield];
    }
}

#pragma mark - Prime checker delegate methods
- (void)didPrimeCheckNumber:(NSNumber *)theNumber result:(BOOL)theIsPrime
{
    if (theIsPrime)
        self.checkingPrimeLabel.text = [NSString stringWithFormat:@"%d is a prime.", (NSInteger)([theNumber floatValue] + 0.5f)];
    else
        self.checkingPrimeLabel.text = [NSString stringWithFormat:@"%d is not a prime.", (NSInteger)([theNumber floatValue] + 0.5f)];
    
    self.spinner.hidden = YES;
    [self.spinner stopAnimating];
}

- (void)willPrimeCheckNumber:(NSNumber *)theNumber
{
    self.checkingPrimeLabel.text = [NSString stringWithFormat:@"Checking if %d is a prime", (NSInteger)([theNumber floatValue] + 0.5f)];
    self.spinner.hidden = NO;
    [self.spinner startAnimating];
}

@end
