//
//  NSMutableArray+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 5/24/11.
//  Copyright 2011 Moondeer Studios. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "MSKitProtocols.h"
#import "MSKitDefines.h"
//typedef void(^NSArrayEnumerationBlock)(id obj, NSUInteger idx, BOOL *stop);
//typedef BOOL(^NSArrayPredicateBlock)  (id obj, NSUInteger idx, BOOL *stop);
//typedef id  (^NSArrayMappingBlock)    (id obj, NSUInteger idx);

@interface NSArray (MSKitAdditions) <MSKeySearchable, MSObjectContaining>

@property (nonatomic, readonly) BOOL isEmpty;

+ (nonnull NSArray *)arrayFromRange:(NSRange)range;
+ (nonnull NSArray *)arrayWithObject:(id __nonnull)obj count:(NSUInteger)count;

//@property (nonatomic, weak, readonly, nonnull) id JSONObject;
//@property (nonatomic, weak, readonly, nonnull) NSString * JSONString;

- (nonnull NSSet *)set;
- (NSUInteger)lastIndex;
- (nonnull NSOrderedSet *)orderedSet;


- (nonnull NSArray  *)arrayByAddingObjects:(id __nonnull)objects;
- (nonnull NSArray  *)arrayByAddingKeysFromDictionary:(NSDictionary * __nonnull)dictionary;
- (nonnull NSArray  *)arrayByAddingValuesFromDictionary:(NSDictionary * __nonnull)dictionary;
- (nonnull NSArray  *)arrayByAddingObjectsFromSet:(NSSet * __nonnull)set;
- (nonnull NSArray  *)compacted;
- (nonnull NSArray  *)arrayByAddingObjectsFromOrderedSet:(NSOrderedSet * __nonnull)orderedSet;
- (nonnull NSArray  *)filteredArrayUsingPredicateWithFormat:(NSString * __nonnull)format,...;
- (nonnull NSArray  *)filteredArrayUsingPredicateWithBlock:(BOOL (^ __nonnull)(id __nonnull evaluatedObject,
                                                                      NSDictionary * __nullable bindings))block;
- (nonnull NSArray  *)filteredUsingPredicate:(NSPredicate * __nonnull)predicate;
- (nonnull NSArray  *)filtered:(BOOL (^ __nonnull)(id __nonnull evaluatedObject))block;
- (nullable id)objectPassingTest:(BOOL (^ __nonnull)(id __nonnull obj, NSUInteger idx))predicate;
- (nullable id)findFirst:(BOOL (^ __nonnull)(id __nonnull evaluatedObject))predicate;
- (nullable id)findFirstUsingPredicate:(NSPredicate * __nonnull)predicate;
- (nonnull NSArray  *)objectsPassingTest:(BOOL (^ __nonnull)(id __nonnull obj, NSUInteger idx, BOOL * __nonnull stop))predicate;
- (nonnull NSArray  *)flattened;
- (nonnull NSArray  *)uniqued;
- (nonnull NSArray  *)mapped:(id __nullable (^ __nonnull)(id __nonnull obj, NSUInteger idx))block;

@end


@interface NSMutableArray (MSKitAdditions)
+ (nonnull instancetype)arrayWithObject:(id __nonnull)obj count:(NSUInteger)count;
+ (nonnull id)arrayWithNullCapacity:(NSUInteger)capacity;
- (void)filter:(BOOL (^ __nonnull)(id __nonnull evaluatedObject))block;
- (void)map:(id __nonnull (^ __nonnull)(id __nonnull obj, NSUInteger idx))block;
- (void)replaceAllObjectsWithNull;
- (void)compact;
- (void)flatten;
- (void)unique;
@end

#define NSArrayOfVariableNames(...) \
_NSArrayOfVariableNames(@"" # __VA_ARGS__, __VA_ARGS__, nil)

MSEXTERN NSArray * __nonnull _NSArrayOfVariableNames(NSString * __nonnull commaSeparatedNamesString, ...);
