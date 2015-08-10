//
//  MSPickerInput.h
//  Remote
//
//  Created by Jason Cardwell on 4/7/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;


#import "MSView.h"

@class MSPickerInputView, MSPickerInputButton;

@protocol MSPickerInputDelegate <NSObject>

@required

- (void)pickerInput:(MSPickerInputView *)pickerInput selectedRows:(NSArray *)rows;

- (void)pickerInputDidCancel:(MSPickerInputView *)pickerInput;

- (NSInteger)numberOfComponentsInPickerInput:(MSPickerInputView *)pickerInput;

- (NSInteger)pickerInput:(MSPickerInputView *)pickerInput
 numberOfRowsInComponent:(NSInteger)component;

@optional

- (CGFloat)pickerInput:(MSPickerInputView *)pickerInput
     widthForComponent:(NSInteger)component;

- (CGFloat)pickerInput:(MSPickerInputView *)pickerInput 
 rowHeightForComponent:(NSInteger)component;

- (NSString *)pickerInput:(MSPickerInputView *)pickerInput 
              titleForRow:(NSInteger)row 
             forComponent:(NSInteger)component;
- (UIView *)pickerInput:(MSPickerInputView *)pickerInput 
             viewForRow:(NSInteger)row
           forComponent:(NSInteger)component
            reusingView:(UIView *)view;
- (void)pickerInput:(MSPickerInputView *)pickerInput 
       didSelectRow:(NSInteger)row 
        inComponent:(NSInteger)component;

@end

@interface MSPickerInputView : MSView

@property (nonatomic, weak) id<MSPickerInputDelegate> delegate;

+ (MSPickerInputView *)pickerInput;

@property (nonatomic, weak) MSPickerInputButton * pickerInputButton;

@property (nonatomic, strong) IBOutlet UIBarButtonItem * cancelBarButtonItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem * selectBarButtonItem;

- (void)insertBarButtonItem:(UIBarButtonItem *)barButtonItem atIndex:(NSUInteger)index;

@end

@interface MSPickerInputView (UIPickerViewMethods)

@property(nonatomic,assign) id<UIPickerViewDataSource> dataSource;
@property(nonatomic,assign) id<UIPickerViewDelegate>   delegate;
@property(nonatomic)        BOOL                       showsSelectionIndicator;

@property(nonatomic,readonly) NSInteger numberOfComponents;

- (NSInteger)numberOfRowsInComponent:(NSInteger)component;
- (CGSize)rowSizeForComponent:(NSInteger)component;

- (UIView *)viewForRow:(NSInteger)row forComponent:(NSInteger)component;

- (void)reloadAllComponents;
- (void)reloadComponent:(NSInteger)component;

- (void)selectRow:(NSInteger)row inComponent:(NSInteger)component animated:(BOOL)animated;

- (NSInteger)selectedRowInComponent:(NSInteger)component;

@end

