//
//  NSSet+MSKitAdditions.h
//  Remote
//
//  Created by Jason Cardwell on 4/24/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

@import Foundation;
#import "MSKitProtocols.h"

#pragma clang assume_nonnull begin
@interface NSSet (MSKitAdditions) <MSKeySearchable>

@property (nonatomic, readonly) BOOL isEmpty;
//@property (nonatomic, weak, readonly, nonnull) id JSONObject;
//@property (nonatomic, weak, readonly, nonnull) NSString * JSONString;

+ (NSSet *)setWithArrays:(NSArray *)arrays;

- (NSSet *)setByRemovingObjectsFromSet:(NSSet *)other;

- (NSSet *)setByRemovingObjectsFromArray:(NSArray *)other;

- (NSString *)componentsJoinedByString:(NSString *)string;

- (NSSet *)setByRemovingObject:(id)object;

- (NSSet *)setByIntersectingSet:(NSSet *)other;

- (NSSet *)setByIntersectingArray:(NSArray *)other;

- (id)objectPassingTest:(BOOL (^)(id obj))predicate;

- (NSSet *)filteredSetUsingPredicateWithBlock:(BOOL (^)(id obj, NSDictionary * bindings))block;

- (NSSet *)filteredSetUsingPredicateWithFormat:(NSString *)format,...;

- (NSSet *)setByMappingToBlock:(id (^)(id obj))block;

- (BOOL)containsObjectWithValue:(id)value forKey:(NSString *)key;

- (nullable id)objectWithValue:(id)value forKey:(NSString *)key;

- (NSSet *)objectsWithValue:(id)value forKey:(NSString *)key;

@end

@interface NSMutableSet (MSKitAdditions)

- (void)addOrRemoveObject:(id)object;

@end

#pragma clang assume_nonnull end