//
//  MSBarButtonItem.m
//  MSKit
//
//  Created by Jason Cardwell on 2/14/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSBarButtonItem_Private.h"

#define DEFAULT_FRAME (CGRect) {{0, 0}, {55, 18}}

@implementation MSBarButtonItem {
    struct {
        BOOL vanilla;
    } _flags;
}

- (id)initWithImage:(UIImage *)image
              style:(UIBarButtonItemStyle)style
             target:(id)target
             action:(SEL)action
{
    [self generateButtonWithTitle:nil attributedTitle:nil image:image target:target action:action];

    return [self initWithCustomView:_button];
}

- (id)initWithImage:(UIImage *)image
landscapeImagePhone:(UIImage *)landscapeImagePhone
              style:(UIBarButtonItemStyle)style
             target:(id)target
             action:(SEL)action
{
    return [self initWithImage:image style:style target:target action:action];
}

- (id)initWithTitle:(NSString *)title
              style:(UIBarButtonItemStyle)style
             target:(id)target
             action:(SEL)action
{
    [self generateButtonWithTitle:title attributedTitle:nil image:nil target:target action:action];

    return [self initWithCustomView:_button];
}

- (id)initWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem
                           target:(id)target
                           action:(SEL)action
{
    if (self = [super initWithBarButtonSystemItem:systemItem target:target action:action]) {
        _flags.vanilla = YES;
        [self initializeIVARs];
    }
    return self;
}

- (id)initWithCustomView:(UIView *)customView {
    if (self = [super initWithCustomView:customView]) {
        if ([customView isKindOfClass:[UIButton class]])
            self.button = (UIButton *)customView;
        else
            _flags.vanilla = YES;
        [self initializeIVARs];
    }
    return self;
}

- (void)generateButtonWithTitle:(NSString *)title
                      attributedTitle:(NSAttributedString *)attributedTitle
                                image:(UIImage *)image
                               target:(id)target
                               action:(SEL)action
{
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = DEFAULT_FRAME;
    [button setTitleColor:WhiteColor forState:UIControlStateNormal];
    [button setTitleColor:LightTextColor forState:UIControlStateHighlighted];
    [button setTitleColor:LightTextColor forState:UIControlStateSelected];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [button setImage:image forState:UIControlStateNormal];

    if (attributedTitle)
        [button setAttributedTitle:attributedTitle forState:UIControlStateNormal];
    else
        [button setTitle:title forState:UIControlStateNormal];

    self.button = button;
}

- (void)initializeIVARs {
    assert(_flags.vanilla || (_button && self.customView == _button));
}

- (void)setTitle:(NSString *)title {

    if (_flags.vanilla)
        [super setTitle:title];
    else
        [self.button setTitle:title forState:UIControlStateNormal];

}

- (void)setTitleTextAttributes:(NSDictionary *)attributes forState:(UIControlState)state {

    if (_flags.vanilla)
        [super setTitleTextAttributes:attributes forState:state];

    else {
        assert(_button);
        if (attributes[NSFontAttributeName])
            _button.titleLabel.font = attributes[NSFontAttributeName];

        if (attributes[NSForegroundColorAttributeName])
            [_button setTitleColor:attributes[NSForegroundColorAttributeName]
                          forState:state];

        if (attributes[NSShadowAttributeName])
            [_button setTitleShadowColor:((NSShadow *)attributes[NSShadowAttributeName]).shadowColor
                                forState:state];

        if (attributes[NSShadowAttributeName])
            _button.titleLabel.shadowOffset = ((NSShadow *)attributes[NSShadowAttributeName]).shadowOffset;
    }

}

- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (self.customView) [self.customView addGestureRecognizer:gestureRecognizer];
}

- (UIControlState)state { return (_button ? _button.state : UIControlStateApplication); }

- (void)setSelected:(BOOL)selected { _button.selected = selected; }
- (BOOL)isSelected { return _button.selected; }

- (void)setEnabled:(BOOL)enabled { [super setEnabled:enabled]; _button.enabled = enabled; }
- (BOOL)isEnabled { return _button.enabled; }

- (void)setHighlighted:(BOOL)highlighted { _button.highlighted = highlighted; }
- (BOOL)isHighlighted { return _button.highlighted; }

@end

