//
//  UIView+MSKitAdditions.h
//  Remote
//
//  Created by Jason Cardwell on 4/12/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;

@interface UIView (MSKitAdditions)

+ (UIView *)currentResponder;
+ (UIView *)firstResponderInView:(UIView *)topView;
+ (CGRect)unionFrameForViews:(NSArray *)views;

- (NSString *)viewTreeDescription;
- (NSString *)viewTreeDescriptionWithProperties:(NSArray *)properties;

- (void)repositionFrameAtOrigin:(CGPoint)origin;
- (void)resizeFrameToSize:(CGSize)size anchored:(BOOL)anchored;
- (void)resizeBoundsToSize:(CGSize)size;
- (void)fitFrameToSize:(CGSize)size anchored:(BOOL)anchored;
- (void)fitBoundsToSize:(CGSize)size;
- (void)setAlignedCenter:(CGPoint)center;
- (NSArray *)subviewsOfKind:(Class)kind;
- (NSArray *)subviewsOfType:(Class)type;

+ (instancetype)newForAutolayout;

- (instancetype)initForAutoLayout;
- (instancetype)initWithFrame:(CGRect)frame autolayout:(BOOL)autolayout;
- (instancetype)initWithFrame:(CGRect)frame nametag:(NSString *)nametag autolayout:(BOOL)autolayout;
- (instancetype)initWithNametag:(NSString *)nametag autolayout:(BOOL)autolayout;
- (instancetype)initForAutoLayoutWithFrame:(CGRect)frame;
- (instancetype)initWithFrame:(CGRect)frame nametag:(NSString *)nametag;

@property (nonatomic, strong) NSString * nametag;
@property (nonatomic, assign, readonly) CGFloat minX;
@property (nonatomic, assign, readonly) CGFloat minY;
@property (nonatomic, assign, readonly) CGFloat maxX;
@property (nonatomic, assign, readonly) CGFloat maxY;
@property (nonatomic, assign, readonly) CGFloat h;
@property (nonatomic, assign, readonly) CGFloat w;

- (UIView *)viewWithNametag:(NSString *)nametag;
- (UIView *)viewWithNametagPrefix:(NSString *)prefix;
- (UIView *)viewWithNametagSuffix:(NSString *)suffixx;
- (UIView *)viewMatching:(NSPredicate *)predicate;

- (NSArray *)viewsWithNametag:(NSString *)nametag;
- (NSArray *)viewsWithNametagPrefix:(NSString *)prefix;
- (NSArray *)viewsWithNametagSuffix:(NSString *)suffixx;
- (NSArray *)viewsMatching:(NSPredicate *)predicate;

- (UIView *)subviewWithNametag:(NSString *)nametag;
- (UIView *)subviewWithNametagPrefix:(NSString *)prefix;
- (UIView *)subviewWithNametagSuffix:(NSString *)suffixx;
- (UIView *)subviewMatching:(NSPredicate *)predicate;

- (NSArray *)subviewsWithNametag:(NSString *)nametag;
- (NSArray *)subviewsWithNametagPrefix:(NSString *)prefix;
- (NSArray *)subviewsWithNametagSuffix:(NSString *)suffixx;
//- (NSArray *)subviewsMatching:(NSPredicate *)predicate;

- (UIGestureRecognizer *)gestureWithNametag:(NSString *)nametag;
- (UIGestureRecognizer *)gestureWithNametagPrefix:(NSString *)prefix;
- (UIGestureRecognizer *)gestureWithNametagSuffix:(NSString *)suffixx;
- (UIGestureRecognizer *)gestureMatching:(NSPredicate *)predicate;

- (NSArray *)gesturesWithNametag:(NSString *)nametag;
- (NSArray *)gesturesWithNametagPrefix:(NSString *)prefix;
- (NSArray *)gesturesWithNametagSuffix:(NSString *)suffixx;
- (NSArray *)gesturesMatching:(NSPredicate *)predicate;

- (NSLayoutConstraint *)constraintWithTag:(NSUInteger)tag;
- (NSArray *)constraintsWithTag:(NSUInteger)tag;

- (NSLayoutConstraint *)constraintWithNametag:(NSString *)nametag;
- (NSLayoutConstraint *)constraintWithNametagPrefix:(NSString *)prefix;
- (NSLayoutConstraint *)constraintWithNametagSuffix:(NSString *)suffix;
- (NSLayoutConstraint *)constraintWithIdentifier:(NSString *)identifier;
- (NSLayoutConstraint *)constraintWithIdentifierPrefix:(NSString *)prefix;
- (NSLayoutConstraint *)constraintWithIdentifierSuffix:(NSString *)suffix;
- (NSLayoutConstraint *)constraintMatching:(NSPredicate *)predicate;
// - (NSLayoutConstraint *)constraintWithAttributes:(NSDictionary *)attributes;

