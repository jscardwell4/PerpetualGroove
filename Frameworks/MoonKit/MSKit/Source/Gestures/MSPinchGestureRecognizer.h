//
//  MSPinchGestureRecognizer.h
//  Remote
//
//  Created by Jason Cardwell on 10/9/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;
#import "MSKitGeometryFunctions.h"

@interface MSPinchGestureRecognizer : UIPinchGestureRecognizer

@property (nonatomic, readonly) CGFloat distance;
@property (nonatomic, assign) MSBoundary threshold;

@end
