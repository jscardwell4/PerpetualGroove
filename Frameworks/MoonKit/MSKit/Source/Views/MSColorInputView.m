//
//  MSColorInputView.m
//  Remote
//
//  Created by Jason Cardwell on 5/3/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "MSKitMacros.h"

#import "MSColorInputView.h"
#import "UIColor+MSKitAdditions.h"
#import "UIView+MSKitAdditions.h"

@interface MSColorInputView () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIView *colorPreview;
@property (strong, nonatomic) IBOutlet UISlider *redSlider;
@property (strong, nonatomic) IBOutlet UISlider *greenSlider;
@property (strong, nonatomic) IBOutlet UISlider *blueSlider;
@property (strong, nonatomic) IBOutlet UISlider *alphaSlider;
@property (strong, nonatomic) IBOutlet UITextField *redTextField;
@property (strong, nonatomic) IBOutlet UITextField *greenTextField;
@property (strong, nonatomic) IBOutlet UITextField *blueTextField;
@property (strong, nonatomic) IBOutlet UITextField *alphaTextField;

- (IBAction)cancel:(id)sender;
- (IBAction)reset:(id)sender;
- (IBAction)presets:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)sliderValueChanged:(UISlider *)sender;

- (void)initializeIVARs;

- (void)updateColor;
- (void)updateControlsForComponent:(NSUInteger)component withValue:(CGFloat)value;

@end


@implementation MSColorInputView {
    UIView * responderView;
}

@synthesize initialColor = _initialColor;
@synthesize toolbar = _toolbar;
@synthesize colorPreview = _colorPreview;
@synthesize redSlider = _redSlider;
@synthesize greenSlider = _greenSlider;
@synthesize blueSlider = _blueSlider;
@synthesize alphaSlider = _alphaSlider;
@synthesize redTextField = _redTextField;
@synthesize greenTextField = _greenTextField;
@synthesize blueTextField = _blueTextField;
@synthesize alphaTextField = _alphaTextField;

+ (MSColorInputView *)colorInputView {
    MSColorInputView * colorInputView = [MainBundle loadNibNamed:@"MSColorInputView" 
                                                            owner:nil
                                                          options:nil][0];
    return colorInputView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initializeIVARs];
    }
    return self;
}

- (void)awakeFromNib {
    [self initializeIVARs];
}

- (void)initializeIVARs {
    responderView = [UIView currentResponder];
}

- (UIColor *)color {
    return [UIColor colorWithRed:_redSlider.value 
                           green:_greenSlider.value 
                            blue:_blueSlider.value 
                           alpha:_alphaSlider.value];
}

- (void)setInitialColor:(UIColor *)initialColor {
    _initialColor = initialColor;
    [self setColor:_initialColor];
}

- (void)setColor:(UIColor *)color {
  CGFloat r = 0, g = 0, b = 0, a = 0;
  [color getRed:&r green:&g blue:&b alpha:&a];
  NSArray * colorComponents = @[@(r), @(g), @(b), @(a)];

    for (int i = 0; i < 4; i++)  [self updateControlsForComponent:i withValue:[colorComponents[i] floatValue]];
    
    _colorPreview.backgroundColor = color;
    
}

- (void)updateControlsForComponent:(NSUInteger)component withValue:(CGFloat)value {
    
    NSString * valueString = [NSString stringWithFormat:@"%lu", (unsigned long)(value*255)];
    
    switch (component) {
        case 0:
            _redSlider.value = value;
            _redTextField.text = valueString;
            break;
            
        case 1:
            _greenSlider.value = value;
            _greenTextField.text = valueString;
            break;
            
        case 2:
            _blueSlider.value = value;
            _blueTextField.text = valueString;
            break;
            
        case 3:
            _alphaSlider.value = value;
            _alphaTextField.text = valueString;
            break;
            
        default:
            NSAssert(NO,@"Invalid component index received");
            break;
    }
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)updateColor {
    UIColor * color = [self color];

    _colorPreview.backgroundColor = color;
    
    if ([responderView conformsToProtocol:@protocol(MSColorInput)])
        [(id<MSColorInput>)responderView setColor:color];
}


- (IBAction)cancel:(id)sender {
    
    if ([responderView conformsToProtocol:@protocol(MSColorInput)])
        [(id<MSColorInput>)responderView setColor:_initialColor];

    [responderView resignFirstResponder];
}

- (IBAction)reset:(id)sender {
    [self setColor:_initialColor];
}

- (IBAction)presets:(id)sender {
}

- (IBAction)done:(id)sender {
    [responderView resignFirstResponder];
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
 
    [self updateControlsForComponent:sender.tag withValue:sender.value];

    [self updateColor];

}

#pragma mark - UITextFieldDelegate methods

- (BOOL)              textField:(UITextField *)textField
  shouldChangeCharactersInRange:(NSRange)range 
			  replacementString:(NSString *)string
{
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	return YES;
}

@end

