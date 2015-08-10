//
//  MSNumberPadView.m
//  Remote
//
//  Created by Jason Cardwell on 3/30/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "MSNumberPadView.h"

@interface MSNumberPadView ()

- (IBAction)keyAction:(UIView *)sender;
@property (nonatomic, weak) UITextField *textField;

@end


@implementation MSNumberPadView

@synthesize delegate = _delegate, textField = _textField;

+ (MSNumberPadView *)numberPadViewWithDelegate:(id<MSNumberPadViewDelegate>)delegate
									 textField:(UITextField *)textField {
	UINib *numberPadNib = [UINib nibWithNibName:@"CustomNumberPadView" bundle:nil];
	MSNumberPadView *numberPadView = 
		[numberPadNib instantiateWithOwner:nil options:nil][0];
	numberPadView.delegate = delegate;
	numberPadView.textField = textField;
	return numberPadView;
}

- (IBAction)keyAction:(UIView *)sender {
	// NSLog(@"keyAction for view with tag:%i", sender.tag);
	if (!_textField)
		return;
	
	NSString *currentText = _textField.text;
	switch (sender.tag) {
		case 1:
			_textField.text = [currentText stringByAppendingString:@"1"];
			break;
			
		case 2:
			_textField.text = [currentText stringByAppendingString:@"2"];
			break;
			
		case 3:
			_textField.text = [currentText stringByAppendingString:@"3"];
			break;
			
		case 4:
			_textField.text = [currentText stringByAppendingString:@"4"];
			break;
			
		case 5:
			_textField.text = [currentText stringByAppendingString:@"5"];
			break;
			
		case 6:
			_textField.text = [currentText stringByAppendingString:@"6"];
			break;
			
		case 7:
			_textField.text = [currentText stringByAppendingString:@"7"];
			break;
			
		case 8:
			_textField.text = [currentText stringByAppendingString:@"8"];
			break;
			
		case 9:
			_textField.text = [currentText stringByAppendingString:@"9"];
			break;
			
		case 10:
			_textField.text = [currentText stringByAppendingString:@"."];
			break;
			
		case 11:
			_textField.text = [currentText stringByAppendingString:@"0"];
			break;
			
		case 12:
			_textField.text = [currentText substringToIndex:[currentText length] - 1];
			break;
	}
}

@end

