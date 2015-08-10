//
//  UIStoryboard+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 9/22/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "UIStoryboard+MSKitAdditions.h"

@implementation UIStoryboard (MSKitAdditions)

- (UIViewController *)instantiateViewControllerWithClassNameIdentifier:(Class)controllerClass
{
    return (controllerClass
            ? [self instantiateViewControllerWithIdentifier:NSStringFromClass(controllerClass)]
            : nil);

}

@end
