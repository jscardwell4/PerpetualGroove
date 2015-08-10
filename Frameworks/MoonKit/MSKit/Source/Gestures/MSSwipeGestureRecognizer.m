//
//  MSSwipeGestureRecognizer.m
//  MSKit
//
//  Created by Jason Cardwell on 3/21/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "NSSet+MSKitAdditions.h"
#import "MSSwipeGestureRecognizer.h"
#import "MSKVOReceptionist.h"

@implementation MSSwipeGestureRecognizer {
    MSKVOReceptionist * _kvoReceptionist;
    struct {
        CGRect right;
        CGRect left;
        CGRect up;
        CGRect down;
    } _quads;
}

- (id)init {
    if (self = [super init])
        [self initializeIVARs];
    return self;
}

- (id)initWithTarget:(id)target action:(SEL)action {
    if (self = [super initWithTarget:target action:action])
        [self initializeIVARs];
    return self;
}

- (void)initializeIVARs {
    _quads.right = _quads.left = _quads.up = _quads.down = CGRectZero;
    _kvoReceptionist = [MSKVOReceptionist
                        receptionistWithObserver:self
                        forObject:self
                        keyPath:@"view"
                        options:NSKeyValueObservingOptionNew
                        queue:[NSOperationQueue mainQueue]
                        handler:^(MSKVOReceptionist * receptionist){
                          [(MSSwipeGestureRecognizer *)receptionist.observer updateQuads];
                        }];
}

- (void)updateQuads {
    if (self.view && !CGRectIsEmpty(self.view.bounds))
    {
        CGRect bounds = self.view.bounds;
        CGRectDivide(bounds, &_quads.left, &_quads.right, bounds.size.width / 2.0f, CGRectMinXEdge);
        CGRectDivide(bounds, &_quads.up, &_quads.down, bounds.size.height / 2.0f, CGRectMinYEdge);
    }

    else
    {
        _quads.right = _quads.left = _quads.up = _quads.down = CGRectZero;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    __weak UIView * view = self.view;
    if (self.state == UIGestureRecognizerStatePossible && _quadrant
        && ![touches objectPassingTest:^BOOL(UITouch * touch) {
        CGPoint location = [touch locationInView:view];
        if (   (_quadrant & MSSwipeGestureRecognizerQuadrantLeft)
            && !CGRectContainsPoint(_quads.left, location)) return NO;
        else if (   (_quadrant & MSSwipeGestureRecognizerQuadrantRight)
            && !CGRectContainsPoint(_quads.right, location)) return NO;
        else if (   (_quadrant & MSSwipeGestureRecognizerQuadrantUp)
            && !CGRectContainsPoint(_quads.up, location)) return NO;
        else if (   (_quadrant & MSSwipeGestureRecognizerQuadrantDown)
            && !CGRectContainsPoint(_quads.down, location)) return NO;
        else return YES;
    }]) self.state = UIGestureRecognizerStateFailed;

    else
        [super touchesBegan:touches withEvent:event];
}

@end
