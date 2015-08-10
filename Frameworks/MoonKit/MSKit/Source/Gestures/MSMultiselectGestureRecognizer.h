//
//  MSMultiselectGestureRecognizer.h
//  MSKit
//
//  Created by Jason Cardwell on 2/20/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;

@interface MSMultiselectGestureRecognizer : UIGestureRecognizer

/**
 * Provides access to the current array of touch locations as converted to the specified view.
 *
 * @param view The view to use in `CGPoint` conversions
 *
 * @return The array of `CGPoint` values
 */
- (NSSet *)touchLocationsInView:(id)view;

/**
 * Provides the set of subviews of the specified view for which touchs have been registered.
 *
 * @param view The view whose subviews will be tested
 *
 * @return The set of touched subviews for `view`
 */
- (NSSet *)touchedSubviewsInView:(id)view;

/**
 * Provides the set of subviews of the specified view for which touchs have been registered and
 * which are a kind of the specified `Class`.
 *
 * @param view The view whose subviews will be tested
 *
 * @param kind Class to filter for
 *
 * @return The set of touched subviews for `view` of the specified `kind`
 */
- (NSSet *)touchedSubviewsInView:(id)view ofKind:(Class)kind;

/// Time in seconds to allow before gesture can be said to have been recognized or has failed
@property (nonatomic, assign) CGFloat                       tolerance;
@property (nonatomic, assign) NSUInteger                    maximumNumberOfTouches;
@property (nonatomic, assign) NSUInteger                    minimumNumberOfTouches;
@property (nonatomic, readonly, getter = isAnchored) BOOL   anchored;
@property (nonatomic, assign) NSUInteger                    numberOfAnchorTouchesRequired;

@end
