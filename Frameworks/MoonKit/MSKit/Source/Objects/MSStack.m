//
//  MSStack.m
//  MSKit
//
//  Created by Jason Cardwell on 4/29/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
#import "MSStack.h"
#import "MSKitMacros.h"

@implementation MSStack {
    NSMutableArray * _array;
}

+ (MSStack *)stack { return [self new]; }

+ (MSStack *)stackWithArray:(NSArray *)array {
  if (!array) ThrowInvalidNilArgument(array);
  return [[self alloc] initWithContentsOfArray:array];
}

+ (MSStack *)stackWithObject:(id)obj {
  if (!obj) ThrowInvalidNilArgument(obj);
  return [[self alloc] initWithContentsOfArray:@[obj]];
}

- (id)init { if (self = [super init]) self->_array = [@[] mutableCopy]; return self; }

- (id)initWithContentsOfArray:(NSArray *)array
{
    if (self = [super init]) _array = [[NSMutableArray alloc] initWithArray:array];
    return self;
}

+ (BOOL)instancesRespondToSelector:(SEL)aSelector
{
    if ([[self superclass] instancesRespondToSelector:aSelector]) return YES;
    else if ([[NSArray class] instancesRespondToSelector:aSelector]) return YES;
    else return NO;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([super respondsToSelector:aSelector]) return YES;
    else if ([_array respondsToSelector:aSelector]) return YES;
    else return NO;
}

- (id)forwardingTargetForSelector:(SEL)aSelector { return _array; }

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation invokeWithTarget:_array];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])buffer
                                    count:(NSUInteger)len
{
    return [_array countByEnumeratingWithState:state objects:buffer count:len];
}

- (void)push:(id)obj count:(NSUInteger)count { for (NSUInteger i = 0; i < count; i++) [self push:obj]; }

- (void)push:(id)obj { if (obj) [_array addObject:obj]; }

- (void)pushObjectsFromArray:(NSArray *)array { for (id obj in array) [self push:obj]; }

- (id)pop { id obj = [_array lastObject]; if (obj) [_array removeLastObject]; return obj; }

- (id)peek { return [_array lastObject]; }

- (void)empty { [_array removeAllObjects]; }

- (BOOL)isEmpty { return !([_array count]); }

- (NSUInteger)count { return [_array count]; }

- (void)reverse
{
    for (NSUInteger l = 0, r = [_array count] - 1; l < r; l++, r--)
        [_array exchangeObjectAtIndex:l withObjectAtIndex:r];
}

- (NSString *)description { return [_array description]; }

@end
