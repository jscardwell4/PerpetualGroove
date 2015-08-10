//
//  MSSwipeGestureRecognizer.h
//  MSKit
//
//  Created by Jason Cardwell on 3/21/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;

typedef NS_OPTIONS(NSUInteger, MSSwipeGestureRecognizerQuadrant) {
    MSSwipeGestureRecognizerQuadrantRight = 1 << 0,
    MSSwipeGestureRecognizerQuadrantLeft  = 1 << 1,
    MSSwipeGestureRecognizerQuadrantUp    = 1 << 2,
    MSSwipeGestureRecognizerQuadrantDown  = 1 << 3
};

@interface MSSwipeGestureRecognizer : UISwipeGestureRecognizer

@property (nonatomic) MSSwipeGestureRecognizerQuadrant quadrant;

@end
