//
//  NSLayoutConstraint+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 9/30/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;
#import "MSKitDefines.h"

MSEXTERN_STRING MSExtendedVisualFormatIdentifierName;
MSEXTERN_STRING MSExtendedVisualFormatItem1Name;
MSEXTERN_STRING MSExtendedVisualFormatAttribute1Name;
MSEXTERN_STRING MSExtendedVisualFormatRelationName;
MSEXTERN_STRING MSExtendedVisualFormatItem2Name;
MSEXTERN_STRING MSExtendedVisualFormatAttribute2Name;
MSEXTERN_STRING MSExtendedVisualFormatMultiplierName;
MSEXTERN_STRING MSExtendedVisualFormatConstantName;
MSEXTERN_STRING MSExtendedVisualFormatPriorityName;
MSEXTERN_STRING MSExtendedVisualFormatConstantOperatorName;

@interface NSLayoutConstraint (MSKitAdditions) <NSCopying>

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Getting an array of NSLayoutConstraint objects
////////////////////////////////////////////////////////////////////////////////

+ (NSArray *)constraintsByParsingString:(NSString *)string
								options:(NSLayoutFormatOptions)options
								metrics:(NSDictionary *)metrics
								  views:(NSDictionary *)views;

+ (NSArray *)constraintsByParsingString:(NSString *)string
                                metrics:(NSDictionary *)metrics
                                  views:(NSDictionary *)views;

+ (NSArray *)constraintsByParsingString:(NSString *)string
                                  views:(NSDictionary *)views;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Converting to and from an NSDictionary
////////////////////////////////////////////////////////////////////////////////

+ (NSLayoutAttribute)attributeForPseudoName:(NSString *)pseudoName;

+ (NSLayoutRelation)relationForPseudoName:(NSString *)pseudoName;

+ (NSString *)pseudoNameForAttribute:(NSLayoutAttribute)attribute;

+ (NSString *)pseudoNameForRelation:(NSLayoutRelation)relation;

+ (NSLayoutConstraint *)constraintFromDictionary:(NSDictionary *)dictionary;

+ (NSDictionary *)dictionaryFromConstraint:(NSLayoutConstraint *)constraint;

+ (NSArray *)constraintDictionariesByParsingString:(NSString *)string;

+ (NSDictionary *)dictionaryFromExtendedVisualFormat:(NSString *)format;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Retrieving attribute values
////////////////////////////////////////////////////////////////////////////////

+ (id)valueForAttribute:(NSLayoutAttribute)attribute item:(UIView *)item;

+ (id)valueForAttribute:(NSLayoutAttribute)attribute alignmentRect:(CGRect)rect;

- (id)firstAttributeValue;

- (id)secondAttributeValue;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Copy support
////////////////////////////////////////////////////////////////////////////////

- (NSLayoutConstraint *)copyWithMultiplier:(CGFloat)multiplier;

//- (NSLayoutConstraint *)copyWithZone:(NSZone *)zone;
//
//- (NSLayoutConstraint *)copy;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - String representation
////////////////////////////////////////////////////////////////////////////////


- (NSString *)stringRepresentationWithSubstitutions:(NSDictionary *)substitutions;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Associated Objects
////////////////////////////////////////////////////////////////////////////////

@property (nonatomic, copy) NSString * nametag;
@property (nonatomic, assign) NSInteger tag;

- (NSString *)prettyDescription;

@end

// Prepare Constraint Compliance
#define PrepConstraints(View) \
	[View setTranslatesAutoresizingMaskIntoConstraints:NO]

// Add a  visual format constraint
#define Constrain(Parent, Format, ...)                             \
    [Parent addConstraints:                                        \
     [NSLayoutConstraint constraintsByParsingString:(Format)       \
                                              views:NSDictionaryOfVariableBindings(__VA_ARGS__)]]
#define ConstrainViews(Parent, Format, Bindings)                    \
    [Parent addConstraints:                                        \
     [NSLayoutConstraint constraintsByParsingString:(Format)       \
                                              views:Bindings]]
