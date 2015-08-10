//
//  NSMutableArray+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 5/24/11.
//  Copyright 2011 Moondeer Studios. All rights reserved.
//
#import "MSLog.h"
#import "NSArray+MSKitAdditions.h"
#import "NSString+MSKitAdditions.h"
#import "MSKitMacros.h"
#import "NSObject+MSKitAdditions.h"
//#import "MSJSONSerialization.h"
#import "NSMutableString+MSKitAdditions.h"
#import "MoonKit/MoonKit-Swift.h"

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

@interface NSObject ()
@property (nonatomic, readonly) id         JSONValue;
@end

@implementation NSArray (MSKitAdditions)

/// allValues
/// @return NSArray *
- (NSArray *)allValues { return self; }

/// topLevelObjects
/// @return NSArray *
- (NSArray *)topLevelObjects { return self; }

/// topLevelObjectsOfKind:
/// @param objectKind
/// @return NSArray *
- (NSArray *)topLevelObjectsOfKind:(Class)objectKind {
  return [self filtered:^BOOL(id evaluatedObject) { return [evaluatedObject isKindOfClass:objectKind]; }];
}

/// topLevelObjectsConformingTo:
/// @param objectKind
/// @return NSArray *
- (NSArray *)topLevelObjectsConformingTo:(Protocol *)protocol {
  return [self filtered:^BOOL(id evaluatedObject) { return [evaluatedObject conformsToProtocol:protocol]; }];
}

/// allObjectsOfKind:
/// @param objectKind
/// @return NSArray *
- (NSArray *)allObjectsOfKind:(Class)objectKind {

  NSMutableArray * objects = [[self topLevelObjectsOfKind:objectKind] mutableCopy];
  [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if ([obj conformsToProtocol:@protocol(MSObjectContaining)])
      [objects addObjectsFromArray:[obj allObjectsOfKind:objectKind]];
  }];

  return objects;

}

/// allObjectsConformingTo:
/// @param objectKind
/// @return NSArray *
- (NSArray *)allObjectsConformingTo:(Protocol *)protocol {

  NSMutableArray * objects = [[self topLevelObjectsConformingTo:protocol] mutableCopy];
  [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if ([obj conformsToProtocol:@protocol(MSObjectContaining)])
      [objects addObjectsFromArray:[obj allObjectsConformingTo:protocol]];
  }];

  return objects;
  
}


/// _lastObjectForKeyPath:
/// @param keyPath
/// @return id
- (id)_lastObjectForKeyPath:(NSString *)keyPath {
  return [self.lastObject valueForKeyPath:keyPath];
}

/// isEmpty
/// @return BOOL
- (BOOL)isEmpty { return self.count == 0; }

/// arrayWithObject:count:
/// @param obj
/// @param count
/// @return NSArray *
+ (NSArray *)arrayWithObject:(id)obj count:(NSUInteger)count {
  return [NSMutableArray arrayWithObject:obj count:count];
}

/// JSONString
/// @return NSString *
//- (NSString *)JSONString {
//  return [MSJSONSerialization JSONFromObject:self.JSONObject options:MSJSONWriteFormatOptionsDefault];
//  id        jsonObject = self.JSONObject;
//  NSError * error;
//  NSData  * jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
//                                                       options:NSJSONWritingPrettyPrinted
//                                                         error:&error];
//
//  if (error || !jsonData) {
//    MSHandleErrors(error);
//    return nil;
//  } else {
//    NSMutableString * jsonString = [[NSString stringWithData:jsonData] mutableCopy];
//    [jsonString replaceRegEx:@"^(\\s*\"[^\"]+\") :" withString:@"$1:"];
//    [jsonString replaceOccurrencesOfString:@"\\" withString:@"" options:0 range:NSMakeRange(0, jsonString.length)];
//    return jsonString;
//  }
//}

/// writeJSONToFile:
/// @param file
/// @return BOOL
//- (BOOL)writeJSONToFile:(NSString *)file {
//  NSString * json = self.JSONString;
//  return StringIsEmpty(json) ? NO : [json writeToFile:file];
//}

