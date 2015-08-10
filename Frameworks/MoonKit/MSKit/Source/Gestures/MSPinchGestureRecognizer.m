//
//  MSPinchGestureRecognizer.m
//  Remote
//
//  Created by Jason Cardwell on 10/9/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "MSKitMacros.h"
#import "MSKitLoggingFunctions.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "MSPinchGestureRecognizer.h"
//#define IGNORE_DISTANCE_THRESHOLD



@implementation MSPinchGestureRecognizer {
    CGFloat _delta;
    CGFloat _initialDistance;
    UITouch * __strong _touches[2];
}

- (void)reset {
    [super reset];
    _delta = 0.0f;
    _initialDistance = 0.0f;
//    DDLogDebug(@"%@ delta and initial distance have been reset", ClassTagSelectorString);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    [super touchesBegan:touches withEvent:event];
    __block int idx = 0;
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        if (idx > 1)
            *stop = YES;
        else
            _touches[idx++] = obj;
    }];
    CGPoint p1 = [_touches[0] locationInView:self.view.window];
    CGPoint p2 = [_touches[1] locationInView:self.view.window];
    _initialDistance = sqrtl(powl(p2.x-p1.x, 2) + powl(p2.y-p1.y, 2));
//    DDLogDebug(@"%@ initial distance: %f", ClassTagSelectorString, _initialDistance);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

    [super touchesMoved:touches withEvent:event];
    CGPoint p1 = [_touches[0] locationInView:self.view.window];
    CGPoint p2 = [_touches[1] locationInView:self.view.window];
    CGFloat distance = sqrtl(powl(p2.x-p1.x, 2) + powl(p2.y-p1.y, 2));
    _delta = distance - _initialDistance;
//    DDLogDebug(@"%@ initial distance: %f  current distance: %f  delta: %f",
//               ClassTagSelectorString, _initialDistance, distance, _delta);
}

- (CGFloat)distance {
#ifdef IGNORE_DISTANCE_THRESHOLD
    return _delta;
#else
//    DDLogDebug(@"%@ threshold:%@  delta:%f",
//               ClassTagSelectorString, MSBoundaryString(_threshold), _delta);
    return (MSValueInBounds(_delta, _threshold)
            ? _delta
            : (_delta < _threshold.lower
               ? _threshold.lower
               : _threshold.upper
               )
            );
#endif
}

@end
