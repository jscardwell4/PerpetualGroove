//
//  MSColorInputButton.m
//  Remote
//
//  Created by Jason Cardwell on 5/3/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "MSColorInputViewController.h"
#import "MSColorInputButton.h"

@interface MSColorInputButton () <MSColorInputViewControllerDelegate>

@property (nonatomic, strong) MSColorInputViewController * colorInputVC;

- (void)initializeIVARs;
- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer;

@end


@implementation MSColorInputButton

@synthesize colorInputVC = _colorInputVC;

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
    UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc]
                                                  initWithTarget:self 
                                                  action:@selector(handleTap:)];
    [self addGestureRecognizer:tapRecognizer];
}

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
    [self becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (UIView *)inputView {
    
    if (!_colorInputVC) {
        self.colorInputVC = 
            [MSColorInputViewController 
                 colorInputViewControllerWithInitialColor:self.backgroundColor];
        _colorInputVC.delegate = self;
    }
    
    return _colorInputVC.view;
}

#pragma mark - MSColorInputViewControllerDelegate methods

- (void)colorSelected:(UIColor *)color {
    self.backgroundColor = color;
    [self resignFirstResponder];
}

- (void)colorSelectionDidCancel {
    [self resignFirstResponder];
}

@end

