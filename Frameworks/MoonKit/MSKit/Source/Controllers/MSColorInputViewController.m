//
//  MSColorInputViewController.m
//  Remote
//
//  Created by Jason Cardwell on 5/4/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "MSKitGeometryFunctions.h"
#import "MSKitMacros.h"
#import "MSColorInputViewController.h"
#import "UIColor+MSKitAdditions.h"
#import "UIView+MSKitAdditions.h"
#import "MSScrollWheel.h"
#import "UIAlertView+MSKitAdditions.h"

#define DISABLE_LABEL_INTERACTION YES
#define LABEL_INTERACTION_USES_SCROLL_WHEEL NO
#define LABEL_INTERACTION_USES_ALERT_VIEW NO



uint8_t floatToRGB8(CGFloat f) {
  return (uint8_t)(f*255);
}

@interface MSColorInputViewController ()

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIView *colorPreview;
@property (strong, nonatomic) IBOutlet UISlider *redSlider;
@property (strong, nonatomic) IBOutlet UISlider *greenSlider;
@property (strong, nonatomic) IBOutlet UISlider *blueSlider;
@property (strong, nonatomic) IBOutlet UISlider *alphaSlider;
@property (strong, nonatomic) IBOutlet UILabel *redLabel;
@property (strong, nonatomic) IBOutlet UILabel *greenLabel;
@property (strong, nonatomic) IBOutlet UILabel *blueLabel;
@property (strong, nonatomic) IBOutlet UILabel *alphaLabel;
@property (strong, nonatomic) IBOutlet UIView *sliderContainer;
@property (strong, nonatomic) IBOutlet MSScrollWheel * scrollWheel;
@property (strong, nonatomic) IBOutlet UIView *scrollWheelContainer;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
@property (strong, nonatomic) IBOutlet UIView *numberPad;

@property (nonatomic, strong) UIColor * initialColor;
@property (nonatomic, weak) UIColor * color;

- (IBAction)cancel:(id)sender;
- (IBAction)reset:(id)sender;
- (IBAction)presets:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)scrollWheelValueChanged:(MSScrollWheel *)sender;
- (IBAction)sliderValueChanged:(UISlider *)sender;
- (IBAction)handleTap:(UITapGestureRecognizer *)sender;
- (IBAction)handleKeyPress:(UIButton *)sender;

//- (void)initializeIVARs;

- (void)updateColor;
- (void)updateControlsForComponent:(NSUInteger)component withValue:(CGFloat)value;

@end

@implementation MSColorInputViewController {
  __weak UIView * tappedView;
}

@synthesize delegate = _delegate;
@synthesize initialColor = _initialColor;
@synthesize toolbar = _toolbar;
@synthesize colorPreview = _colorPreview;
@synthesize redSlider = _redSlider;
@synthesize greenSlider = _greenSlider;
@synthesize blueSlider = _blueSlider;
@synthesize alphaSlider = _alphaSlider;
@synthesize redLabel = _redLabel;
@synthesize greenLabel = _greenLabel;
@synthesize blueLabel = _blueLabel;
@synthesize alphaLabel = _alphaLabel;
@synthesize sliderContainer = _sliderContainer;
@synthesize scrollWheel = _scrollWheel;
@synthesize scrollWheelContainer = _scrollWheelContainer;
@synthesize labels = _labels;
@synthesize numberPad = _numberPad;

+ (MSColorInputViewController *)colorInputViewControllerWithInitialColor:(UIColor *)initialColor {
  MSColorInputViewController * colorInputViewController =
  [[MSColorInputViewController alloc] initWithNibName:@"MSColorInputView" bundle:nil];
  colorInputViewController.initialColor = initialColor;
  return colorInputViewController;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  [self setColor:_initialColor];
  self.scrollWheel = [MSScrollWheel scrollWheel];
  _scrollWheel.center = CGRectGetCenter(_scrollWheelContainer.bounds);
  _scrollWheel.labelTextGenerator = (ValueToLabelTextConverter)^(CGFloat value) {
    return [NSString stringWithFormat:@"%hhu",floatToRGB8(value)];
  };
  [_scrollWheel addTarget:self
                   action:@selector(scrollWheelValueChanged:)
         forControlEvents:UIControlEventValueChanged];
  [self.scrollWheelContainer addSubview:_scrollWheel];
  _scrollWheelContainer.exclusiveTouch = YES;

  if (DISABLE_LABEL_INTERACTION)
    [self.labels setValue:@NO forKey:@"userInteractionEnabled"];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  [self setSliderContainer:nil];
  [self setToolbar:nil];
  [self setRedSlider:nil];
  [self setRedLabel:nil];
  [self setBlueSlider:nil];
  [self setBlueLabel:nil];
  [self setGreenSlider:nil];
  [self setGreenLabel:nil];
  [self setAlphaSlider:nil];
  [self setAlphaLabel:nil];
  [self setColorPreview:nil];
  [self setScrollWheel:nil];
  [self setScrollWheelContainer:nil];
  [self setLabels:nil];
  [self setNumberPad:nil];
  if ([self isViewLoaded] && self.view.window == nil) self.view = nil;
}

