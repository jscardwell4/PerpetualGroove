//
//  UIWindow+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 10/2/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;

@interface UIWindow (MSKitAdditions)
+ (UIWindow *)keyWindow;
- (NSString *)_autolayoutTrace;
@end
