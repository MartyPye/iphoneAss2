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
    NSUInteger lastPressedOperatorTag;
    NSMutableArray *historyOfResults;
    NSUInteger posInHistory;
    double currentValueInTextfield;
    
}
@property (weak, nonatomic) IBOutlet UIButton *plusButton;
@property (weak, nonatomic) IBOutlet UIButton *minusButton;
@property (weak, nonatomic) IBOutlet UIButton *multButton;
@property (weak, nonatomic) IBOutlet UIButton *divButton;
@property (weak, nonatomic) IBOutlet UILabel *leftArrowLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightArrowLabel;

@end

@implementation ViewController

#pragma mark - Object Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
//	currentOperation = OP_NOOP;
//	textFieldShouldBeCleared = NO;
    
    currentResult = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentResult"];
    self.numberTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"NumberTextField"];
    BOOL anOperatorWasPressed = [[NSUserDefaults standardUserDefaults] boolForKey:@"LastToggledOperatorSelected"];
    lastPressedOperatorTag = [[NSUserDefaults standardUserDefaults] integerForKey:@"LastPressedOperatorTag"];
    
    
    NSString *errorDesc = nil;
    NSPropertyListFormat format;
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:@"Data.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:@"Data" ofType:@"plist"];
    }
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                          propertyListFromData:plistXML
                                          mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                          format:&format
                                          errorDescription:&errorDesc];
    if (!temp) {
        NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
    }
    historyOfResults = (NSMutableArray*)[temp objectForKey:@"history"];
    NSNumber* num = [temp objectForKey:@"posInHistory"];
    posInHistory = [num integerValue];
    
    if (!historyOfResults)
        historyOfResults = [NSMutableArray arrayWithCapacity:10];
    
    //NSLog(@"pos: %d", posInHistory);
    //NSLog(@"Elements: %@", historyOfResults);
    
    [self updateArrowLabels];
    
    if (anOperatorWasPressed) {
        switch (lastPressedOperatorTag) {
            case 11:
                self.plusButton.selected = YES;
                currentOperation = OP_ADD;
                break;
            case 12:
                self.minusButton.selected = YES;
                currentOperation = OP_SUB;
                break;
            case 13:
                self.multButton.selected = YES;
                currentOperation = OP_MULT;
                break;
            case 14:
                self.divButton.selected = YES;
                currentOperation = OP_DIV;
                break;
            default:
                break;
        }
        textFieldShouldBeCleared = YES;
    }
    firstOperand = [[NSUserDefaults standardUserDefaults] doubleForKey:@"FirstOperand"];
    // load the amount of decimal points (user preference)
    decimalPointCounter = [[NSUserDefaults standardUserDefaults] integerForKey:@"AmountOfDecimalPoints"];
    
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
    if (lastButtonPressWasNumber) {
        self.numberTextField.text = [NSString stringWithFormat:@"%f", currentValueInTextfield];
    }
    else {
        self.numberTextField.text = [NSString stringWithFormat:@"%f", currentResult];
    }
    [self updateTextField];
    
    // register decimal point count in user defaults
    [self saveState];
    
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

    [self deselectAllButtons];
    
    sender.selected = YES;
    lastToggledOperator = sender;
    lastPressedOperatorTag = lastToggledOperator.tag;
    [self saveState];
	// Have a look at the tag-property of the buttons calling this method
	
	// Once a button is pressed, we check if the first operand is zero
	// If so, we can start a new calculation, otherwise, we replace the first operand with the result of the operation
    lastButtonPressWasPoint = NO;
    lastButtonPressWasResult = NO;
	if (firstOperand == 0.)
	{
		firstOperand = [self.numberTextField.text doubleValue];
		currentOperation = sender.tag;
	}
    
//    else if (firstOperand == 0.)
//    {
//        firstOperand = currentResult;
//		currentOperation = sender.tag;
//    }
    
    // only execute operation if previous button pressed was a number
	else if (lastButtonPressWasNumber)
	{
        if (!([self.numberTextField.text doubleValue] == 0 && currentOperation == OP_DIV)) {
            firstOperand = [self executeOperation:currentOperation withArgument:firstOperand andSecondArgument:[self.numberTextField.text doubleValue]];
            currentResult = firstOperand;
            currentOperation = sender.tag;
            self.numberTextField.text = [NSString stringWithFormat:@"%f", currentResult];
//            self.numberTextField.text = [NSString stringWithFormat:@"%.6f",firstOperand];
//            self.numberTextField.text = [NSString removeDanglingZerosFromDecimalString:self.numberTextField.text];
        }
        
        else {
            self.numberTextField.text = @"Error";
            [self resetCalculator];
        }
        
        
	}
    
    else if (lastButtonPressWasOperator) {
        currentOperation = sender.tag;
    }
    
    [self saveState];
    lastButtonPressWasNumber = NO;
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
            [self addResultToHistory:currentResult];
            [self saveState];
            self.numberTextField.text = [NSString stringWithFormat:@"%f", currentResult];
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
    
    [self updateArrowLabels];

}

