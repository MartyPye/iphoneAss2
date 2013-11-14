//
//  ViewController.h
//  iCalc
//
//  Created by Florian Heller on 10/5/12.
//  Copyright (c) 2012 Florian Heller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasicCalculator.h"

@interface ViewController : UIViewController <BasicCalculatorDelegate>

typedef enum BCButtonType : NSUInteger {
	OperatorButton,
	NumberButton,
	PointButton,
	ResultButton,
    ClearButton
} BCButtonType;


@property (weak, nonatomic) IBOutlet UITextField *numberTextField;

@property (strong, nonatomic) BasicCalculator *calculator;

- (IBAction)operationButtonPressed:(UIButton *)sender;
- (IBAction)resultButtonPressed:(UIButton *)sender;
- (IBAction)numberEntered:(UIButton *)sender;
- (IBAction)decimalPointEntered:(UIButton *) sender;
- (IBAction)clearDisplay:(id)sender;

-(void)storeHistory;


@end
