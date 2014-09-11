//
//  CPViewController.m
//  CloudPaymentsAPIDemo
//
//  Created by Oleg Fedjakin on 9/7/14.
//  Copyright (c) 2014 Cloudpayments. All rights reserved.
//

#import "CPViewController.h"

#import <CloudPaymentsAPI/CPService.h>
#import "AFNetworking.h"
#import "SVProgressHUD.h"


@interface CPViewController () {
	CPService *_apiService;
	
	// These values you MUST store at your server.
	NSString *_apiPublicID;
	NSString *_apiSecret;
	
	// This variable is for 3DS authorization. You MUST use your own value.
	NSString *_termURL;
}

- (NSDictionary *)parseQueryString:(NSString *)query;
@end

@implementation CPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_apiService = [[CPService alloc] init];
	
#pragma message "These values you MUST store at your server."
	_apiPublicID = @"pk_348c635ba69b355d6f4dc75a4a205";
	_apiSecret = @"02a16349d37b79838a1d0310e21bd369";

#pragma message "This variable is for 3DS authorization. You MUST use your own value."
	_termURL = @"http://cloudpayments.ru/";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - make payment implementation

- (IBAction)makePaymentAction:(id)sender {
	
	// ExpDate must be in YYMM format
	NSArray *cardDateComponents = [self.cardExpirationDateTextField.text componentsSeparatedByString:@"/"];
	NSString *cardExpirationDateString = [NSString stringWithFormat:@"%@%@",cardDateComponents[1],cardDateComponents[0]];
	
	// create dictionary with parameters for send
	NSMutableDictionary *paramsDictionary = [[NSMutableDictionary alloc] init];
	
	NSString *cryptogramPacket = [_apiService makeCardCryptogramPacket:self.cardNumberTextField.text
															andExpDate:cardExpirationDateString
																andCVV:self.cardCVVTextField.text
													  andStorePublicID:_apiPublicID];

	[paramsDictionary setObject:cryptogramPacket forKey:@"CardCryptogramPacket"];
	[paramsDictionary setObject:self.orderAmountTextField.text forKey:@"Amount"];
	[paramsDictionary setObject:@"RUB" forKey:@"Currency"];
	[paramsDictionary setObject:self.cardOwnerTextField.text forKey:@"Name"];
	
	NSString *apiURLString = @"https://api.cloudpayments.ru/payments/cards/charge";
	
	// setup AFHTTPRequestOperationManager HTTP BasicAuth and serializers
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
		
	manager.requestSerializer = [AFJSONRequestSerializer serializer];
	[manager.requestSerializer setAuthorizationHeaderFieldWithUsername:_apiPublicID password:_apiSecret];
   
	manager.responseSerializer = [AFJSONResponseSerializer serializer];

	// implement success block
	void (^successBlock)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
		if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
			BOOL isSuccess = [[responseObject objectForKey:@"Success"] boolValue];
			if (isSuccess) {
				[SVProgressHUD showSuccessWithStatus:@"Ok"];
			} else {
				NSDictionary *model = [responseObject objectForKey:@"Model"];
				if (([responseObject objectForKey:@"Message"]) && ![[responseObject objectForKey:@"Message"] isKindOfClass:[NSNull class]]) {
					// some error
					[SVProgressHUD showErrorWithStatus:[responseObject objectForKey:@"Message"]];
				} else if (([model objectForKey:@"CardHolderMessage"]) && ![[model objectForKey:@"CardHolderMessage"] isKindOfClass:[NSNull class]]) {
					// some error from acquier
					[SVProgressHUD showErrorWithStatus:[model objectForKey:@"CardHolderMessage"]];
				} else if (([model objectForKey:@"AcsUrl"]) && ![[model objectForKey:@"AcsUrl"] isKindOfClass:[NSNull class]]) {
					// need for 3DSecure request
					[self make3DSPaymentWithAcsURLString:(NSString *) [model objectForKey:@"AcsUrl"] andPaReqString:(NSString *) [model objectForKey:@"PaReq"] andTransactionIdString:[[model objectForKey:@"TransactionId"] stringValue]];
				}
			}
		}
	};
		
	// implement failure block
	void (^failureBlock)(AFHTTPRequestOperation*,NSError*) = ^(AFHTTPRequestOperation *operation, NSError *error) {
		[SVProgressHUD dismiss];
		[SVProgressHUD showErrorWithStatus:error.localizedDescription];
	};
	
	[SVProgressHUD showWithStatus:@"Отправка данных"];
	[manager POST:apiURLString parameters:paramsDictionary
		  success: successBlock
		  failure:failureBlock
	];
}

