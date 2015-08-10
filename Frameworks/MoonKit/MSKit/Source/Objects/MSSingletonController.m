//
//  MSSingletonController.m
//  MSKit
//
//  Created by Jason Cardwell on 9/13/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSSingletonController.h"

@interface MSSingletonController ()

@property (nonatomic, strong) UIViewController * viewController;

@end

@implementation MSSingletonController

+ (UIViewController *)viewController
{
    return ((MSSingletonController *)[self sharedInstance]).viewController;
}

- (UIViewController *)viewController
{
    if (!_viewController) self.viewController = [UIViewController new];
    return _viewController;
}

//+ (BOOL)isAbstract { return YES; }

@end
