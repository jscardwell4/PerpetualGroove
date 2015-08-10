//
// MSPopupBarButton.h
// MSKit
//
// Created by Jason Cardwell on 1/18/13.
// Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "MSBarButtonItem.h"

@protocol MSPopupBarButtonDelegate;

@interface MSPopupBarButton : MSBarButtonItem

- (void)addItemWithTitle:(NSString *)title
                   image:(UIImage *)image
                  target:(id)target
                  action:(SEL)action;
- (void)addItemWithTitle:(NSString *)title
                  target:(id)target
                  action:(SEL)action;
- (void)addItemWithAttributedTitle:(NSAttributedString *)title
                             image:(UIImage *)image
                            target:(id)target
                            action:(SEL)action;
- (void)addItemWithAttributedTitle:(NSAttributedString *)title
                            target:(id)target
                            action:(SEL)action;
- (void)addItemWithImage:(UIImage *)image
                  target:(id)target
                  action:(SEL)action;
- (void)insertItemWithTitle:(NSString *)title
                      image:(UIImage *)image
                     target:(id)target
                     action:(SEL)action
                      index:(NSUInteger)idx;
- (void)insertItemWithTitle:(NSString *)title
                     target:(id)target
                     action:(SEL)action
                      index:(NSUInteger)idx;
- (void)insertItemWithAttributedTitle:(NSAttributedString *)title
                                image:(UIImage *)image
                               target:(id)target
                               action:(SEL)action
                                index:(NSUInteger)idx;
- (void)insertItemWithAttributedTitle:(NSAttributedString *)title
                               target:(id)target
                               action:(SEL)action
                                index:(NSUInteger)idx;
- (void)insertItemWithImage:(UIImage *)image
                     target:(id)target
                     action:(SEL)action
                      index:(NSUInteger)idx;
- (void)showPopover;
- (void)hidePopover;

@property (nonatomic, weak) IBOutlet id<MSPopupBarButtonDelegate>   delegate;

@end

@protocol MSPopupBarButtonDelegate <NSObject>

@optional
- (void)popupBarButtonDidShowPopover:(MSPopupBarButton *)popupBarButton;
- (void)popupBarButtonDidHidePopover:(MSPopupBarButton *)popupBarButton;

@end
