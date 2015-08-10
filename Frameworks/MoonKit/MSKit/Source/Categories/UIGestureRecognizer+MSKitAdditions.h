//
//  UIGestureRecognizer+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 10/9/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

@import Foundation;
@import UIKit;
#import "MSKitDefines.h"

@interface UIGestureRecognizer (MSKitAdditions)

+ (instancetype)gestureWithTarget:(id)target action:(SEL)action;

@property (nonatomic, assign) NSUInteger tag;
@property (nonatomic, strong) NSString * nametag;

@end

MSSTATIC_INLINE NSString * NSStringFromUIGestureRecognizerState(UIGestureRecognizerState state)
{
	NSString *gestureRecognizerStateString = nil;
	switch (state) {
		case UIGestureRecognizerStatePossible:
			gestureRecognizerStateString = @"UIGestureRecognizerStatePossible";
			break;

		case UIGestureRecognizerStateBegan:
			gestureRecognizerStateString = @"UIGestureRecognizerStateBegan";
			break;

		case UIGestureRecognizerStateChanged:
			gestureRecognizerStateString = @"UIGestureRecognizerStateChanged";
			break;

		case UIGestureRecognizerStateEnded:
			gestureRecognizerStateString = @"UIGestureRecognizerStateRecognized";
			break;

		case UIGestureRecognizerStateCancelled:
			gestureRecognizerStateString = @"UIGestureRecognizerStateCancelled";
			break;

		case UIGestureRecognizerStateFailed:
			gestureRecognizerStateString = @"UIGestureRecognizerStateFailed";
			break;

	}
	return gestureRecognizerStateString;
}

