//
//  MSKitMiscellaneousFunctions.m
//  Remote
//
//  Created by Jason Cardwell on 4/22/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "MSKitMiscellaneousFunctions.h"
#import <objc/runtime.h>
#import "NSObject+MSKitAdditions.h"
#import "MSKitMacros.h"

NSString * classNametagWithSuffix(NSString *suffix, id obj) {
  return $(@"%@%@", [obj className], (suffix ?: @""));
}

NSString * MSNonce() {
    return [[NSUUID UUID] UUIDString];
}

void MSRunSyncOnMain(dispatch_block_t block) {
    if ([[NSThread currentThread] isMainThread])
        block();
    else
        dispatch_sync(dispatch_get_main_queue(), block);
}

void MSRunAsyncOnMain(dispatch_block_t block) {
    if ([[NSThread currentThread] isMainThread])
        block();
    else
        dispatch_async(dispatch_get_main_queue(), block);
}

void MSDelayedRunOnMain(int64_t seconds, dispatch_block_t block)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC),
                   dispatch_get_main_queue(),
                   block);
}

void MSSwapInstanceMethodsForClass(Class c, SEL m1, SEL m2)
{
    MSSwapInstanceMethods(c, m1, c, m2);
}

void MSSwapInstanceMethods(Class c1, SEL m1, Class c2, SEL m2)
{
    if (c1 && m1 && c2 && m2)
        method_exchangeImplementations(class_getInstanceMethod(c1, m1),
                                       class_getInstanceMethod(c2, m2));
}

BOOL MSSelectorInProtocol(SEL selector, Protocol * protocol, BOOL isRequired, BOOL isInstance)
{
    struct objc_method_description   description = protocol_getMethodDescription(protocol,
                                                                                 selector,
                                                                                 isRequired,
                                                                                 isInstance);
    BOOL selectorInProtocol = (description.name != NULL);

    if (!selectorInProtocol) {
        unsigned int                    adoptedProtocolCount = 0;
        __unsafe_unretained Protocol ** adoptedProtocols;
        adoptedProtocols = protocol_copyProtocolList(protocol, &adoptedProtocolCount);

        while (!selectorInProtocol && adoptedProtocolCount) {
            description = protocol_getMethodDescription(adoptedProtocols[--adoptedProtocolCount],
                                                        selector,
                                                        isRequired,
                                                        isInstance);
            selectorInProtocol = (description.name != NULL);
        }
    }

    return selectorInProtocol;
}

NSArray * findValuesForKeyInContainer(id<NSCopying>key, id<MSKeySearchable>container) {

  NSMutableArray * values = [@[] mutableCopy];

  if ([container conformsToProtocol:@protocol(MSKeyContaining)]) {
    id<MSKeyContaining> keyedContainer = (id<MSKeyContaining>)container;
    if ([keyedContainer hasKey:key]) [values addObject:[keyedContainer valueForKey:key]];
  }

  for (id value in [container allValues]) {
    if ([value conformsToProtocol:@protocol(MSKeySearchable)])
    [values addObjectsFromArray:findValuesForKeyInContainer(key, (id<MSKeySearchable>)value)];
  }

  return values;
}

id findFirstValueForKeyInContainer(id<NSCopying>key, id<MSKeySearchable>container) {
  return [findValuesForKeyInContainer(key, container) firstObject];
}