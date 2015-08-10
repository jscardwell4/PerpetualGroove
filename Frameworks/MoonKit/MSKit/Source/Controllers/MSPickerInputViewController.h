//
//  MSPickerInputViewController.h
//  Remote
//
//  Created by Jason Cardwell on 4/6/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

@import Foundation;
@import UIKit;


@class MSPickerInputViewController;

@protocol MSPickerInputViewControllerDelegate <NSObject>

- (void)pickerInputViewControllerDidCancel:(MSPickerInputViewController *)controller;

- (void)pickerInputViewController:(MSPickerInputViewController *)controller 
                     selectedRows:(NSArray *)rows;

@end

@interface MSPickerInputViewController : UIViewController <UIPickerViewDelegate,
	                                                       UIPickerViewDataSource>

@property (nonatomic, weak) id<MSPickerInputViewControllerDelegate> delegate;

@property (nonatomic, strong) NSArray * pickerViewData;

- (void)selectRow:(NSInteger)row inComponent:(NSInteger)component animated:(BOOL)animated;

- (void)customCancelButtonFromView:(UIView *)view;

- (void)customSelectButtonFromView:(UIView *)view;

+ (MSPickerInputViewController *)pickerInputViewController;

@end
