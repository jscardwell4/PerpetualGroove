//
//  UIView+MSKitAdditions.m
//  Remote
//
//  Created by Jason Cardwell on 4/12/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "MSKitMacros.h"
#import "MSKitGeometryFunctions.h"
#import "UIView+MSKitAdditions.h"
#import <objc/runtime.h>
//#import "NSLayoutConstraint+MSKitAdditions.h"
#import "NSString+MSKitAdditions.h"
#import "NSArray+MSKitAdditions.h"
#import "UIGestureRecognizer+MSKitAdditions.h"
#import "UIImage+ImageEffects.h"
#import "NSDictionary+MSKitAdditions.h"
static const void *UIViewNametagKey = &UIViewNametagKey;

@implementation UIView (MSKitAdditions)

/// nametag
/// @return id
- (NSString *)nametag { return objc_getAssociatedObject(self, UIViewNametagKey); }

/// setNametag:
/// @param nametag
- (void)setNametag:(NSString *)nametag {
  objc_setAssociatedObject(self, UIViewNametagKey, nametag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/// subviewsOfKind:
/// @param kind
/// @return NSArray *
- (NSArray *)subviewsOfKind:(Class)kind {
  return [self.subviews filtered:^BOOL (id obj) { return [obj isKindOfClass:kind]; }];
}

/// subviewsOfType:
/// @param type
/// @return NSArray *
- (NSArray *)subviewsOfType:(Class)type {
  return [self.subviews filtered:^BOOL (id obj) { return [obj isMemberOfClass:type]; }];
}

/// newForAutolayout
/// @return instancetype
+ (instancetype)newForAutolayout {
  UIView * view = [self new];
  if (view) view.translatesAutoresizingMaskIntoConstraints = NO;
  return view;
}

/// initForAutoLayout
/// @return instancetype
- (instancetype)initForAutoLayout {
  if ((self = [self init])) self.translatesAutoresizingMaskIntoConstraints = NO;
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame autolayout:(BOOL)autolayout {
  if ((self = [self initWithFrame:frame]))
    self.translatesAutoresizingMaskIntoConstraints = autolayout;
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame nametag:(NSString *)nametag autolayout:(BOOL)autolayout {
  if ((self = [self initWithFrame:frame])) {
    self.translatesAutoresizingMaskIntoConstraints = autolayout;
    self.nametag = nametag;
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame nametag:(NSString *)nametag {
  if ((self = [self initWithFrame:frame])) {
    self.nametag = nametag;
  }
  return self;
}

- (instancetype)initWithNametag:(NSString *)nametag autolayout:(BOOL)autolayout {
  if ((self = [self init])) {
    self.translatesAutoresizingMaskIntoConstraints = autolayout;
    self.nametag = nametag;
  }
  return self;
}


/// initForAutoLayoutWithFrame:
/// @param frame
/// @return instancetype
- (instancetype)initForAutoLayoutWithFrame:(CGRect)frame {
  if ((self = [self initWithFrame:frame]))
    self.translatesAutoresizingMaskIntoConstraints = NO;

  return self;
}

/// minX
/// @return CGFloat
- (CGFloat)minX { return CGRectGetMinX(self.frame); }

/// minY
/// @return CGFloat
- (CGFloat)minY { return CGRectGetMinY(self.frame); }

/// maxX
/// @return CGFloat
- (CGFloat)maxX { return CGRectGetMaxX(self.frame); }

/// maxY
/// @return CGFloat
- (CGFloat)maxY { return CGRectGetMaxY(self.frame); }

/// height
/// @return CGFloat
- (CGFloat)h { return self.bounds.size.height; }

/// width
/// @return CGFloat
- (CGFloat)w { return self.bounds.size.width; }

/// viewMatching:
/// @param predicate
/// @return UIView *
- (UIView *)viewMatching:(NSPredicate *)predicate {
  return ([predicate evaluateWithObject:self] ? self :  [self.subviews findFirstUsingPredicate:predicate]);
}

/// viewsMatching:
/// @param predicate
/// @return NSArray *
- (NSArray *)viewsMatching:(NSPredicate *)predicate {
  return [[self.subviews arrayByAddingObject:self] filteredUsingPredicate:predicate];
}

/// subviewMatching:
/// @param predicate
/// @return UIView *
- (UIView *)subviewMatching:(NSPredicate *)predicate {
  return [self.subviews findFirstUsingPredicate:predicate];
}

/// subviewsMatching:
/// @param predicate
/// @return NSArray *
- (NSArray *)subviewsMatching:(NSPredicate *)predicate {
  return [self.subviews filteredUsingPredicate:predicate];
}

/// viewWithNametag:
/// @param nametag
/// @return UIView *
- (UIView *)viewWithNametag:(NSString *)nametag {
  return [self viewMatching:[NSPredicate predicateWithFormat:@"self.nametag == %@", nametag]];
}

/// viewsWithNametag:
/// @param nametag
/// @return NSArray *
- (NSArray *)viewsWithNametag:(NSString *)nametag {
  return [self viewsMatching:[NSPredicate predicateWithFormat:@"self.nametag == %@", nametag]];
}

/// subviewWithNametag:
/// @param nametag
/// @return UIView *
- (UIView *)subviewWithNametag:(NSString *)nametag {
  return [self subviewMatching:[NSPredicate predicateWithFormat:@"self.nametag == %@", nametag]];
}

/// subviewsWithNametag:
/// @param nametag
/// @return NSArray *
- (NSArray *)subviewsWithNametag:(NSString *)nametag {
  return [self subviewsMatching:[NSPredicate predicateWithFormat:@"self.nametag == %@", nametag]];
}

/// viewWithNametagPrefix:
/// @param prefix
/// @return UIView *
- (UIView *)viewWithNametagPrefix:(NSString *)prefix {
  return [self viewMatching:[NSPredicate predicateWithFormat:@"self.nametag beginsWith %@", prefix]];
}

/// viewsWithNametagPrefix:
/// @param prefix
/// @return NSArray *
- (NSArray *)viewsWithNametagPrefix:(NSString *)prefix {
  return [self viewsMatching: [NSPredicate predicateWithFormat:@"self.nametag beginsWith %@", prefix]];
}

/// subviewWithNametagPrefix:
/// @param prefix
/// @return UIView *
- (UIView *)subviewWithNametagPrefix:(NSString *)prefix {
  return [self subviewMatching:[NSPredicate predicateWithFormat:@"self.nametag beginsWith %@", prefix]];
}

/// subviewsWithNametagPrefix:
/// @param prefix
/// @return NSArray *
- (NSArray *)subviewsWithNametagPrefix:(NSString *)prefix {
  return [self subviewsMatching:[NSPredicate predicateWithFormat:@"self.nametag beginsWith %@", prefix]];
}

/// viewWithNametagSuffix:
/// @param suffix
/// @return UIView *
- (UIView *)viewWithNametagSuffix:(NSString *)suffix {
  return [self viewMatching:[NSPredicate predicateWithFormat:@"self.nametag endsWith %@", suffix]];
}

/// viewsWithNametagSuffix:
/// @param suffix
/// @return NSArray *
- (NSArray *)viewsWithNametagSuffix:(NSString *)suffix {
  return [self viewsMatching:[NSPredicate predicateWithFormat:@"self.nametag endsWith %@", suffix]];
}

/// subviewWithNametagSuffix:
/// @param suffix
/// @return UIView *
- (UIView *)subviewWithNametagSuffix:(NSString *)suffix {
  return [self subviewMatching:[NSPredicate predicateWithFormat:@"self.nametag endsWith %@", suffix]];
}

/// subviewsWithNametagSuffix:
/// @param suffix
/// @return NSArray *
- (NSArray *)subviewsWithNametagSuffix:(NSString *)suffix {
  return [self subviewsMatching:[NSPredicate predicateWithFormat:@"self.nametag endsWith %@", suffix]];
}

/// gestureMatching:
/// @param predicate
/// @return UIGestureRecognizer *
- (UIGestureRecognizer *)gestureMatching:(NSPredicate *)predicate {
  return [self.gestureRecognizers findFirstUsingPredicate:predicate];
}

/// gesturesMatching:
/// @param predicate
/// @return NSArray *
- (NSArray *)gesturesMatching:(NSPredicate *)predicate {
  return [self.gestureRecognizers filteredUsingPredicate:predicate];
}

/// gestureWithNametag:
/// @param nametag
/// @return UIGestureRecognizer *
- (UIGestureRecognizer *)gestureWithNametag:(NSString *)nametag {
  return [self gestureMatching:[NSPredicate predicateWithFormat:@"self.nametag == %@", nametag]];
}

/// gesturesWithNametag:
/// @param nametag
/// @return NSArray *
- (NSArray *)gesturesWithNametag:(NSString *)nametag {
  return [self gesturesMatching:[NSPredicate predicateWithFormat:@"self.nametag == %@", nametag]];
}

/// gestureWithNametagPrefix:
/// @param prefix
/// @return UIGestureRecognizer *
- (UIGestureRecognizer *)gestureWithNametagPrefix:(NSString *)prefix {
  return [self gestureMatching:[NSPredicate predicateWithFormat:@"self.nametag beginsWith %@", prefix]];
}

/// gesturesWithNametagPrefix:
/// @param prefix
/// @return NSArray *
- (NSArray *)gesturesWithNametagPrefix:(NSString *)prefix {
  return [self gesturesMatching:[NSPredicate predicateWithFormat:@"self.nametag beginsWith %@", prefix]];
}

/// gestureWithNametagSuffix:
/// @param suffix
/// @return UIGestureRecognizer *
- (UIGestureRecognizer *)gestureWithNametagSuffix:(NSString *)suffix {
  return [self gestureMatching:[NSPredicate predicateWithFormat:@"self.nametag endsWith %@", suffix]];
}

/// gesturesWithNametagSuffix:
/// @param suffix
/// @return NSArray *
- (NSArray *)gesturesWithNametagSuffix:(NSString *)suffix {
  return [self gesturesMatching:[NSPredicate predicateWithFormat:@"self.nametag endsWith %@", suffix]];
}

/// constraintWithTag:
/// @param tag
/// @return NSLayoutConstraint *
- (NSLayoutConstraint *)constraintWithTag:(NSUInteger)tag {
  return [self.constraints findFirstUsingPredicate:[NSPredicate predicateWithFormat:@"self.tag == %@", tag]];
}

/// constraintsWithTag:
/// @param tag
/// @return NSArray *
- (NSArray *)constraintsWithTag:(NSUInteger)tag {
  return [self.constraints filteredUsingPredicate:[NSPredicate predicateWithFormat:@"self.tag == %@", tag]];
}

/// constraintMatching:
/// @param predicate
/// @return NSLayoutConstraint *
- (NSLayoutConstraint *)constraintMatching:(NSPredicate *)predicate {
  return [self.constraints findFirstUsingPredicate:predicate];
}

/// constraintsMatching:
/// @param predicate
/// @return NSArray *
- (NSArray *)constraintsMatching:(NSPredicate *)predicate {
  return [self.constraints filteredUsingPredicate:predicate];
}

/// constraintWithNametag:
/// @param nametag
/// @return NSLayoutConstraint *
- (NSLayoutConstraint *)constraintWithNametag:(NSString *)nametag {
  return [self constraintWithIdentifier:nametag];
}

/// constraintsWithNametag:
/// @param nametag
/// @return NSArray *
- (NSArray *)constraintsWithNametag:(NSString *)nametag {
  return [self constraintsWithIdentifier:nametag];
}

/// constraintWithNametagPrefix:
/// @param prefix
/// @return NSLayoutConstraint *
- (NSLayoutConstraint *)constraintWithNametagPrefix:(NSString *)prefix {
  return [self constraintWithIdentifierPrefix:prefix];
}

/// constraintsWithNametagPrefix:
/// @param prefix
/// @return NSArray *
- (NSArray *)constraintsWithNametagPrefix:(NSString *)prefix {
  return [self constraintsWithIdentifierPrefix:prefix];
}

/// constraintWithNametagSuffix:
/// @param suffix
/// @return NSLayoutConstraint *
- (NSLayoutConstraint *)constraintWithNametagSuffix:(NSString *)suffix {
  return [self constraintWithIdentifierSuffix:suffix];
}

/// constraintsWithNametagSuffix:
/// @param suffix
/// @return NSArray *
- (NSArray *)constraintsWithNametagSuffix:(NSString *)suffix {
  return [self constraintsWithIdentifierSuffix:suffix];
}

/// replaceConstraintWithNametag:withConstraint:
/// @param nametag
/// @param constraint
- (void)replaceConstraintWithNametag:(NSString *)nametag withConstraint:(NSLayoutConstraint *)constraint {
  [self replaceConstraintWithIdentifier:nametag withConstraint:constraint];
}

/// replaceConstraintsWithNametag:withConstraints:
/// @param nametag
/// @param constraints
- (void)replaceConstraintsWithNametag:(NSString *)nametag withConstraints:(NSArray *)constraints {
  [self replaceConstraintsWithIdentifier:nametag withConstraints:constraints];
}

/// constraintWithIdentifier:
/// @param identifier
/// @return NSLayoutConstraint *
- (NSLayoutConstraint *)constraintWithIdentifier:(NSString *)identifier {
  return [self constraintMatching:[NSPredicate predicateWithFormat:@"self.identifier == %@", identifier]];
}

/// constraintsWithIdentifier:
/// @param identifier
/// @return NSArray *
- (NSArray *)constraintsWithIdentifier:(NSString *)identifier {
  return [self constraintsMatching:[NSPredicate predicateWithFormat:@"self.identifier == %@", identifier]];
}

/// constraintWithIdentifierPrefix:
/// @param prefix
/// @return NSLayoutConstraint *
- (NSLayoutConstraint *)constraintWithIdentifierPrefix:(NSString *)prefix {
  return [self constraintMatching:[NSPredicate predicateWithFormat:@"self.identifier beginsWith %@", prefix]];
}

/// constraintsWithIdentifierPrefix:
/// @param prefix
/// @return NSArray *
- (NSArray *)constraintsWithIdentifierPrefix:(NSString *)prefix {
  return [self constraintsMatching:[NSPredicate predicateWithFormat:@"self.identifier beginsWith %@", prefix]];
}

/// constraintWithIdentifierSuffix:
/// @param suffix
/// @return NSLayoutConstraint *
- (NSLayoutConstraint *)constraintWithIdentifierSuffix:(NSString *)suffix {
  return [self constraintMatching:[NSPredicate predicateWithFormat:@"self.identifier endsWith %@", suffix]];
}

/// constraintsWithIdentifierSuffix:
/// @param suffix
/// @return NSArray *
- (NSArray *)constraintsWithIdentifierSuffix:(NSString *)suffix {
  return [self constraintsMatching:[NSPredicate predicateWithFormat:@"self.identifier endsWith %@", suffix]];
}

/// replaceConstraintWithIdentifier:withConstraint:
/// @param identifier
/// @param constraint
- (void)replaceConstraintWithIdentifier:(NSString *)identifier withConstraint:(NSLayoutConstraint *)constraint {

  NSLayoutConstraint * oldConstraint = [self constraintWithIdentifier:identifier];

  if (oldConstraint) [self removeConstraint:oldConstraint];

  if (constraint) {
    constraint.identifier = identifier;
    [self addConstraint:constraint];
  }

}

/// replaceConstraintsWithIdentifier:withConstraints:
/// @param identifier
/// @param constraints
- (void)replaceConstraintsWithIdentifier:(NSString *)identifier withConstraints:(NSArray *)constraints {

  NSArray * oldConstraints = [self constraintsWithIdentifier:identifier];

  if (oldConstraints) [self removeConstraints:oldConstraints];

  if (constraints) {
    [constraints setValue:identifier forKeyPath:@"identifier"];
    [self addConstraints:constraints];
  }

}

/// constraintsOfType:
/// @param type
/// @return NSArray *
- (NSArray *)constraintsOfType:(Class)type {
  return [self.constraints filtered:^BOOL (id evaluatedObject) {
    return [evaluatedObject isMemberOfClass:type];
  }];
}

/// replaceConstraintsOfType:withConstraints:
/// @param type
/// @param constraints
- (void)replaceConstraintsOfType:(Class)type withConstraints:(NSArray *)constraints {
  [self removeConstraints:[self constraintsOfType:type]];
  [self addConstraints:constraints];
}

/// replaceConstraintsWithNametagPrefix:withConstraints:
/// @param prefix
/// @param constraints
- (void)replaceConstraintsWithNametagPrefix:(NSString *)prefix withConstraints:(NSArray *)constraints {
  [self replaceConstraintsWithIdentifierPrefix:prefix withConstraints:constraints];
}

/// replaceConstraintsWithIdentifierPrefix:withConstraints:
/// @param prefix
/// @param constraints
- (void)replaceConstraintsWithIdentifierPrefix:(NSString *)prefix withConstraints:(NSArray *)constraints {

  [self endEditing:YES];

  NSArray * oldConstraints = [self constraintsWithIdentifierPrefix:prefix];

  if (oldConstraints) [self removeConstraints:oldConstraints];

  if (constraints) {

    for (NSLayoutConstraint * constraint in constraints) {
      if (![constraint.identifier hasPrefix:prefix])
        constraint.identifier = [prefix stringByAppendingFormat:@"-%@", constraint.identifier];
    }

    [self addConstraints:constraints];

  }

}

- (void)replaceConstraintsWithIdentifierSuffix:(NSString *)suffix withConstraints:(NSArray *)constraints {

  [self endEditing:YES];

  NSArray * oldConstraints = [self constraintsWithIdentifierSuffix:suffix];

  if (oldConstraints) [self removeConstraints:oldConstraints];

  if (constraints) {

    for (NSLayoutConstraint * constraint in constraints) {
      if (![constraint.identifier hasSuffix:suffix])
        constraint.identifier = [constraint.identifier stringByAppendingFormat:@"-%@", suffix];
    }

    [self addConstraints:constraints];

  }

}
- (void)removeConstraintWithIdentifier:(NSString *)identifier {
  [self replaceConstraintWithIdentifier:identifier withConstraint:nil];
}

- (void)removeConstraintsWithIdentifier:(NSString *)identifier {
  [self replaceConstraintsWithIdentifier:identifier withConstraints:nil];
}

- (void)removeConstraintsWithIdentifierPrefix:(NSString *)prefix {
  [self replaceConstraintsWithIdentifierPrefix:prefix withConstraints:nil];
}

- (void)removeConstraintsWithIdentifierSuffix:(NSString *)suffix {
  [self replaceConstraintsWithIdentifierSuffix:suffix withConstraints:nil];
}

/// repositionFrameAtOrigin:
/// @param origin
- (void)repositionFrameAtOrigin:(CGPoint)origin { self.frame = CGRectReposition(self.frame, origin); }

/// resizeFrameToSize:anchored:
/// @param size
/// @param anchored
- (void)resizeFrameToSize:(CGSize)size anchored:(BOOL)anchored {
  self.frame = (anchored ? CGRectAnchoredResize(self.frame, size) : CGRectResize(self.frame, size));
}

/// resizeBoundsToSize:
/// @param size
- (void)resizeBoundsToSize:(CGSize)size { self.bounds = CGRectResize(self.bounds, size); }

/// unionFrameForViews:
/// @param views
/// @return CGRect
+ (CGRect)unionFrameForViews:(NSArray *)views {

  CGRect unionFrame = CGRectZero;

  if ([views count]) {

    unionFrame = ((UIView *)views[0]).frame;

    for (int i = 1; i < views.count; i++) unionFrame = CGRectUnion(unionFrame, ((UIView *)views[i]).frame);

  }

  return unionFrame;
}

/// fitFrameToSize:anchored:
/// @param size
/// @param anchored
- (void)fitFrameToSize:(CGSize)size anchored:(BOOL)anchored {
  [self resizeFrameToSize:CGSizeAspectMappedToSize(self.frame.size, size, YES) anchored:anchored];
}

/// fitBoundsToSize:
/// @param size
- (void)fitBoundsToSize:(CGSize)size {
  [self resizeBoundsToSize:CGSizeAspectMappedToSize(self.bounds.size, size, YES)];
}

/// currentResponder
/// @return UIView *
+ (UIView *)currentResponder { return [UIView firstResponderInView:[SharedApp keyWindow]]; }

/// firstResponderInView:
/// @param topView
/// @return UIView *
+ (UIView *)firstResponderInView:(UIView *)topView {

  __block BOOL     stop           = NO;
  __block UIView * firstResponder = nil;

  __block void (^findFirstResponder)(UIView *, UIView **, BOOL *) = nil;
  __block void(__weak ^ weakFindFirstResponder)(UIView *, UIView **, BOOL *) = findFirstResponder;

  findFirstResponder = ^(UIView * view, UIView ** firstResponder, BOOL * stop) {

    if (!*stop && [view isFirstResponder]) { *stop = YES; *firstResponder = view; }

    else if (!*stop && [view.subviews count] > 0)
      for (UIView * subview in view.subviews) weakFindFirstResponder(subview, firstResponder, stop);


  };

  findFirstResponder(topView, &firstResponder, &stop);

  return firstResponder;

}

/// viewTreeDescription
/// @return NSString *
- (NSString *)viewTreeDescription {

  NSMutableString * outstring = [@"" mutableCopy];

  __block void (^dumpView)(UIView *, int) = nil;
  __block void(__weak ^ weakDumpView)(UIView *, int) = nil;

  dumpView = ^(UIView * view, int indent) {

    [outstring appendFormat:@"%@[%2d] %@(%p)\n",
     [NSString stringWithCharacter:'-' count:indent*2], indent, ClassString([view class]), view];

    for (UIView * subview in view.subviews) weakDumpView(subview, indent + 1);

  };

  weakDumpView = dumpView;
  dumpView(self, 0);

  return outstring;

}

/// Append '?' to property name in `properties` array if the value is a `BOOL` and you want "YES" or "NO"
/// @param properties
/// @return NSString *
- (NSString *)viewTreeDescriptionWithProperties:(NSArray *)properties {

  NSMutableString * outstring = [@"" mutableCopy];

  __block void (^dumpView)(UIView *, int)             = nil;
  __block void (__weak ^ weakDumpView)(UIView *, int) = nil;

  weakDumpView = dumpView = ^(UIView * view, int indent) {

    [outstring appendString:[NSString stringWithCharacter:'-' count:indent*2]];

    NSMutableDictionary * propertyValues = [@{} mutableCopy];

    for (int i = 0; i < properties.count; i++) {

      NSString * property = properties[i];
      BOOL       isBool   = ([property characterAtIndex:property.length - 1] == '?');

      if (isBool) property = [property substringToIndex:property.length - 1];

      if ([view respondsToSelector:NSSelectorFromString(property)]) {

        id val = [view valueForKey:property];

        if (ValueIsNil(val) || ([val respondsToSelector:@selector(count)] && [val count] == 0)) continue;

        propertyValues[properties[i]] = (val ? (isBool ? BOOLString([val boolValue]) : val) : NullObject);

      }

    }

    NSString * valueDump = (propertyValues.count > 0
                            ? [[propertyValues description] stringByReplacingRegEx:@"=[\t ]+" withString:@"= "]
                            : @"");

    [outstring appendFormat:@"[%2d] %@(%p)%@%@\n",
     indent, ClassString([view class]), view, (propertyValues.count > 0 ? @":" : @""), valueDump];

    for (UIView * subview in view.subviews) weakDumpView(subview, indent + 1);

  };

  dumpView(self, 0);

  return outstring;

}

/// setAlignedCenter:
/// @param center
- (void)setAlignedCenter:(CGPoint)center { self.center = center; self.frame = CGRectIntegral(self.frame); }

/// prettyConstraintsDescription
/// @return NSString *
//- (NSString *)prettyConstraintsDescription {
//
//  static NSString *(^itemNameForView)(UIView *) = ^(UIView * view) {
//
//    NSString * name = view.nametag;
//
//    if (!name && [view respondsToSelector:@selector(name)]) name = [view valueForKey:@"name"];
//
//    if (!name && [view respondsToSelector:@selector(text)]) {
//      name = [[view valueForKey:@"text"] stringByReplacingReturnsWithSymbol];
//      if ([name length] > 30) name = $(@"%@…", [name substringToIndex:30]);
//    }
//
//    NSString * fullName = nil;
//
//    if (name) fullName = $(@"<%@:'%@'>", ClassString([view class]), name);
//    else if (!name && view) fullName = $(@"<%@:%p>", ClassString([view class]), view);
//
//    return fullName;
//
//  };
//
//  NSArray * descriptions = [self.constraints mapped:^id (NSLayoutConstraint * constraint, NSUInteger idx) {
//
//    NSString     * firstItem     = itemNameForView(constraint.firstItem);
//    NSString     * secondItem    = itemNameForView(constraint.secondItem);
//    NSDictionary * substitutions = nil;
//
//    if (firstItem && secondItem)
//      substitutions = @{ MSExtendedVisualFormatItem1Name : firstItem,
//                         MSExtendedVisualFormatItem2Name : secondItem };
//
//    else if (firstItem)
//      substitutions = @{ MSExtendedVisualFormatItem1Name : firstItem };
//
//    return [constraint stringRepresentationWithSubstitutions:substitutions];
//
//  }];
//
//  return $(@"Constraints for view '%@':\n%@", itemNameForView(self), [@"\n" join:descriptions]);
//
//}

/// snapshot
/// @return UIImage *
- (UIImage *)snapshot {

  UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);

  [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:false];

  UIImage * image = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();

  return image;

}

/// blurredSnapshot
/// @return UIImage *
- (UIImage *)blurredSnapshot {

  //TODO: Look into using new UIVisualEffect object

  return [[self snapshot] applyBlurWithRadius:3.0
                                    tintColor:[UIColor colorWithWhite:1.0 alpha:0.5]
                        saturationDeltaFactor:1.0
                                    maskImage:nil];

/*
  // Create the image context
  UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);

  // There he is! The new API method
  [self drawViewHierarchyInRect:self.frame afterScreenUpdates:NO];

  // Get the snapshot
  UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();

  // Now apply the blur effect using Apple's UIImageEffect category
  UIImage * blurredSnapshotImage = [snapshotImage applyLightEffect];

  // Or apply any other effects available in "UIImage+ImageEffects.h"
  // UIImage *blurredSnapshotImage = [snapshotImage applyDarkEffect];
  // UIImage *blurredSnapshotImage = [snapshotImage applyExtraLightEffect];

  // Be nice and clean your mess up
  UIGraphicsEndImageContext();

  return blurredSnapshotImage;
*/

}

/// constrainWithFormat:nametag:
/// @param format
/// @param nametag
//- (NSArray *)constrainWithFormat:(NSString *)format nametag:(NSString *)nametag {
//  return [self constrainWithFormat:format views:@{} nametag:nametag];
//}
//
///// constrainWithFormat:identifier:
///// @param format
///// @param identifier
//- (NSArray *)constrainWithFormat:(NSString *)format identifier:(NSString *)identifier {
//  return [self constrainWithFormat:format views:@{} identifier:identifier];
//}
//
///// constrainWithFormat:
///// @param format
//- (NSArray *)constrainWithFormat:(NSString *)format { return [self constrainWithFormat:format views:@{}]; }
//
///// constrainWithFormat:views:
///// @param format
///// @param views
//- (NSArray *)constrainWithFormat:(NSString *)format views:(NSDictionary *)views {
//  return [self constrainWithFormat:format views:views nametag:nil];
//}
//
///// constraintWithFormat:views:nametag:
///// @param format
///// @param views
///// @param nametag
//- (NSArray *)constrainWithFormat:(NSString *)format views:(NSDictionary *)views nametag:(NSString *)nametag {
//  return [self constrainWithFormat:format views:views identifier:nametag];
//}
//
///// constraintWithFormat:views:identifier:
///// @param format
///// @param views
///// @param identifier
//- (NSArray *)constrainWithFormat:(NSString *)format views:(NSDictionary *)views identifier:(NSString *)identifier {
//  NSArray * constraints = nil;
//  if (StringIsNotEmpty(format)) {
//    NSMutableDictionary * dict = [views mutableCopy];
//    dict[@"self"] = self;
//    constraints = [NSLayoutConstraint constraintsByParsingString:format views:dict];
//    if (identifier) [constraints setValue:identifier forKeyPath:@"identifier"];
//    [self addConstraints:constraints];
//  }
//  return constraints;
//}
//

- (void)removeAllConstraints { [self removeConstraints: self.constraints]; }

@end
