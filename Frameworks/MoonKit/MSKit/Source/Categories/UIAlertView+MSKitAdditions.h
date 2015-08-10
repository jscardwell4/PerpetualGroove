//
//  UIAlertView+MSKitAdditions.h
//  Remote
//
//  Created by Jason Cardwell on 5/4/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;



typedef void (^DismissBlock)(NSInteger buttonIndex, UIAlertView * alertView);
typedef void (^CancelBlock)();

@interface UIAlertView (MSKitAdditions)

+ (UIAlertView *)showAlertViewWithTitle:(NSString *)title  
                                  style:(UIAlertViewStyle)style
                                message:(NSString *)message 
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                      otherButtonTitles:(NSArray *)otherButtons
                              onDismiss:(DismissBlock)dismissed                   
                               onCancel:(CancelBlock)cancelled;

@end