-(void) make3DSPaymentWithAcsURLString: (NSString *) acsUrlString andPaReqString: (NSString *) paReqString andTransactionIdString: (NSString *) transactionIdString {
	
	NSDictionary *postParameters = @{@"MD": transactionIdString, @"TermUrl": _termURL, @"PaReq": paReqString};
	NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST"
																				 URLString:acsUrlString
																				parameters:postParameters
																					 error:nil];
	
	NSHTTPURLResponse *response;
	NSError *error;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request
												 returningResponse:&response
															 error:&error];
	
	
	if ([response statusCode] == 200) {
		[SVProgressHUD dismiss];
		UIWebView *webView=[[UIWebView alloc] initWithFrame:self.view.frame];
		webView.delegate = self;
		[self.view addSubview:webView];
		
		[webView loadData:responseData
				 MIMEType:[response MIMEType]
		 textEncodingName:[response textEncodingName]
				  baseURL:[response URL]];
	} else {
		NSString *messageString = [NSString stringWithFormat:@"Unable to load 3DS autorization page.\nStatus code: %d", (unsigned int)[response statusCode]];
		[SVProgressHUD showErrorWithStatus:messageString];
	}
}

-(void) complete3DSPaymentWithPaResString: (NSString *) paResString andTransactionIdString: (NSString *) transactionIdString {

	// create dictionary with parameters for send
	NSMutableDictionary *paramsDictionary = [[NSMutableDictionary alloc] init];
		
	[paramsDictionary setObject:paResString forKey:@"PaRes"];
	[paramsDictionary setObject:transactionIdString forKey:@"TransactionId"];
	
	NSString *apiURLString = @"https://api.cloudpayments.ru/payments/post3ds";
	
	// setup AFHTTPRequestOperationManager HTTP BasicAuth and serializers
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	
	manager.requestSerializer = [AFJSONRequestSerializer serializer];
	[manager.requestSerializer setAuthorizationHeaderFieldWithUsername:_apiPublicID password:_apiSecret];
	
	manager.responseSerializer = [AFJSONResponseSerializer serializer];
	
	// implement success block
	void (^successBlock)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
		if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
			BOOL isSuccess = [[responseObject objectForKey:@"Success"] boolValue];
			if (isSuccess) {
				NSDictionary *model = [responseObject objectForKey:@"Model"];
				if (([model objectForKey:@"CardHolderMessage"]) && ![[model objectForKey:@"CardHolderMessage"] isKindOfClass:[NSNull class]]) {
					// some error from acquier
					[SVProgressHUD showSuccessWithStatus:[model objectForKey:@"CardHolderMessage"]];
				} else {
					[SVProgressHUD showSuccessWithStatus:@"Ok"];
				}
			} else {
				NSDictionary *model = [responseObject objectForKey:@"Model"];
				if (([responseObject objectForKey:@"Message"]) && ![[responseObject objectForKey:@"Message"] isKindOfClass:[NSNull class]]) {
					// some error
					[SVProgressHUD showErrorWithStatus:[responseObject objectForKey:@"Message"]];
				} else if (([model objectForKey:@"CardHolderMessage"]) && ![[model objectForKey:@"CardHolderMessage"] isKindOfClass:[NSNull class]]) {
					// some error from acquier
					[SVProgressHUD showErrorWithStatus:[model objectForKey:@"CardHolderMessage"]];
				} else {
					[SVProgressHUD showErrorWithStatus:@"Some error"];
				}
			}
		}
	};
	
	// implement failure block
	void (^failureBlock)(AFHTTPRequestOperation*,NSError*) = ^(AFHTTPRequestOperation *operation, NSError *error) {
		[SVProgressHUD dismiss];
		[SVProgressHUD showErrorWithStatus:error.localizedDescription];
	};
	
	[SVProgressHUD showWithStatus:@"Отправка данных"];
	
	[manager POST:apiURLString parameters:paramsDictionary
		  success: successBlock
		  failure:failureBlock
	 ];
}

