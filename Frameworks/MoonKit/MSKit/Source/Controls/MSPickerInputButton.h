//
//  MSPickerInputButton.h
//  Remote
//
//  Created by Jason Cardwell on 4/6/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//


#import "MSView.h"
#import "MSPickerInputView.h"


@class MSPickerInputButton;

@protocol MSPickerInputButtonDelegate <MSPickerInputDelegate>

@optional
- (void)pickerInputButtonWillShowPicker:(MSPickerInputButton *)pickerInputButton;
- (void)pickerInputButtonWillHidePicker:(MSPickerInputButton *)pickerInputButton;

@end

@interface MSPickerInputButton : MSView

@property (nonatomic, strong, readonly) MSPickerInputView * inputView;

@property (nonatomic, weak) IBOutlet id<MSPickerInputButtonDelegate> delegate;

@end

@interface MSPickerInputButton (UIButtonMethods)
@property (nonatomic)         BOOL enabled;
@property(nonatomic)          UIEdgeInsets contentEdgeInsets; 
@property(nonatomic)          UIEdgeInsets titleEdgeInsets;              
@property(nonatomic)          BOOL         reversesTitleShadowWhenHighlighted;
@property(nonatomic)          UIEdgeInsets imageEdgeInsets;           
@property(nonatomic)          BOOL         adjustsImageWhenHighlighted; 
@property(nonatomic)          BOOL         adjustsImageWhenDisabled;    
@property(nonatomic)          BOOL         showsTouchWhenHighlighted;   
@property(nonatomic,strong)   UIColor     *tintColor;
@property(nonatomic,readonly) UIButtonType buttonType;

- (void)setTitle:(NSString *)title forState:(UIControlState)state;      
- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state;      
- (void)setTitleShadowColor:(UIColor *)color forState:(UIControlState)state;
- (void)setImage:(UIImage *)image forState:(UIControlState)state;           
- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state; 

- (NSString *)titleForState:(UIControlState)state;        
- (UIColor *)titleColorForState:(UIControlState)state;
- (UIColor *)titleShadowColorForState:(UIControlState)state;
- (UIImage *)imageForState:(UIControlState)state;
- (UIImage *)backgroundImageForState:(UIControlState)state;

@property(nonatomic,readonly,strong) NSString *currentTitle;           
@property(nonatomic,readonly,strong) UIColor  *currentTitleColor;      
@property(nonatomic,readonly,strong) UIColor  *currentTitleShadowColor;
@property(nonatomic,readonly,strong) UIImage  *currentImage;          
@property(nonatomic,readonly,strong) UIImage  *currentBackgroundImage;
@property(nonatomic,readonly,strong) UILabel     *titleLabel;
@property(nonatomic,readonly,strong) UIImageView *imageView;

- (CGRect)backgroundRectForBounds:(CGRect)bounds;
- (CGRect)contentRectForBounds:(CGRect)bounds;
- (CGRect)titleRectForContentRect:(CGRect)contentRect;
- (CGRect)imageRectForContentRect:(CGRect)contentRect;

@end

@interface MSPickerInputButton (UIPickerViewMethods)

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

@interface MSPickerInputButton (MSPickerInputMethods)

@property (nonatomic, strong) IBOutlet UIBarButtonItem * cancelBarButtonItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem * selectBarButtonItem;

- (void)insertBarButtonItem:(UIBarButtonItem *)barButtonItem atIndex:(NSUInteger)index;

@end

