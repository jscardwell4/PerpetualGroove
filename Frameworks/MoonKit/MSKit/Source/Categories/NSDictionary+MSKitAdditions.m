//
//  NSDictionary+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 10/25/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "NSDictionary+MSKitAdditions.h"
//#import "MSJSONSerialization.h"
#import "MSKitMacros.h"
#import "NSObject+MSKitAdditions.h"
#import "MSDictionary.h"
#import "MSLog.h"
#import "NSMutableString+MSKitAdditions.h"
#import "NSArray+MSKitAdditions.h"
#import "MoonKit/MoonKit-Swift.h"

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

@interface NSObject ()
@property (nonatomic, readonly) id         JSONValue;
@end

@implementation NSDictionary (MSKitAdditions)

/// isEmpty
/// @return BOOL
- (BOOL)isEmpty { return self.count == 0; }

/// JSONString
/// @return NSString *
//- (NSString *)JSONString { return [JSONSerialization JSONFromObject:self.JSONObject options:MSJSONWriteFormatOptionsDefault];}

/// JSONObject
/// @return id
//- (id)JSONObject {
//
//  if ([NSJSONSerialization isValidJSONObject:self]) return self;
//  else if (![self count]) return NullObject;
//
//  NSMutableDictionary * dictionary = [NSMutableDictionary dictionaryWithCapacity:[self count]];
//
//  [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * stop) {
//
//    NSString * keyString = [key description];
//    dictionary[keyString] = obj;
//
//    if (![NSJSONSerialization isValidJSONObject:dictionary]) {
//      [dictionary removeObjectForKey:keyString];
//
//      if ([obj respondsToSelector:@selector(JSONObject)]) {
//        id jsonObj = [obj JSONObject];
//
//        if ([NSJSONSerialization isValidJSONObject:jsonObj])
//          dictionary[keyString] = jsonObj;
//        else
//          MSLogDebug(@"object of type %@ returned invalid JSON object",
//                     ClassTagStringForInstance(obj));
//      } else if ([obj respondsToSelector:@selector(JSONValue)])   {
//        id jsonValue = [obj valueForKey:@"JSONValue"];
//
//        if ([JSONSerialization isValidJSONValue:jsonValue])
//          dictionary[keyString] = jsonValue;
//        else
//          MSLogDebug(@"object of type %@ returned invalid JSON Value",
//                     ClassTagStringForInstance(obj));
//      }
//
//      NSAssert(![dictionary count] || [NSJSONSerialization isValidJSONObject:dictionary],
//               @"Only valid JSON values should have been added to dictionary");
//    }
//
//  }];
//
//  return dictionary;
//
//}

/// topLevelObjects
/// @return NSArray *
- (NSArray *)topLevelObjects { return [self allValues]; }

/// topLevelObjectsOfKind:
/// @param objectKind
/// @return NSArray *
- (NSArray *)topLevelObjectsOfKind:(Class)objectKind { return [[self allValues] topLevelObjectsOfKind:objectKind]; }

/// allObjectsOfKind:
/// @param objectKind
/// @return NSArray *
- (NSArray *)allObjectsOfKind:(Class)objectKind { return [[self allValues] allObjectsOfKind:objectKind]; }

/// topLevelObjectsConformingTo:
/// @param objectKind
/// @return NSArray *
- (NSArray *)topLevelObjectsConformingTo:(Protocol *)protocol {
  return [[self allValues] topLevelObjectsConformingTo:protocol];
}

/// allObjectsConformingTo:
/// @param objectKind
/// @return NSArray *
- (NSArray *)allObjectsConformingTo:(Protocol *)protocol { return [[self allValues] allObjectsConformingTo:protocol]; }

/// dictionaryFromDictionary:replacements:
/// @param dictionary
/// @param replacements
/// @return instancetype
+ (instancetype)dictionaryFromDictionary:(NSDictionary *)dictionary replacements:(NSDictionary *)replacements {
  NSMutableDictionary * d = [dictionary mutableCopy];
  for (id key in replacements)
    for (id objectKey in [dictionary allKeysForObject:key]) d[objectKey] = replacements[key];
  return [self dictionaryWithDictionary:d];
}

/// dictionaryWithSharedKeys:
/// @param keys
/// @return instancetype
+ (instancetype)dictionaryWithSharedKeys:(NSArray *)keys {
  id sharedKeySet = [NSDictionary sharedKeySetForKeys:keys];
  return (sharedKeySet ? [[self class] dictionaryWithSharedKeySet:sharedKeySet] : nil);
}

/// dictionaryByRemovingEntriesForKeys:
/// @param keys
/// @return instancetype
- (instancetype)dictionaryByRemovingEntriesForKeys:(NSArray *)keys {
  NSMutableDictionary * dictionary = [self mutableCopy];
  [dictionary removeObjectsForKeys:keys];
  return dictionary;
}

/// dictionaryByRemovingEntryForKey:
/// @param key
/// @return instancetype
- (instancetype)dictionaryByRemovingEntryForKey:(id<NSCopying>)key {
  return ([self hasKey:key] ? [self dictionaryByRemovingEntriesForKeys:@[key]] : self);
}

/// dictionaryByAddingEntriesFromDictionary:
/// @param dictionary
/// @return instancetype
- (instancetype)dictionaryByAddingEntriesFromDictionary:(NSDictionary *)dictionary {
  NSMutableDictionary * d = [self mutableCopy];
  [d addEntriesFromDictionary:dictionary];
  return d;
}

/// dictionaryByMappingObjectsToBlock:
/// @param block
/// @return instancetype
- (instancetype)dictionaryByMappingObjectsToBlock:(id (^)(id key, id obj))block {
  NSMutableDictionary * d = [self mutableCopy];
  [d mapObjectsToBlock:block];
  return [[self class] dictionaryWithDictionary:d];
}

/// dictionaryByMappingKeysToBlock:
/// @param block
/// @return instancetype
- (instancetype)dictionaryByMappingKeysToBlock:(id (^)(id key, id obj))block {
  NSMutableDictionary * d = [self mutableCopy];
  [d mapKeysToBlock:block];
  return [[self class] dictionaryWithDictionary:d];
}

/// hasKey:
/// @param key
/// @return BOOL
- (BOOL)hasKey:(id)key {
  return (CFDictionaryContainsKey((__bridge CFDictionaryRef)(self), (__bridge const void *)(key)));
}

/// MSDictionaryValue
/// @return MSDictionary *
- (MSDictionary *)MSDictionaryValue { return [MSDictionary dictionaryWithDictionary:self]; }

@end

@implementation NSMutableDictionary (MSKitAdditions)

/// mapObjectsToBlock:
/// @param block
- (void)mapObjectsToBlock:(id (^)(id key, id obj))block {
  for (id key in [self allKeys]) self[key] = block(key, self[key]);
}

/// mapKeysToBlock:
/// @param block
- (void)mapKeysToBlock:(id (^)(id key, id obj))block {
  for (id key in [self allKeys]) {
    id object = self[key];
    id kPrime = block(key, object);
    [self removeObjectForKey:key];
    self[kPrime] = object;
  }
}

@end
