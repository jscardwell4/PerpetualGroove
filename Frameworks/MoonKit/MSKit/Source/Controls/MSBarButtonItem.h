//
// MSBarButtonItem.h
// MSKit
//
// Created by Jason Cardwell on 2/14/13.
// Copyright (c) 2013 Moondeer Studios. All rights reserved.
//


@import Foundation;
@import UIKit;

@interface MSBarButtonItem : UIBarButtonItem

- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer;

@property (nonatomic, getter = isHighlighted) BOOL   highlighted;
@property (nonatomic, getter = isSelected) BOOL      selected;
@property (nonatomic, readonly) UIControlState       state;
@property (nonatomic, strong, readonly) UIButton   * button;

@end
