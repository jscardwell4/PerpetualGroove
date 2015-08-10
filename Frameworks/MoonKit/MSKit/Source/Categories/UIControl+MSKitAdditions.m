//
//  UIControl+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 10/6/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "UIControl+MSKitAdditions.h"
#import <objc/runtime.h>

static const char * kActionBlocksKey = "kActionBlocksKey";

@implementation UIControl (MSKitAdditions)

- (NSDictionary *)actionBlocks
{
  NSDictionary * actionBlocks = objc_getAssociatedObject(self, (void *)kActionBlocksKey);
  return actionBlocks;
}

- (void)invokeActionBlocksForControlEvents:(UIControlEvents)controlEvents
{
  for (void (^action)(void) in [self actionBlocks][@(controlEvents)])
    action();
}

- (void)addActionBlock:(void (^)(void))action forControlEvents:(UIControlEvents)controlEvents
{
  NSMutableDictionary * actionBlocks = [[self actionBlocks] mutableCopy];
  if (!actionBlocks) actionBlocks = [@{} mutableCopy];
  NSArray * actionsArray = actionBlocks[@(controlEvents)];

  actionsArray = (actionsArray ? [actionsArray arrayByAddingObject:action] : @[action]);
  actionBlocks[@(controlEvents)] = actionsArray;

  objc_setAssociatedObject(self,
                           kActionBlocksKey,
                           actionBlocks,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  NSString * selectorName = [NSString stringWithFormat:@"invokeActionBlocksForControlEvents%u", (unsigned int)controlEvents];

  if (![[self actionsForTarget:self forControlEvent:controlEvents] containsObject:selectorName])
  {
    SEL selector = NSSelectorFromString(selectorName);
    if (![self respondsToSelector:selector])
    {
      class_addMethod([self class],
                      selector,
                      imp_implementationWithBlock(^(id _self)
                                                  {
                                                    [_self invokeActionBlocksForControlEvents:controlEvents];
                                                  }),
                      "v@:");
    }
    [self addTarget:self action:selector forControlEvents:controlEvents];
  }
}

- (void)removeActionBlocksForControlEvents:(UIControlEvents)controlEvents
{
  NSMutableDictionary * actionBlocks = [[self actionBlocks] mutableCopy];
  if (actionBlocks) [actionBlocks removeObjectForKey:@(controlEvents)];

  objc_setAssociatedObject(self,
                           kActionBlocksKey,
                           actionBlocks,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