- (IBAction)numberEntered:(UIButton *)sender {
    
    lastButtonPressWasOperator = NO;
    lastButtonPressWasResult = NO;
    [self deselectAllButtons];
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
    currentValueInTextfield = [self.numberTextField.text doubleValue];
    // remove unnecessary leading zeros
    self.numberTextField.text = [NSString removeLeadingZerosFromString:self.numberTextField.text];
    [self saveState];
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
    [self saveState];
}

// The parameter type id says that any object can be sender of this method.
// As we do not need the pointer to the clear button here, it is not really important.
- (IBAction)clearDisplay:(UIButton*)sender {
    lastButtonPressWasNumber = NO;
    lastButtonPressWasOperator = NO;
    lastButtonPressWasPoint = NO;
	firstOperand = 0;
    currentResult = 0;
	currentOperation = OP_NOOP;
	self.numberTextField.text = @"0";
    lastToggledOperator.selected = NO;
    self.plusButton.selected = NO;
    self.minusButton.selected = NO;
    self.multButton.selected = NO;
    self.divButton.selected = NO;
    [self saveState];
}

- (IBAction)arrowPressed:(UIButton*)sender {
    // right arrow
    if (historyOfResults != nil) {
        if (sender.tag == 15) {
            if (posInHistory < historyOfResults.count - 1) {
                posInHistory++;
                currentResult = [[historyOfResults objectAtIndex:posInHistory] doubleValue];
                self.numberTextField.text = [NSString stringWithFormat:@"%f", currentResult];
                [self updateTextField];
            }
        }
        
        // left arrow
        else {
            if (posInHistory > 0) {
                posInHistory--;
                currentResult = [[historyOfResults objectAtIndex:posInHistory] doubleValue];
                self.numberTextField.text = [NSString stringWithFormat:@"%f", currentResult];
                [self updateTextField];
            }
        }
    }
    
    [self updateArrowLabels];
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
//    currentResult = 0.; // DANGEROUS
    lastToggledOperator.selected = NO;
    [self saveState];
    textFieldShouldBeCleared = YES;
    lastButtonPressWasResult = YES;
}

- (void) updateTextField;
{
    switch (decimalPointCounter) {
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

- (void) saveState;
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@", self.numberTextField.text] forKey:@"NumberTextField"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:currentResult] forKey:@"CurrentResult"];
    [[NSUserDefaults standardUserDefaults] setBool:lastToggledOperator.selected forKey:@"LastToggledOperatorSelected"];
    [[NSUserDefaults standardUserDefaults] setInteger:lastPressedOperatorTag forKey:@"LastPressedOperatorTag"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:decimalPointCounter] forKey:@"AmountOfDecimalPoints"];
    [[NSUserDefaults standardUserDefaults] setDouble:firstOperand forKey:@"FirstOperand"];
}

- (void) deselectAllButtons;
{
    lastToggledOperator.selected = NO;
    self.minusButton.selected = NO;
    self.plusButton.selected = NO;
    self.multButton.selected = NO;
    self.divButton.selected = NO;
}

- (void) addResultToHistory: (double) theResult;
{
    if (historyOfResults.count < 10) {
        [historyOfResults addObject:[NSNumber numberWithDouble:theResult]];
        posInHistory = historyOfResults.count - 1;
    }
    
    else {
        [historyOfResults removeObjectAtIndex:0];
        [historyOfResults addObject:[NSNumber numberWithDouble:theResult]];
    }
    
    [self updateArrowLabels];
}

- (void) updateArrowLabels;
{
    self.leftArrowLabel.text = [NSString stringWithFormat:@"%i", posInHistory];
    self.rightArrowLabel.text = [NSString stringWithFormat:@"%i", historyOfResults.count - 1 - posInHistory];
    if (historyOfResults.count == 0)
        self.rightArrowLabel.text = [NSString stringWithFormat:@"%i", 0];
}

- (BOOL)prefersStatusBarHidden;
{
    return YES;
}

-(void)storeHistory
{
    //NSLog(@"results: %@", historyOfResults);
    
    NSString *error;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"Data.plist"];
    NSDictionary *plistDict = [NSDictionary dictionaryWithObjects:
                               [NSArray arrayWithObjects: historyOfResults, [[NSNumber alloc] initWithInt:posInHistory], nil]
                                                          forKeys:[NSArray arrayWithObjects: @"history", @"posInHistory", nil]];
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:plistDict
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                         errorDescription:&error];
    if(plistData) {
        [plistData writeToFile:plistPath atomically:YES];
    }
    else {
        NSLog(error);
    }
}

@end
