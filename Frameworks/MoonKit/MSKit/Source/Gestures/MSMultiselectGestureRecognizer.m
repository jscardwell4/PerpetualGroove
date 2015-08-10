//
//  MSMultiselectGestureRecognizer.m
//  MSKit
//
//  Created by Jason Cardwell on 2/20/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
#import "UIGestureRecognizer+MSKitAdditions.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "MSMultiselectGestureRecognizer.h"
#import "MSKitMacros.h"
#import "NSValue+MSKitAdditions.h"
#import "NSSet+MSKitAdditions.h"
#import "MSKitGeometryFunctions.h"
#import "NSOperationQueue+MSKitAdditions.h"
#import "MSLog.h"

static BOOL   msShouldLog = YES;
static int ddLogLevel = LOG_LEVEL_DEBUG;

#pragma unused(msShouldLog, ddLogLevel)

#define MAX_ANCHOR_MOVEMENT 5.0f

#ifdef MSDEBUG

static NSOperationQueue * _logQueue;

#define DEBUG_BLOCK_MAKE NSBlockOperation * blockOperation = [NSBlockOperation new]
#define DEBUG_BLOCK_ADD(block) [blockOperation addExecutionBlock:block]
#define DEBUG_BLOCK_EXEC [_logQueue addOperation:blockOperation]

#define DEBUG_BLOCK(block) \
    do                     \
    {                      \
        block              \
    } while(0)

#else

#define DEBUG_BLOCK(block) \
    do                     \
    {                      \
    } while(0)
#define DEBUG_BLOCK_MAKE DEBUG_BLOCK(nil)
#define DEBUG_BLOCK_ADD  DEBUG_BLOCK(nil)
#define DEBUG_BLOCK_EXEC DEBUG_BLOCK(nil)
#endif

#define LogTouchLocations(touches)                                            \
    do                                                                        \
    {                                                                         \
        if ((msShouldLog && touches.count))                                   \
        {                                                                     \
            DDLogDebug(@"\ttouch locations:\n\t\t%@",                         \
                       [[touches setByMappingToBlock:                         \
                         ^NSString *(UITouch * obj){                          \
                        return CGPointString([obj locationInView:nil]); \
                    }] componentsJoinedByString:@"\n\t\t"]);                  \
        }                                                                     \
    } while(0)

#define LogTouches(message, touches)                                               \
    do                                                                             \
    {                                                                              \
        if ((msShouldLog && touches.count))                                        \
            DDLogDebug($(@"\t%@%@", message,                                       \
                         [[touches setByMappingToBlock:^NSString *(UITouch * obj){ \
                            return $(@"%i", (int)obj);                             \
                        }] componentsJoinedByString:@", "]));                      \
    } while(0)

#define LogFail(reason)                          \
    do                                           \
    {                                            \
        if ((msShouldLog))                       \
            DDLogDebug(@"\t%s = fail", reason);  \
    } while(0)

#define LogTouchMovement(touches)                                                             \
    do                                                                                        \
    {                                                                                         \
        if ((msShouldLog && touches.count))                                                   \
            DDLogDebug(@"\t\t%@",                                                             \
                       [[touches setByMappingToBlock:^NSString *(UITouch * obj){              \
                        return $(@"\ttouch(%i): previous location: %@  current location: %@", \
                                 (int)obj,                                                    \
                                 CGPointString([obj previousLocationInView:self.view]), \
                                 CGPointString([obj locationInView:self.view]));        \
                    }] componentsJoinedByString:@"\n\t\t"]);                                  \
    } while(0)

#define LogFirstTouch                                                                        \
    do                                                                                       \
    {                                                                                        \
        if ((msShouldLog))                                                                   \
            DDLogDebug(@"\tfirst touch: %@",                                                 \
                       [NSDateFormatter localizedStringFromDate:_firstTouchDate              \
                                                      dateStyle:NSDateFormatterNoStyle       \
                                                      timeStyle:NSDateFormatterFullStyle]);  \
    } while(0)

#define LogSelector                                                                      \
    do                                                                                   \
    {                                                                                    \
        if ((msShouldLog))                                                               \
            DDLogDebug(@"[MSKit] %@", ClassTagSelectorStringForInstance(self.nametag));  \
    } while(0)

