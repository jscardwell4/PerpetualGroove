//
//  NSPointerArray+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 10/21/13.
//  Copyright (c) 2013 Jason Cardwell. All rights reserved.
//

@import Foundation;
#import "MSKitProtocols.h"

@interface NSPointerArray (MSKitAdditions) <MSKeySearchable>

- (void)setObjectsFromArray:(NSArray *)array;
- (void)removePointerAtIndex:(NSUInteger)index compact:(BOOL)compact;
- (void)removePointersAtIndexes:(NSIndexSet *)indexes;
- (void)removePointersAtIndexes:(NSIndexSet *)indexes compact:(BOOL)compact;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;

- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes;

- (BOOL)containsObject:(id)anObject;

- (NSUInteger)indexOfObject:(id)anObject;
- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range;
- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject;
- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject inRange:(NSRange)range;

- (NSEnumerator *)objectEnumerator;
- (NSEnumerator *)reverseObjectEnumerator;

- (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator
                              context:(void *)context;
- (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator
                              context:(void *)context
                                 hint:(NSData *)hint;
- (NSArray *)sortedArrayUsingSelector:(SEL)comparator;
- (NSArray *)subarrayWithRange:(NSRange)range;

- (NSUInteger)indexOfObjectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
- (NSUInteger)indexOfObjectWithOptions:(NSEnumerationOptions)opts
                           passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
- (NSUInteger)indexOfObjectAtIndexes:(NSIndexSet *)s
                             options:(NSEnumerationOptions)opts
                         passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;

- (NSIndexSet *)indexesOfObjectsPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
- (NSIndexSet *)indexesOfObjectsWithOptions:(NSEnumerationOptions)opts
                                passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
- (NSIndexSet *)indexesOfObjectsAtIndexes:(NSIndexSet *)s
                                  options:(NSEnumerationOptions)opts
                              passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;

- (NSArray *)sortedArrayUsingComparator:(NSComparator)cmptr;
- (NSArray *)sortedArrayWithOptions:(NSSortOptions)opts usingComparator:(NSComparator)cmptr;

- (NSUInteger)indexOfObject:(id)obj
              inSortedRange:(NSRange)r
                    options:(NSBinarySearchingOptions)opts
            usingComparator:(NSComparator)cmp;

- (void)exchangePointerAtIndex:(NSUInteger)index withPointerAtIndex:(NSUInteger)otherIndex;

@end
