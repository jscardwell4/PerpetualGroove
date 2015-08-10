//
//  MSGestureManager.h
//  MSKit
//
//  Created by Jason Cardwell on 2/22/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

@import Foundation;
@import UIKit;

/// Specification for blocks registered for gesture responses.
typedef BOOL (^ MSGestureManagerBlock)(UIGestureRecognizer *, id);

/// Specifies for which response a given block is registered.
typedef NS_ENUM (NSUInteger, MSGestureManagerResponseType){
    MSGestureManagerResponseTypeBegin                   = 0,
    MSGestureManagerResponseTypeReceiveTouch            = 1,
    MSGestureManagerResponseTypeRecognizeSimultaneously = 2,
    MSGestureManagerResponseTypeBeRequiredToFail        = 3,
    MSGestureManagerResponseTypeRequireFailureOf        = 4
};

/**
 * The `MSGestureManager` class poses as a go between for a `UIGestureRecognizerDelegate` and its
 * gestures. The manager maintains a set of gestures for which it can answer such questions as:
 *
 * - `gestureRecognizerShouldBegin:`
 * - `gestureRecognizer:shouldReceiveTouch:`
 * - `gestureRecognizer:shouldRecognizerSimultaneouslyWithOtherGestureRecognizer:`
 */
@interface MSGestureManager:NSObject

/**
 * Creates a new gesture manager for the specified gestures.
 *
 * @param gestures The gestures to manage
 *
 * @return The manager
 */
+ (instancetype)gestureManagerForGestures:(NSArray *)gestures;

/**
 * Creates a new gesture manager for the specified gestures with the specified blocks registered.
 * `blocks` contains dictionaries (or [NSNull null]) keyed by `MSGestureManagerResponseType` for
 * the gesture located at the corresponding index in `gestures`.
 *
 * @param gestures The gestures to manage
 *
 * @param blocks Array of dictionaries containing blocks for corresponding gestures
 *
 * @return The manager
 */
+ (instancetype)gestureManagerForGestures:(NSArray *)gestures blocks:(NSArray *)blocks;
+ (instancetype)gestureManagerWithGestures:(NSArray *)gestures blocks:(NSArray *)blocks;
- (instancetype)initWithGestures:(NSArray *)gestures blocks:(NSArray *)blocks;

/**
 * Invokes the registered block for the specified gesture and returns the result. Returns `YES` if
 * no block is registered.
 *
 * @param gesture The gesture that should or should not begin
 *
 * @return The answer
 */
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;

/**
 * Invokes the registered block for the specified gesture and returns the result. Returns `YES` if
 * no block is registered.
 *
 * @param gesture The gesture that should or should not begin
 *
 * @return The answer
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;

/**
 * Invokes the registered block for the specified gesture and returns the result. Returns `NO` if
 * no block is registered.
 *
 * @param gesture The gesture that should or should not begin
 *
 * @param otherGesture The other gesture
 *
 * @return The answer
 */
- (BOOL)                             gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

/**
 * Adds the specifed gesture to the set of managed gestures.
 *
 * @param gesture The gesture to manage
 */
- (void)addGesture:(UIGestureRecognizer *)gesture;

/**
 * Adds the specifed gesture to the set of managed gestures and registers the specified blocks.
 * The blocks are keyed by `MSGestureRecognizerResponseType`.
 *
 * @param gesture The gesture to manage
 *
 * @param blocks The responses to register for the gesture
 */
- (void)addGesture:(UIGestureRecognizer *)gesture withBlocks:(NSDictionary *)blocks;

/**
 * Removes the specified gesture from the set of managed gestures.
 *
 * @param gesture The gesture to remove
 */
- (void)removeGesture:(UIGestureRecognizer *)gesture;

/**
 * Sets the block used for the managed gesture for the specified response. Pass `nil` to remove
 * existing block.
 *
 * @param block The block to register
 *
 * @param response The type of response the block should be registered as
 *
 * @param gesture The gesture for which the block is to be registered
 */
- (void)registerBlock:(MSGestureManagerBlock)block
          forResponse:(MSGestureManagerResponseType)response
           forGesture:(UIGestureRecognizer *)gesture;

@end