@implementation MSMultiselectGestureRecognizer {
    NSMutableDictionary * _potentialTouchLocations;

    NSMutableSet * _potentialAnchoringTouches;
    NSMutableSet * _touchLocations;
    NSMutableSet * _anchoringTouches;
    NSMutableSet * _registeredTouches;
    NSDate       * _firstTouchDate;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization
////////////////////////////////////////////////////////////////////////////////

#ifdef MSDEBUG
+ (void)initialize
{
    if (self == [MSMultiselectGestureRecognizer class])
    {
        _logQueue =
            [NSOperationQueue
         operationQueueWithName:@"com.moondeerstudios.mskit-gestures-debug"];
        [_logQueue setMaxConcurrentOperationCount:1];
    }
}
#endif

- (void)initializeIVARs
{
    _tolerance              = 0;
    _maximumNumberOfTouches = 1;
    _minimumNumberOfTouches = 1;
    _touchLocations         = [NSMutableSet set];
    _anchoringTouches       = [NSMutableSet set];
    _registeredTouches      = [NSMutableSet set];

}

- (id)init
{
    if (self = [super init]) [self initializeIVARs];

    return self;
}

- (id)initWithTarget:(id)target action:(SEL)action
{
    if (self = [super initWithTarget:target action:action]) [self initializeIVARs];

    return self;
}

- (void)reset
{
    [super reset];
    [_touchLocations            removeAllObjects];
    [_anchoringTouches          removeAllObjects];
    [_registeredTouches         removeAllObjects];
    _firstTouchDate = nil;
    self.state      = UIGestureRecognizerStatePossible;
}

- (BOOL)isAnchored { return (_numberOfAnchorTouchesRequired ? YES : NO); }

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Getting Touch Locations and Touched Subviews
////////////////////////////////////////////////////////////////////////////////

- (NSSet *)touchLocationsInView:(id)view
{
    return [_touchLocations setByMappingToBlock:^NSValue *(NSValue * obj){
        return NSValueWithCGPoint([view convertPoint:CGPointValue(obj) fromView:nil]);
    }];

}

- (NSSet *)touchedSubviewsInView:(id)view
{
    return [self touchedSubviewsInView:view ofKind:[UIView class]];
}

- (NSSet *)touchedSubviewsInView:(id)view ofKind:(__unsafe_unretained Class)kind
{
    if (!kind) return nil;

    return [[[self touchLocationsInView:view] setByMappingToBlock:^id (NSValue * obj){
            UIView * touchedView = [view hitTest:CGPointValue(obj) withEvent:nil];

            return ([touchedView isKindOfClass:kind] ? touchedView : NullObject);
        }] setByRemovingObjectsFromArray:@[view, NullObject]];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIGestureRecognizer Methods
////////////////////////////////////////////////////////////////////////////////

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{

    [_registeredTouches unionSet:touches];  // grab touches

    if (_registeredTouches.count > _maximumNumberOfTouches +_numberOfAnchorTouchesRequired)
    {
        self.state = UIGestureRecognizerStateFailed;  // too many touches = fail

        return;
    }

    if (!_firstTouchDate)
    {
        _firstTouchDate = CurrentDate;  // grab timestamp
    }

    if (self.isAnchored && _anchoringTouches.count < _numberOfAnchorTouchesRequired)
    {
        if (touches.count != _numberOfAnchorTouchesRequired)
        {
            self.state = UIGestureRecognizerStateFailed;  // too few touches = fail


            return;
        }

        [_anchoringTouches unionSet:touches];

        assert(_anchoringTouches.count == _numberOfAnchorTouchesRequired);

    }

    [_touchLocations unionSet:  // grab touch locations
     [[touches setByRemovingObjectsFromSet:_anchoringTouches]
      setByMappingToBlock:^NSValue *(UITouch * obj){
            return NSValueWithCGPoint([obj locationInView:nil]);
        }]];

}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{

    [_registeredTouches unionSet:touches];

 
    // process anchor movement
    if (self.isAnchored && [_anchoringTouches intersectsSet:touches])
    {

        NSSet * invalidAnchors = [[_anchoringTouches setByIntersectingSet:touches]
                                  filteredSetUsingPredicateWithBlock:^BOOL (UITouch * touch, NSDictionary *bindings){
            // determine whether movement from previous location is in the acceptable range
            CGPoint delta = CGPointDeltaPoint([touch previousLocationInView:nil],
                                              [touch locationInView:nil]);
            CGFloat distance = sqrtf(powf(delta.x, 2.0f) + powf(delta.y, 2.0f));

            return (distance > MAX_ANCHOR_MOVEMENT);
        }];

        if (invalidAnchors.count)
        {
            self.state = UIGestureRecognizerStateFailed;  // anchors shouldn't move
            return;
        }
    }

    // if not anchored then just add all the touch locations
    [_touchLocations unionSet:
     [touches setByMappingToBlock:^NSValue *(UITouch * obj){
            return NSValueWithCGPoint([obj locationInView:nil]);
        }]];

    self.state = UIGestureRecognizerStateChanged;

}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateCancelled;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{

    [_anchoringTouches minusSet:touches];

    [_registeredTouches minusSet:touches];

    if (!_anchoringTouches.count)
        self.state = (_touchLocations.count && SecondsSinceDate(_firstTouchDate) > _tolerance
                      ? UIGestureRecognizerStateRecognized
                      : UIGestureRecognizerStateFailed);

}

@end