// Stretch across axis
#define StretchViewH(Parent, View) \
    Constrain(Parent, View, @"H:|["#View "(>=0)]|")
#define StretchViewV(Parent, View) \
    Constrain(Parent, View, @"V:|["#View "(>=0)]|")
#define StretchView(Parent, View) \
    {StretchViewH(Parent, View); StretchViewV(Parent, View); }

// Center along axis
#define CenterViewH(Parent, View, Constant)                          \
    [Parent addConstraint:                                           \
     [NSLayoutConstraint constraintWithItem:View                     \
                                  attribute:NSLayoutAttributeCenterX \
                                  relatedBy:NSLayoutRelationEqual    \
                                     toItem:Parent                   \
                                  attribute:NSLayoutAttributeCenterX \
                                 multiplier:1.0f                     \
                                   constant:Constant]]
#define CenterViewV(Parent, View, Constant)                          \
    [Parent addConstraint:                                           \
     [NSLayoutConstraint constraintWithItem:View                     \
                                  attribute:NSLayoutAttributeCenterY \
                                  relatedBy:NSLayoutRelationEqual    \
                                     toItem:Parent                   \
                                  attribute:NSLayoutAttributeCenterY \
                                 multiplier:1.0f                     \
                                   constant:Constant]]
#define CenterView(Parent, View) \
    {CenterViewH(Parent, View, 0.0f); CenterViewV(Parent, View, 0.0f); }

// Align to parent
#define AlignViewLeft(Parent, View, Constant)                     \
    [Parent addConstraint:                                        \
     [NSLayoutConstraint constraintWithItem:View                  \
                                  attribute:NSLayoutAttributeLeft \
                                  relatedBy:NSLayoutRelationEqual \
                                     toItem:Parent                \
                                  attribute:NSLayoutAttributeLeft \
                                 multiplier:1.0f                  \
                                   constant:Constant]]
#define AlignViewRight(Parent, View, Constant)                     \
    [Parent addConstraint:                                         \
     [NSLayoutConstraint constraintWithItem:View                   \
                                  attribute:NSLayoutAttributeRight \
                                  relatedBy:NSLayoutRelationEqual  \
                                     toItem:Parent                 \
                                  attribute:NSLayoutAttributeRight \
                                 multiplier:1.0f                   \
                                   constant:Constant]]
#define AlignViewTop(Parent, View, Constant)                      \
    [Parent addConstraint:                                        \
     [NSLayoutConstraint constraintWithItem:View                  \
                                  attribute:NSLayoutAttributeTop  \
                                  relatedBy:NSLayoutRelationEqual \
                                     toItem:Parent                \
                                  attribute:NSLayoutAttributeTop  \
                                 multiplier:1.0f                  \
                                   constant:Constant]]
#define AlignViewBottom(Parent, View, Constant)                     \
    [Parent addConstraint:                                          \
     [NSLayoutConstraint constraintWithItem:View                    \
                                  attribute:NSLayoutAttributeBottom \
                                  relatedBy:NSLayoutRelationEqual   \
                                     toItem:Parent                  \
                                  attribute:NSLayoutAttributeBottom \
                                 multiplier:1.0f                    \
                                   constant:Constant]]

// Set Size
#define ConstrainWidth(View, Width)                                         \
    [View addConstraint:                                                    \
     [NSLayoutConstraint constraintWithItem:View                            \
                                  attribute:NSLayoutAttributeWidth          \
                                  relatedBy:NSLayoutRelationEqual           \
                                     toItem:nil                             \
                                  attribute:NSLayoutAttributeNotAnAttribute \
                                 multiplier:1.0f                            \
                                   constant:Width]]
#define ConstrainHeight(View, Height)                                       \
    [View addConstraint:                                                    \
     [NSLayoutConstraint constraintWithItem:View                            \
                                  attribute:NSLayoutAttributeHeight         \
                                  relatedBy:NSLayoutRelationEqual           \
                                     toItem:nil                             \
                                  attribute:NSLayoutAttributeNotAnAttribute \
                                 multiplier:1.0f                            \
                                   constant:Height]]
#define ConstrainSize(View, Height, Width) \
    {ConstrainWidth(View, Width); ConstrainHeight(View, Height);}

// Set Aspect
#define ConstrainAspect(View, Aspect)                               \
    [View addConstraint:                                            \
     [NSLayoutConstraint constraintWithItem:View                    \
                                  attribute:NSLayoutAttributeWidth  \
                                  relatedBy:NSLayoutRelationEqual   \
                                     toItem:View                    \
                                  attribute:NSLayoutAttributeHeight \
                                 multiplier:(Aspect)                \
                                   constant:0.0f]]// Order items
#define ConstrainOrderH(Parent, View1, View2)                                           \
    [Parent addConstraints:                                                             \
     [NSLayoutConstraint constraintsWithVisualFormat:(@"H:["#View1"]->=0-["#View2"]")   \
                                             options:0                                  \
                                             metrics:nil                                \
                                               views:NSDictionaryOfVariableBindings(View1, View2)]]
#define ConstrainOrderV(Parent, View1, View2)                                            \
    [Parent addConstraints:                                                             \
     [NSLayoutConstraint constraintsWithVisualFormat:(@"V:["#View1"]->=0-["#View2"]")   \
                                             options:0                                  \
                                             metrics:nil                                \
                                               views:NSDictionaryOfVariableBindings(View1, View2)]]

#define PseudoForAttribute(a) [NSLayoutConstraint pseudoNameForAttribute:a]
#define AttributeForPseudo(p) [NSLayoutConstraint attributeForPseudoName:p]
#define PseudoForRelation(r)  [NSLayoutConstraint pseudoNameForRelation:r]
#define RelationForPseudo(p)  [NSLayoutConstraint relationForPseudoName:p]