/// JSONObject
/// @return id
//- (id)JSONObject {
//  if ([NSJSONSerialization isValidJSONObject:self])
//    return self;
//
//  else if (![self count])
//    return NullObject;
//
//  NSMutableArray * array = [NSMutableArray arrayWithCapacity:[self count]];
//
//  [self enumerateObjectsUsingBlock:
//   ^(id obj, NSUInteger idx, BOOL * stop)
//  {
//    array[idx] = obj;
//
//    if (![NSJSONSerialization isValidJSONObject:array]) {
//      [array removeObjectAtIndex:idx];
//
//      if ([obj respondsToSelector:@selector(JSONObject)]) {
//        id jsonObj = [obj JSONObject];
//
//        if ([NSJSONSerialization isValidJSONObject:jsonObj])
//          array[idx] = jsonObj;
//        else
//          MSLogDebug(@"object of type %@ returned invalid JSON object",
//                     ClassTagStringForInstance(obj));
//      } else if ([obj respondsToSelector:@selector(JSONValue)]) {
//        id jsonValue = [obj valueForKey:@"JSONValue"];
//
//        if ([MSJSONSerialization isValidJSONValue:jsonValue])
//          array[idx] = jsonValue;
//        else
//          MSLogDebug(@"object of type %@ returned invalid JSON Value",
//                     ClassTagStringForInstance(obj));
//      }
//
//      NSAssert(![array count] || [NSJSONSerialization isValidJSONObject:array],
//               @"Only valid JSON values should have been added to array");
//    }
//  }];
//
//  return array;
//}

/// uniqued
/// @return NSArray *
- (NSArray *)uniqued { return [[self set] allObjects]; }

/// arrayFromRange:
/// @param range
/// @return NSArray *
+ (NSArray *)arrayFromRange:(NSRange)range {
  NSMutableArray * array = [NSMutableArray arrayWithCapacity:range.length];

  for (NSUInteger i = range.location; i < range.location + range.length; i++)
    array[i] = @(i);

  return array;
}

/// lastIndex
/// @return NSUInteger
- (NSUInteger)lastIndex
{ NSInteger count = [self count]; return (count ? count - 1 : NSUIntegerMax); }

/// set
/// @return NSSet *
- (NSSet *)set
{ return [NSSet setWithArray:self]; }

/// orderedSet
/// @return NSOrderedSet *
- (NSOrderedSet *)orderedSet
{ return [NSOrderedSet orderedSetWithArray:self]; }

/// arrayByAddingObjects:
/// @param objects
/// @return NSArray *
- (NSArray *)arrayByAddingObjects:(id)objects {
  if ([objects isKindOfClass:[NSArray class]])
    return [self arrayByAddingObjectsFromArray:objects];
  else if ([objects isKindOfClass:[NSSet class]])
    return [self arrayByAddingObjectsFromSet:objects];
  else if ([objects isKindOfClass:[NSOrderedSet class]])
    return [self arrayByAddingObjectsFromOrderedSet:objects];
  else if ([objects isKindOfClass:[NSDictionary class]])
    return [self arrayByAddingValuesFromDictionary:objects];
  else if (objects)
    return [self arrayByAddingObject:objects];
  else
    return nil;
}

/// arrayByAddingKeysFromDictionary:
/// @param dictionary
/// @return NSArray *
- (NSArray *)arrayByAddingKeysFromDictionary:(NSDictionary *)dictionary {
  return [self arrayByAddingObjectsFromArray:[dictionary allKeys]];
}

/// arrayByAddingValuesFromDictionary:
/// @param dictionary
/// @return NSArray *
- (NSArray *)arrayByAddingValuesFromDictionary:(NSDictionary *)dictionary {
  return [self arrayByAddingObjectsFromArray:[dictionary allValues]];
}

/// arrayByAddingObjectsFromSet:
/// @param set
/// @return NSArray *
- (NSArray *)arrayByAddingObjectsFromSet:(NSSet *)set {
  return [self arrayByAddingObjectsFromArray:[set allObjects]];
}

/// arrayByAddingObjectsFromOrderedSet:
/// @param orderedSet
/// @return NSArray *
- (NSArray *)arrayByAddingObjectsFromOrderedSet:(NSOrderedSet *)orderedSet {
  return [self arrayByAddingObjectsFromArray:[orderedSet array]];
}

/// filteredArrayUsingPredicateWithFormat:
/// @param format
/// @return NSArray *
- (NSArray *)filteredArrayUsingPredicateWithFormat:(NSString *)format, ...{
  va_list args;
  va_start(args, format);
  NSPredicate * predicate = [NSPredicate predicateWithFormat:format arguments:args];
  va_end(args);

  if (!predicate) {
    return nil;
  } else
    return [self filteredArrayUsingPredicate:predicate];
}

/// filteredArrayUsingPredicateWithBlock:
/// @param block
/// @return NSArray *
- (NSArray *)filteredArrayUsingPredicateWithBlock:(BOOL (^)(id evaluatedObject, NSDictionary * bindings))block {
  return [self filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:block]];
}

/// filtered:
/// @param block
/// @return NSArray *
- (NSArray *)filtered:(BOOL (^)(id evaluatedObject))block {

  NSMutableArray * array = [self mutableCopy];
  [array filter:block];
  return array;

}

