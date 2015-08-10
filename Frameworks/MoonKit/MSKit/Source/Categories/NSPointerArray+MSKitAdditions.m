//
//  NSPointerArray+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 10/21/13.
//  Copyright (c) 2013 Jason Cardwell. All rights reserved.
//

#import "NSPointerArray+MSKitAdditions.h"
#import "MSKitMacros.h"

@implementation NSPointerArray (MSKitAdditions)

- (NSArray *)allValues { return [self allObjects]; }

- (void)setObjectsFromArray:(NSArray *)array
{
    [self setCount:0];
    for (id obj in array) [self addPointer:(__bridge void *)(NilSafe(obj))];
}

- (void)removePointerAtIndex:(NSUInteger)index compact:(BOOL)compact
{
    [self removePointerAtIndex:index];
    if (compact) [self compact];
}

- (void)removePointersAtIndexes:(NSIndexSet *)indexes
{
    [self removePointersAtIndexes:indexes compact:NO];
}

- (void)removePointersAtIndexes:(NSIndexSet *)indexes compact:(BOOL)compact
{
    if ([indexes indexGreaterThanOrEqualToIndex:[self count]] == NSNotFound)
    {
        __block int removed = 0;
        [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [self removePointerAtIndex:idx - removed++];
        }];
        if (compact) [self compact];
    }
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx { return [self pointerAtIndex:idx]; }

- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes
{
    return [[self allObjects] objectsAtIndexes:indexes];
}

- (BOOL)containsObject:(id)anObject { return [[self allObjects] containsObject:anObject]; }

- (NSUInteger)indexOfObject:(id)anObject { return [[self allObjects] indexOfObject:anObject]; }

- (NSUInteger)indexOfObject:(id)anObject inRange:(NSRange)range
{
    return [[self allObjects] indexOfObject:anObject inRange:range];
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject
{
    return [[self allObjects] indexOfObjectIdenticalTo:anObject];
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)anObject inRange:(NSRange)range
{
    return [[self allObjects] indexOfObjectIdenticalTo:anObject inRange:range];
}

- (NSEnumerator *)objectEnumerator { return [[self allObjects] objectEnumerator]; }

- (NSEnumerator *)reverseObjectEnumerator { return [[self allObjects] reverseObjectEnumerator]; }

- (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator
                              context:(void *)context
{
    return [[self allObjects] sortedArrayUsingFunction:comparator context:context];
}

- (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator
                              context:(void *)context
                                 hint:(NSData *)hint
{
    return [[self allObjects] sortedArrayUsingFunction:comparator context:context hint:hint];
}

- (NSArray *)sortedArrayUsingSelector:(SEL)comparator
{
    return [[self allObjects] sortedArrayUsingSelector:comparator];
}

- (NSArray *)subarrayWithRange:(NSRange)range { return [[self allObjects] subarrayWithRange:range]; }


- (NSUInteger)indexOfObjectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate
{
    return [[self allObjects] indexOfObjectPassingTest:predicate];
}

- (NSUInteger)indexOfObjectWithOptions:(NSEnumerationOptions)opts
                           passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate
{
    return [[self allObjects] indexOfObjectWithOptions:opts passingTest:predicate];
}

- (NSUInteger)indexOfObjectAtIndexes:(NSIndexSet *)s
                             options:(NSEnumerationOptions)opts
                         passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate
{
    return [[self allObjects] indexOfObjectAtIndexes:s options:opts passingTest:predicate];
}

- (NSIndexSet *)indexesOfObjectsPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate
{
    return [[self allObjects] indexesOfObjectsPassingTest:predicate];
}

- (NSIndexSet *)indexesOfObjectsWithOptions:(NSEnumerationOptions)opts
                                passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate
{
    return [[self allObjects] indexesOfObjectsWithOptions:opts passingTest:predicate];
}

- (NSIndexSet *)indexesOfObjectsAtIndexes:(NSIndexSet *)s
                                  options:(NSEnumerationOptions)opts
                              passingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate
{
    return [[self allObjects] indexesOfObjectsAtIndexes:s options:opts passingTest:predicate];
}

- (NSArray *)sortedArrayUsingComparator:(NSComparator)cmptr
{
    return [[self allObjects] sortedArrayUsingComparator:cmptr];
}

- (NSArray *)sortedArrayWithOptions:(NSSortOptions)opts usingComparator:(NSComparator)cmptr
{
    return [[self allObjects] sortedArrayWithOptions:opts usingComparator:cmptr];
}


- (NSUInteger)indexOfObject:(id)obj
              inSortedRange:(NSRange)r
                    options:(NSBinarySearchingOptions)opts
            usingComparator:(NSComparator)cmp
{
    return [[self allObjects] indexOfObject:obj inSortedRange:r options:opts usingComparator:cmp];
}

- (void)exchangePointerAtIndex:(NSUInteger)index withPointerAtIndex:(NSUInteger)otherIndex
{
    if (index >= [self count]) ThrowInvalidIndexArgument(index);
    else if (otherIndex >= [self count]) ThrowInvalidIndexArgument(otherIndex);
    else
    {
        id pointerForIndex = self[index];
        [self replacePointerAtIndex:index withPointer:(__bridge void *)(self[otherIndex])];
        [self replacePointerAtIndex:otherIndex withPointer:(__bridge void *)(pointerForIndex)];
    }
}

@end
