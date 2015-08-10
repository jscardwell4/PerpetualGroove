//
//  NSMapTable+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 10/14/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "NSMapTable+MSKitAdditions.h"

@implementation NSMapTable (MSKitAdditions)

- (NSArray *)allValues { return self.objectEnumerator.allObjects; }

+ (id)weakToWeakObjectsMapTableFromDictionary:(NSDictionary *)dictionary
{
    NSMapTable * mapTable = [self weakToWeakObjectsMapTable];
    for (id key in dictionary) mapTable[key] = dictionary[key];
    return mapTable;
}

+ (id)weakToStrongObjectsMapTableFromDictionary:(NSDictionary *)dictionary
{
    NSMapTable * mapTable = [self weakToStrongObjectsMapTable];
    for (id key in dictionary) mapTable[key] = dictionary[key];
    return mapTable;
}

+ (id)strongToWeakObjectsMapTableFromDictionary:(NSDictionary *)dictionary
{
    NSMapTable * mapTable = [self strongToWeakObjectsMapTable];
    for (id key in dictionary) mapTable[key] = dictionary[key];
    return mapTable;
}

+ (id)strongToStrongObjectsMapTableFromDictionary:(NSDictionary *)dictionary
{
    NSMapTable * mapTable = [self strongToStrongObjectsMapTable];
    for (id key in dictionary) mapTable[key] = dictionary[key];
    return mapTable;
}

- (id)objectForKeyedSubscript:(id)key { return [self objectForKey:key]; }

- (void)setObject:(id)object forKeyedSubscript:(id<NSCopying>)key
{
    [self setObject:object forKey:key];
}

- (NSArray *)allKeys { return self.keyEnumerator.allObjects; }

- (BOOL)hasKey:(id<NSCopying>)key
{
    return (CFDictionaryContainsKey((__bridge CFDictionaryRef)(self.dictionaryRepresentation),
                                    (__bridge const void *)(key)));
}

@end