- (UIColor *)color {
  return [UIColor colorWithRed:_redSlider.value
                         green:_greenSlider.value
                          blue:_blueSlider.value
                         alpha:_alphaSlider.value];
}

- (void)setColor:(UIColor *)color {
  CGFloat r = 0, g = 0, b = 0, a = 0;
  [color getRed:&r green:&g blue:&b alpha:&a];
  NSArray * colorComponents = @[@(a), @(g), @(b), @(a)];
  for (int i = 0; i < 4; i++) [self updateControlsForComponent:i withValue:[colorComponents[i] floatValue]];

  _colorPreview.backgroundColor = color;

}

- (void)updateControlsForComponent:(NSUInteger)component withValue:(CGFloat)value {

  NSString * valueString = [NSString stringWithFormat:@"%hhu", floatToRGB8(value)];

  switch (component) {
    case 0:
      _redSlider.value = value;
      _redLabel.text = valueString;
      break;

    case 1:
      _greenSlider.value = value;
      _greenLabel.text = valueString;
      break;

    case 2:
      _blueSlider.value = value;
      _blueLabel.text = valueString;
      break;

    case 3:
      _alphaSlider.value = value;
      _alphaLabel.text = valueString;
      break;

    default:
      NSAssert(NO,@"Invalid component index received");
      break;
  }

}

- (void)updateColor {

  UIColor * color = [self color];

  _colorPreview.backgroundColor = color;

  if ([_delegate respondsToSelector:@selector(colorValueDidChange:)])
    [_delegate colorValueDidChange:color];

}


- (IBAction)cancel:(id)sender {

  UIView * firstResponder = [UIView firstResponderInView:self.view];
  if (firstResponder)
    [firstResponder resignFirstResponder];

  [_delegate colorSelectionDidCancel];
}

- (IBAction)reset:(id)sender {
  [self setColor:_initialColor];
}

- (IBAction)presets:(id)sender {
}

- (IBAction)done:(id)sender {

  UIView * firstResponder = [UIView firstResponderInView:self.view];
  if (firstResponder)
    [firstResponder resignFirstResponder];

  [_delegate colorSelected:self.color];
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
  [self updateControlsForComponent:sender.tag withValue:sender.value];
  [self updateColor];
}

- (IBAction)handleTap:(UITapGestureRecognizer *)sender {
  // NSLog(@"%@", ClassTagSelectorString);


  if (LABEL_INTERACTION_USES_SCROLL_WHEEL) {

    tappedView = sender.view;
    _scrollWheelContainer.hidden = NO;

  } else if (LABEL_INTERACTION_USES_ALERT_VIEW) {

    NSInteger tag = sender.view.tag;
    NSString * component;
    switch (tag) {
      case 0:
        component = @"Red";
        break;

      case 1:
        component = @"Green";
        break;

      case 2:
        component = @"Blue";
        break;

      case 3:
        component = @"Alpha";
        break;

      default:
        NSAssert(NO, @"Invalid tag");
        break;
    }

    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ component value", component]
                                                     message:@"Enter a value between 0 and 255."
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Enter", nil];

    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = tag;
    UITextField * textField = [alert textFieldAtIndex:0];
    textField.placeholder = [(UILabel *)sender.view text];
    textField.keyboardType = UIKeyboardTypeDecimalPad;
    textField.enablesReturnKeyAutomatically = YES;
    [alert show];

  } else {

    //        self.numberPad.hidden = NO;

  }

}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex > 0) {

    UITextField * textField = [alertView textFieldAtIndex:0];
    if (StringIsNotEmpty(textField.text)) {
      // NSLog(@"%@ textField.text:%@", ClassTagSelectorString, textField.text);

      NSInteger value = [textField.text integerValue];

      if (value >= 0 && value <= 255) {

        [self updateControlsForComponent:alertView.tag
                               withValue:value/255.0];
        [self updateColor];

      }

    }

  }
}

- (IBAction)handleKeyPress:(UIButton *)sender {
  // NSLog(@"%@ tag:%i", ClassTagSelectorString, sender.tag);
}

- (IBAction)scrollWheelValueChanged:(MSScrollWheel *)sender {
  // NSLog(@"%@ scroll wheel value:%@", ClassTagSelectorString, PrettyFloat(sender.value));
  [self updateControlsForComponent:tappedView.tag withValue:sender.value];
}

@end