#pragma mark - UITextFieldDelegate implementation
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	// check if card number valid
	if ([textField isEqual:self.cardNumberTextField]) {
		NSString *cardNumberString = textField.text;
		if ([CPService isCardNumberValid:cardNumberString]) {
			[textField resignFirstResponder];
			return YES;
		} else {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Ошибка" message:@"Введите корректный номер карты" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
			[alertView show];
			return NO;
		}
	}
	
	// check if valid length of expiration date
	if ([textField isEqual:self.cardExpirationDateTextField]) {
		NSString *cardExpirationDateString = textField.text;
		if (cardExpirationDateString.length < 5) {
			[SVProgressHUD showErrorWithStatus:@"Введите 4 цифры даты окончания действия карты в формате MM/YY"];
			return NO;
		}
		
		NSArray *dateComponents = [textField.text componentsSeparatedByString:@"/"];
		if(dateComponents.count == 2) {
			NSDate *date = [NSDate date];
			NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
			NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit) fromDate:date];
			NSInteger currentMonth = [components month];
			NSInteger currentYear = [[[NSString stringWithFormat:@"%ld",(long)[components year]] substringFromIndex:2] integerValue];
			
			if([dateComponents[1] intValue] < currentYear) {
				[SVProgressHUD showErrorWithStatus:@"Карта недействительна."];
				[textField becomeFirstResponder];
				return NO;
			}
			
			if (([dateComponents[0] intValue] > 12)) {
				[SVProgressHUD showErrorWithStatus:@"Карта недействительна."];
				[textField becomeFirstResponder];
				return NO;
			}
			
			if([dateComponents[0] integerValue] < currentMonth && [dateComponents[1] intValue] <= currentYear) {
				[SVProgressHUD showErrorWithStatus:@"Карта недействительна."];
				[textField becomeFirstResponder];
				return NO;
			}
		}
		
		[textField resignFirstResponder];
		return YES;
	}
	
	[textField resignFirstResponder];
	return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if ([textField isEqual:self.cardExpirationDateTextField]) {
		
		// handle backspace
		if (range.length > 0 && [string length] == 0) {
			return YES;
		}

		if (textField.text.length >= 5) {
			return NO;
		}
		
		NSString *addChar = [[string componentsSeparatedByCharactersInSet:
							  [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
							 componentsJoinedByString:@""];
		
		switch (textField.text.length) {
			case 0:
			case 3:
			case 4:
				textField.text = [textField.text stringByAppendingString:addChar];
				break;
			case 1:
				textField.text = [textField.text stringByAppendingString:addChar];
				textField.text = [textField.text stringByAppendingString:@"/"];
				break;
			default:
				break;
		}
		
		return NO;
	}
	
	return YES;
}

#pragma mark - UIWebViewDelegate implementation
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSString *urlString = [request.URL absoluteString];
	if ([urlString isEqualToString:_termURL]) {
		NSString *response = [[NSString alloc] initWithData:request.HTTPBody encoding:NSASCIIStringEncoding];
		
		NSDictionary *responseDictionary = [self parseQueryString:response];
		[webView removeFromSuperview];
		
		[self complete3DSPaymentWithPaResString:[responseDictionary objectForKey:@"PaRes"] andTransactionIdString:[responseDictionary objectForKey:@"MD"]];
		return NO;
	}

	return YES;
}

#pragma mark - Utilities
- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [dict setObject:val forKey:key];
    }
    return dict;
}
@end
