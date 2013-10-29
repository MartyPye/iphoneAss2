//
//  ViewController.h
//  iCalc
//
//  Created by Florian Heller on 10/5/12.
//  Copyright (c) 2012 Florian Heller. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *numberTextField;

- (IBAction)operationButtonPressed:(UIButton *)sender;
- (IBAction)resultButtonPressed:(UIButton *)sender;
- (IBAction)numberEntered:(UIButton *)sender;
- (IBAction)decimalPointEntered:(UIButton *) sender;
- (IBAction)clearDisplay:(id)sender;


@end
