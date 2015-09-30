//
//  UIControl+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 10/6/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;

@interface UIControl (MSKitAdditions)

- (void)addActionBlock:(void (^)(void))action forControlEvents:(UIControlEvents)controlEvents;
- (void)invokeActionBlocksForControlEvents:(UIControlEvents)controlEvents;
- (void)removeActionBlocksForControlEvents:(UIControlEvents)controlEvents;

@property(nonatomic,getter=isEnabled) IBInspectable BOOL enabled;
@property(nonatomic,getter=isSelected) IBInspectable BOOL selected;
@property(nonatomic,getter=isHighlighted) IBInspectable BOOL highlighted;

@end
