//
// MSPopupBarButton.m
// MSKit
//
// Created by Jason Cardwell on 1/18/13.
// Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSPopupBarButton_Private.h"

#define HIGHLIGHT_COLOR [UIColor colorWithRed:0 green:175 / 255.0 blue:1 alpha:1]

@implementation MSPopupBarButton {
    UITapGestureRecognizer * _tapGesture;
}

- (void)initializeIVARs {

    [super initializeIVARs];

    _items = [@[] mutableCopy];

    assert(self.button && self.customView == self.button);

    [self.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.button addTarget:self
                    action:@selector(popupAction:)
          forControlEvents:UIControlEventTouchUpInside];
    [self.button setTitleColor:WhiteColor forState:UIControlStateNormal];
    [self.button setTitleColor:HIGHLIGHT_COLOR forState:UIControlStateHighlighted];
    [self.button setTitleColor:HIGHLIGHT_COLOR forState:UIControlStateSelected];
    [self.button setTitleColor:GrayColor forState:UIControlStateDisabled];

}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Actions
////////////////////////////////////////////////////////////////////////////////

- (void)setAction:(SEL)action {}

- (void)setTarget:(id)target {}

- (void)showPopover {

    if (!_popupView) _popupView = [MSPopupBarButtonView popupViewForBarButton:self];

    self.window = self.button.window;

    [_window addSubview:_popupView];

    self.button.selected = YES;

    if ([_delegate respondsToSelector:@selector(popupBarButtonDidShowPopover:)])
        [_delegate popupBarButtonDidShowPopover:self];

    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hidePopover)];
    _tapGesture.delegate = self;

    [_window addGestureRecognizer:_tapGesture];
}

- (void)hidePopover {

    [_popupView removeFromSuperview];

    self.button.selected = NO;

    if ([_delegate respondsToSelector:@selector(popupBarButtonDidHidePopover:)])
        [_delegate popupBarButtonDidHidePopover:self];

    [_window removeGestureRecognizer:_tapGesture];

    _tapGesture = nil;
    _window = nil;
    
}

- (void)popupAction:(id)sender {

    if (self.button.selected)
        [self hidePopover];

    else
        [self showPopover];
    
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Gestures
////////////////////////////////////////////////////////////////////////////////

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer { return YES; }

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch
{
    return ![touch.view isDescendantOfView:_popupView];
}

- (BOOL)                             gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Items
////////////////////////////////////////////////////////////////////////////////

- (void)addItem:(MSPopupBarButtonItem *)item {
    [_items addObject:item];
}

- (void)addItemWithTitle:(NSString *)title
                   image:(UIImage *)image
                  target:(id)target
                  action:(SEL)action
{
    assert(title || image);
    [self addItem:[MSPopupBarButtonItem itemWithTitle:title
                                                image:image
                                               target:target
                                               action:action]];
}

- (void)addItemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    [self addItemWithTitle:title image:nil target:target action:action];
}

- (void)addItemWithAttributedTitle:(NSAttributedString *)title
                             image:(UIImage *)image
                            target:(id)target
                            action:(SEL)action
{
    assert(title||image);
    [self addItem:[MSPopupBarButtonItem itemWithAttributedTitle:title
                                                          image:image
                                                         target:target
                                                         action:action]];
}

- (void)addItemWithAttributedTitle:(NSAttributedString *)title
                            target:(id)target
                            action:(SEL)action
{
    [self addItemWithAttributedTitle:title image:nil target:target action:action];
}

- (void)addItemWithImage:(UIImage *)image target:(id)target action:(SEL)action {
    [self addItemWithTitle:nil image:image target:target action:action];
}

- (void)insertItem:(MSPopupBarButtonItem *)item atIndex:(NSUInteger)idx {
    assert(idx < _items.count);
    [_items insertObject:item atIndex:idx];
}

- (void)insertItemWithTitle:(NSString *)title
                      image:(UIImage *)image
                     target:(id)target
                     action:(SEL)action
                      index:(NSUInteger)idx
{
    assert(title || image);
    [self insertItem:[MSPopupBarButtonItem itemWithTitle:title
                                                   image:image
                                                  target:target
                                                  action:action]
             atIndex:idx];
}

- (void)insertItemWithTitle:(NSString *)title
                     target:(id)target
                     action:(SEL)action
                      index:(NSUInteger)idx
{
    [self insertItemWithTitle:title image:nil target:target action:action index:idx];
}

- (void)insertItemWithAttributedTitle:(NSAttributedString *)title
                                image:(UIImage *)image
                               target:(id)target
                               action:(SEL)action
                                index:(NSUInteger)idx
{
    assert(title || image);
    [self insertItem:[MSPopupBarButtonItem itemWithAttributedTitle:title
                                                             image:image
                                                            target:target
                                                            action:action]
             atIndex:idx];
}

- (void)insertItemWithAttributedTitle:(NSAttributedString *)title
                               target:(id)target
                               action:(SEL)action
                                index:(NSUInteger)idx
{
    [self insertItemWithAttributedTitle:title image:nil target:target action:action index:idx];
}

- (void)insertItemWithImage:(UIImage *)image
                     target:(id)target
                     action:(SEL)action
                      index:(NSUInteger)idx
{
    [self insertItemWithTitle:nil image:image target:target action:action index:idx];
}

@end
