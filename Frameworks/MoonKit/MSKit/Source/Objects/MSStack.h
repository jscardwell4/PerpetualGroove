//
//  MSStack.h
//  MSKit
//
//  Created by Jason Cardwell on 4/29/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;

@interface MSStack : NSObject <NSFastEnumeration>

+ (MSStack *)stack;
+ (MSStack *)stackWithArray:(NSArray *)array;
+ (MSStack *)stackWithObject:(id)obj;

- (void)push:(id)obj count:(NSUInteger)count;
- (void)push:(id)obj;

- (void)pushObjectsFromArray:(NSArray *)array;

- (id)pop;

- (void)empty;

- (id)peek;

- (void)reverse;

@property (nonatomic, assign, readonly) BOOL       isEmpty;
@property (nonatomic, assign, readonly) NSUInteger count;

@end

@interface MSStack (NSArray)

- (NSArray *)arrayByAddingObject:(id)anObject;

- (NSArray *)arrayByAddingObjectsFromArray:(NSArray *)otherArray;

- (NSString *)componentsJoinedByString:(NSString *)separator;

- (BOOL)containsObject:(id)anObject;

- (NSString *)description;

- (NSString *)descriptionWithLocale:(id)locale;

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level;

- (id)firstObjectCommonWithArray:(NSArray *)otherArray;

- (void)getObjects:(id __unsafe_unretained [])objects range:(NSRange)range;

- (NSUInteger)indexOfObject:(id)anObject;

- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range;

- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject;

- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject inRange:(NSRange)range;

- (BOOL)isEqualToArray:(NSArray *)otherArray;

- (id)lastObject;

- (NSEnumerator *)objectEnumerator;

- (NSEnumerator *)reverseObjectEnumerator;

- (NSData *)sortedArrayHint;

- (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator context:(void *)context;

- (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator
                              context:(void *)context hint:(NSData *)hint;

- (NSArray *)sortedArrayUsingSelector:(SEL)comparator;

- (NSArray *)subarrayWithRange:(NSRange)range;

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile;

- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)atomically;

- (void)makeObjectsPerformSelector:(SEL)aSelector;

- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)argument;

- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;

- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)opts
                         usingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;

- (void)enumerateObjectsAtIndexes:(NSIndexSet *)s
                          options:(NSEnumerationOptions)opts
                       usingBlock:(void (^)(id obj, NSUInteger idx, BOOL *stop))block;

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

- (NSUInteger)indexOfObject:(id)obj inSortedRange:(NSRange)r
                    options:(NSBinarySearchingOptions)opts
            usingComparator:(NSComparator)cmp;

@end