/// filteredUsingPredicate:
/// @param predicate
/// @return NSArray *
- (NSArray *)filteredUsingPredicate:(NSPredicate *)predicate {
  return [self filteredArrayUsingPredicate:predicate];
}


/// findFirstUsingPredicate:
/// @param predicate
/// @return id
- (id)findFirstUsingPredicate:(NSPredicate *)predicate {

  __block id match = nil;

  [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if ([predicate evaluateWithObject:obj]) {
      match = obj;
      *stop = YES;
    }
  }];

  return match;

}


/// findFirst:
/// @param predicate
/// @return id
- (id)findFirst:(BOOL (^)(id evaluatedObject))predicate {

  __block id match = nil;

  [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if (predicate(obj)) {
      match = obj;
      *stop = YES;
    }
  }];

  return match;

}

/// objectPassingTest:
/// @param predicate
/// @return id
- (id)objectPassingTest:(BOOL (^)(id obj, NSUInteger idx))predicate {
  __block NSUInteger index = NSNotFound;
  [self enumerateObjectsUsingBlock:^(id o, NSUInteger i, BOOL * s) {
    if (predicate(o, i)) index = i;

    if (index != NSNotFound) *s = YES;
  }];
  return (index == NSNotFound ? nil : self[index]);
}

/// objectsPassingTest:
/// @param predicate
/// @return NSArray *
- (NSArray *)objectsPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL * stop))predicate {
  NSIndexSet * idxs = [self indexesOfObjectsPassingTest:predicate];
  return (idxs.count ? [self objectsAtIndexes:idxs] : nil);
}

/// mapped:
/// @param block
/// @return NSArray *
- (NSArray *)mapped:(id (^)(id, NSUInteger))block {
  NSMutableArray * array = [self mutableCopy];
  [array map:block];
  return array;
}

/// flattened
/// @return NSArray *
- (NSArray *)flattened {
  NSMutableArray * array = [self mutableCopy];
  [array flatten];
  return array;
}

/// compacted
/// @return NSArray *
- (NSArray *)compacted {
  NSMutableArray * array = [self mutableCopy];
  [array compact];
  return array;
}

@end


@implementation NSMutableArray (MSKitAdditions)

/// arrayWithObject:count:
/// @param obj
/// @param count
/// @return instancetype
+ (instancetype)arrayWithObject:(id)obj count:(NSUInteger)count {
  if (!(obj && count)) return nil;

  NSMutableArray * array = [NSMutableArray arrayWithCapacity:count];

  for (int i = 0; i < count; i++) {
    array[i] = obj;
  }

  return array;
}

/// arrayWithNullCapacity:
/// @param capacity
/// @return id
+ (id)arrayWithNullCapacity:(NSUInteger)capacity {
  NSMutableArray * array = [NSMutableArray arrayWithCapacity:capacity];
  [array replaceAllObjectsWithNull];
  return array;
}

/// filter:
/// @param block
- (void)filter:(BOOL (^)(id evaluatedObject))block {

  NSMutableIndexSet * indexes = [NSMutableIndexSet indexSet];

  for (NSUInteger i = 0; i < [self count]; i++)
    if (!block(self[i])) [indexes addIndex:i];

  if ([indexes count])
    [self removeObjectsAtIndexes:indexes];

}

/// flatten
- (void)flatten {
  BOOL flat = NO;

  while (!flat) {
    flat = YES;

    for (int i = 0; i < self.count; i++) {
      if ([self[i] isKindOfClass:[NSArray class]]) {
        NSArray * array = self[i];
        [self removeObjectAtIndex:i];

        if (array.count) {
          flat = NO;
          NSIndexSet * indices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i, array.count)];
          [self insertObjects:array atIndexes:indices];
        }
      }
    }
  }
}

/// unique
- (void)unique { [self setArray:[self uniqued]]; }

/// map:
/// @param block
- (void)map:(id (^)(id, NSUInteger))block {
  for (int i = 0; i < self.count; i++)
    self[i] = block(self[i], i);
}

/// replaceAllObjectsWithNull
- (void)replaceAllObjectsWithNull {
  for (int i = 0; i < [self count]; i++)
    self[i] = [NSNull null];
}

/// compact
- (void)compact {
  [self filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == nil"]];
}

@end

NSArray *_NSArrayOfVariableNames(NSString * commaSeparatedNamesString, ...) {
  if (!commaSeparatedNamesString) return nil;
  else return [commaSeparatedNamesString componentsSeparatedByRegEx:@",\\s*"];
}
