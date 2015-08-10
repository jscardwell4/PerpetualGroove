//
//  UIGestureRecognizer+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 10/9/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "NSString+MSKitAdditions.h"
#import "UIGestureRecognizer+MSKitAdditions.h"
#import <objc/runtime.h>

static const char *kUIGestureRecognizerTagKey = "kUIGestureRecognizerTagKey";
static const char *kUIGestureRecognizerNametagKey = "kUIGestureRecognizerNametagKey";

@implementation UIGestureRecognizer (MSKitAdditions)

+ (instancetype)gestureWithTarget:(id)target action:(SEL)action
{
    return [[self alloc] initWithTarget:target action:action];
}

- (NSUInteger)tag {
    NSNumber * tagObj = objc_getAssociatedObject(self, (void *)kUIGestureRecognizerTagKey);
    return (tagObj ? tagObj.unsignedIntegerValue : 0);
}

- (void)setTag:(NSUInteger)tag {
    objc_setAssociatedObject(self,
                             (void *)kUIGestureRecognizerTagKey,
                             @(tag),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)nametag {
    return objc_getAssociatedObject(self, (void *)kUIGestureRecognizerNametagKey);
}

- (void)setNametag:(NSString *)nametag {
    objc_setAssociatedObject(self,
                             (void *)kUIGestureRecognizerNametagKey,
                             nametag,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)debugDescription {
    NSMutableString * description = [[self description] mutableCopy];
    [description insertString:$(@"(%@)", self.nametag) atIndex:[description rangeOfString:ClassString([self class])].length + 1];
    return description;
}

@end
