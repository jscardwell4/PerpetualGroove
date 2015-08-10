//
//  MSLongPressGestureRecognizer.m
//  MSKit
//
//  Created by Jason Cardwell on 10/13/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "MSLongPressGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "MSKitMacros.h"
#import "MSKitLoggingFunctions.h"
@import ObjectiveC;

@implementation MSLongPressGestureRecognizer {
  NSMutableArray * _mstargets;
}

/// initWithTarget:action:
/// @param target
/// @param action
/// @return id
- (id)initWithTarget:(id)target action:(SEL)action {

  if (self = [super initWithTarget:target action:action]) {
    _mstargets = [@[] mutableCopy];
    [self addTarget:target action:action];
  }

  return self;
}

/// addTarget:action:
/// @param target
/// @param action
- (void)addTarget:(id)target action:(SEL)action {

  [super addTarget:target action:action];

  if (target && action) {

    NSMethodSignature * signature = [target methodSignatureForSelector:action];
    NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:target];

    [_mstargets addObject:invocation];

  }
}

/// touchesBegan:withEvent:
/// @param touches
/// @param event
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

  for (NSInvocation * invocation in _mstargets) [invocation invoke];
  [super touchesBegan:touches withEvent:event];
  
}

@end
