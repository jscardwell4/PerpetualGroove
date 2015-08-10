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

@end
