//
//  CPViewController.h
//  CloudPaymentsAPIDemo
//
//  Created by Oleg Fedjakin on 9/7/14.
//  Copyright (c) 2014 CloudPayments LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPViewController : UIViewController <UITextFieldDelegate, UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *cardNumberTextField;
@property (weak, nonatomic) IBOutlet UITextField *cardOwnerTextField;
@property (weak, nonatomic) IBOutlet UITextField *cardExpirationDateTextField;
@property (weak, nonatomic) IBOutlet UITextField *cardCVVTextField;
@property (weak, nonatomic) IBOutlet UITextField *orderAmountTextField;


- (IBAction)makePaymentAction:(id)sender;

@end