- (NSArray *)constraintsWithNametag:(NSString *)nametag;
- (NSArray *)constraintsWithNametagPrefix:(NSString *)prefix;
- (NSArray *)constraintsWithNametagSuffix:(NSString *)suffix;
- (NSArray *)constraintsWithIdentifier:(NSString *)identifier;
- (NSArray *)constraintsWithIdentifierPrefix:(NSString *)prefix;
- (NSArray *)constraintsWithIdentifierSuffix:(NSString *)suffix;
- (NSArray *)constraintsMatching:(NSPredicate *)predicate;

- (void)replaceConstraintWithNametag:(NSString *)nametag withConstraint:(NSLayoutConstraint *)constraint;
- (void)replaceConstraintsWithNametag:(NSString *)nametag withConstraints:(NSArray *)constraints;
- (void)replaceConstraintsWithNametagPrefix:(NSString *)prefix withConstraints:(NSArray *)constraints;
- (void)replaceConstraintWithIdentifier:(NSString *)identifier withConstraint:(NSLayoutConstraint *)constraint;
- (void)replaceConstraintsWithIdentifier:(NSString *)identifier withConstraints:(NSArray *)constraints;
- (void)replaceConstraintsWithIdentifierPrefix:(NSString *)prefix withConstraints:(NSArray *)constraints;
- (void)replaceConstraintsWithIdentifierSuffix:(NSString *)suffix withConstraints:(NSArray *)constraints;

- (void)removeConstraintWithIdentifier:(NSString *)identifier;
- (void)removeConstraintsWithIdentifier:(NSString *)identifier;
- (void)removeConstraintsWithIdentifierPrefix:(NSString *)prefix;
- (void)removeConstraintsWithIdentifierSuffix:(NSString *)suffix;

- (NSArray *)constraintsOfType:(Class)type;
- (void)replaceConstraintsOfType:(Class)type withConstraints:(NSArray *)constraints;
- (void)removeAllConstraints;

- (UIImage *)snapshot;
- (UIImage *)blurredSnapshot;

//- (NSArray *)constrainWithFormat:(NSString *)format identifier:(NSString *)identifier;
//- (NSArray *)constrainWithFormat:(NSString *)format nametag:(NSString *)nametag;
//- (NSArray *)constrainWithFormat:(NSString *)format; // Use 'self' as identifier to avoid issues with dictionary for views
//- (NSArray *)constrainWithFormat:(NSString *)format views:(NSDictionary *)views; // Adds self to `views`
//- (NSArray *)constrainWithFormat:(NSString *)format views:(NSDictionary *)views nametag:(NSString *)nametag;
//- (NSArray *)constrainWithFormat:(NSString *)format views:(NSDictionary *)views identifier:(NSString *)identifier;

// - (NSArray *)constrainToSize:(CGSize)size;
// - (NSArray *)constrainToSize:(CGSize)size identifier:(NSString *)identifier;
// - (NSArray *)horizontallyStretchSubview:(UIView *)subview;
// - (NSArray *)verticallyStretchSubview:(UIView *)subview;
// - (NSArray *)stretchSubview:(UIView *)subview;
// - (NSArray *)horizontallyCenterSubview:(UIView *)subview;
// - (NSArray *)horizontallyCenterSubview:(UIView *)subview offset:(CGFloat)offset;
// - (NSArray *)verticallyCenterSubview:(UIView *)subview;
// - (NSArray *)verticallyCenterSubview:(UIView *)subview offset:(CGFloat)offset;
// - (NSArray *)centerSubview:(UIView *)subview;
// - (NSArray *)centerSubview:(UIView *)subview offset:(CGFloat)offset;
// - (NSArray *)leftAlignSubview:(UIView *)subview;
// - (NSArray *)leftAlignSubview:(UIView *)subview offset:(CGFloat)offset;
// - (NSArray *)rightAlignSubview:(UIView *)subview;
// - (NSArray *)rightAlignSubview:(UIView *)subview offset:(CGFloat)offset;
// - (NSArray *)topAlignSubview:(UIView *)subview;
// - (NSArray *)topAlignSubview:(UIView *)subview offset:(CGFloat)offset;
// - (NSArray *)bottomAlignSubview:(UIView *)subview;
// - (NSArray *)bottomAlignSubview:(UIView *)subview offset:(CGFloat)offset;
// - (NSLayoutConstraint *)constrainWidth:(CGFloat)width;
// - (NSLayoutConstraint *)constrainHeight:(CGFloat)height;
// - (NSLayoutConstraint *)constrainAspect:(CGFloat)aspect;
// - (NSArray *)alignSubview:(UIView *)subview1 besideSubview:(UIView *)subview2 offset:(CGFloat)offset;
// - (NSArray *)alignSubview:(UIView *)subview1 aboveSubview:(UIView *)subview2 offset:(CGFloat)offset;
// - (NSArray *)stretchSubview:(UIView *)subview1 toSubview:(UIView *)subview2;

@end

@interface UIView (Debugger)
- (NSString *)recursiveDescription;
//- (NSString *)prettyConstraintsDescription;
@end
