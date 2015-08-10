//
// MSPopupBarButtonItem.m
// MSKit
//
// Created by Jason Cardwell on 1/18/13.
// Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSPopupBarButton_Private.h"

@implementation MSPopupBarButtonItem

+ (MSPopupBarButtonItem *)itemWithTitle:(NSString *)title
                                  image:(UIImage *)image
                                 target:(id)target
                                 action:(SEL)action
{
    MSPopupBarButtonItem * item = [MSPopupBarButtonItem new];

    item.title  = title;
    item.image  = image;
    item.target = target;
    item.action = action;

    return item;
}

+ (MSPopupBarButtonItem *)itemWithAttributedTitle:(NSAttributedString *)title
                                            image:(UIImage *)image
                                           target:(id)target
                                           action:(SEL)action
{
    MSPopupBarButtonItem * item = [MSPopupBarButtonItem new];

    item.attributedTitle = title;
    item.image           = image;
    item.target          = target;
    item.action          = action;

    return item;
}

@end