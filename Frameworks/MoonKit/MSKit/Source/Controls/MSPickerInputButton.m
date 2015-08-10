//
//  MSPickerInputButton.m
//  Remote
//
//  Created by Jason Cardwell on 4/6/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "MSKitMacros.h"

#import "MSPickerInputButton.h"



@interface MSPickerInputButton ()

@property (nonatomic, strong) UIButton * button;
@property (nonatomic, strong, readwrite) MSPickerInputView * inputView;

@end


@implementation MSPickerInputButton

@synthesize button = _button, inputView = _inputView, delegate = _delegate;


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.frame = self.bounds;
        _button.autoresizingMask = AutoresizeAllFlexible;
        [_button addTarget:self 
                    action:@selector(becomeFirstResponder) 
          forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_button];
    }
    return self;
}

- (void)awakeFromNib {
    if (ValueIsNil(_button)) {
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.frame = self.bounds;
        _button.autoresizingMask = AutoresizeAllFlexible;
       [_button addTarget:self 
                    action:@selector(becomeFirstResponder) 
          forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_button];
    }
}

- (void)setEnabled:(BOOL)enabled {
    _button.enabled = enabled;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    if ([_delegate respondsToSelector:@selector(pickerInputButtonWillShowPicker:)]) {
        [_delegate pickerInputButtonWillShowPicker:self];
    }
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    if ([_delegate respondsToSelector:@selector(pickerInputButtonWillHidePicker:)]) {
        [_delegate pickerInputButtonWillHidePicker:self];
    }
    return [super resignFirstResponder];
}

- (MSPickerInputView *)inputView {
    if (ValueIsNotNil(_inputView))
        return _inputView;

    
    if (ValueIsNotNil(_delegate)) {
        MSPickerInputView * pickerInput = [MSPickerInputView pickerInput];
        pickerInput.delegate = _delegate;
        pickerInput.pickerInputButton = self;
        self.inputView = pickerInput;
        
        // NSLog(@"%@ pickerInput created for input view:%@",
        //      ClassTagSelectorString, pickerInput);
    }
    
    return _inputView;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector])
        return YES;
    else
        return [self.inputView respondsToSelector:aSelector]|[self.button respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.button respondsToSelector:aSelector]) {
        // NSLog(@"%@ forwarding %@ to button", 
        //    ClassTagSelectorString,
        //         SelectorString(aSelector));
        return _button;
    }
    
    else if ([self.inputView respondsToSelector:aSelector]) {
        // NSLog(@"%@ forwarding %@ to inputView", 
        // ClassTagSelectorString,
        //         SelectorString(aSelector));
        return _inputView;
    } else {
        // NSLog(@"%@ forwarding %@ to super implementation", 
        //         ClassTagSelectorString,
        //         SelectorString(aSelector));
        return [super forwardingTargetForSelector:aSelector];
    }
}

@end

