//
//  UIAlertView+MSKitAdditions.m
//  Remote
//
//  Created by Jason Cardwell on 5/4/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "UIAlertView+MSKitAdditions.h"

static DismissBlock _dismissBlock;
static CancelBlock _cancelBlock;

@implementation UIAlertView (MSKitAdditions)

+ (UIAlertView *)showAlertViewWithTitle:(NSString *)title    
                                  style:(UIAlertViewStyle)style
                                message:(NSString *)message 
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                      otherButtonTitles:(NSArray *)otherButtons
                              onDismiss:(DismissBlock)dismissed                   
                               onCancel:(CancelBlock)cancelled {
    
    _cancelBlock = [cancelled copy];
    
    _dismissBlock = [dismissed copy];
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:[self self]
                                          cancelButtonTitle:cancelButtonTitle
                                          otherButtonTitles:nil];
    
    for(NSString * buttonTitle in otherButtons)
        [alert addButtonWithTitle:buttonTitle];
    
    alert.alertViewStyle = style;
    
    [alert show];
    return alert;
}

+ (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
	if(buttonIndex == [alertView cancelButtonIndex] && _cancelBlock)
		_cancelBlock();

    else if (_dismissBlock)
        _dismissBlock(buttonIndex - 1, alertView); // cancel button is button 0

}

@end

