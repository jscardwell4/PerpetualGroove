//
//  MSColorInputViewController.h
//  Remote
//
//  Created by Jason Cardwell on 5/4/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

@import Foundation;
@import UIKit;


@protocol MSColorInputViewControllerDelegate <NSObject>

- (void)colorSelected:(UIColor *)color;
- (void)colorSelectionDidCancel;

@optional

- (void)colorValueDidChange:(UIColor *)color;

@end

@interface MSColorInputViewController : UIViewController <UIAlertViewDelegate>

+ (MSColorInputViewController *)colorInputViewControllerWithInitialColor:(UIColor *)initialColor;

@property (nonatomic, weak) id<MSColorInputViewControllerDelegate> delegate;

@end
