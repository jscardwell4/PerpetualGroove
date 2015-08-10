//
//  MSKeyPath.m
//  MSKit
//
//  Created by Jason Cardwell on 9/6/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

#import "MSKeyPath.h"
#import "MSKitMacros.h"
#import "NSArray+MSKitAdditions.h"

@interface MSKeyPath ()

@property (nonatomic, strong) NSMutableArray * mutableKeys;

@end

@implementation MSKeyPath

/// keyPathFromString:
/// @param string
/// @return instancetype
+ (instancetype)keyPathFromString:(NSString *)string {
  if (!string) ThrowInvalidNilArgument(string);
  MSKeyPath * keyPath = [self new];
  [keyPath.mutableKeys addObjectsFromArray:[string componentsSeparatedByString:@"."]];
  return keyPath;
}

/// objectAtIndexedSubscript:
/// @param idx
/// @return NSString *
- (NSString *)objectAtIndexedSubscript:(NSUInteger)idx { return self.mutableKeys[idx]; }

/// setObject:atIndexedSubscript:
/// @param obj
/// @param idx
- (void)setObject:(NSString *)key atIndexedSubscript:(NSUInteger)idx { self.mutableKeys[idx] = key; }

/// insertKey:atIndex:
/// @param key
/// @param idx
- (void)insertKey:(NSString *)key atIndex:(NSUInteger)idx { [self.mutableKeys insertObject:key atIndex:idx]; }

/// countByEnumeratingWithState:objects:count:
/// @param state
/// @param buffer
/// @param len
/// @return NSUInteger
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])buffer
                                    count:(NSUInteger)len
{
  return [self.mutableKeys countByEnumeratingWithState:state objects:buffer count:len];
}

/// stringValue
/// @return NSString *
- (NSString *)stringValue { return [self.mutableKeys componentsJoinedByString:@"."]; }

/// stringValueToIndex:
/// @param idx Index of the first key to not include. Passing a negative value counts from the end with -1
///            includes all mutableKeys but that last key, -2 includes all but the last two mutableKeys, etc., ect.
/// @return NSString *
- (NSString *)stringValueToIndex:(NSInteger)idx {

  if (ABS(idx) > self.count) ThrowInvalidIndexArgument(idx);

  NSUInteger length = (idx >= 0 ? idx : self.count + idx);
  NSArray * includedKeys = [self.mutableKeys subarrayWithRange:NSMakeRange(0, length)];
  return [includedKeys componentsJoinedByString:@"."];

}

/// Key path string value with the selected number mutableKeys from the front omitted
/// @param idx Index of the first key to include. Passing a negative value counts from the end with -1
///            includes only the last key, -2 includes only the last two mutableKeys, etc., ect.
/// @return NSString *
- (NSString *)stringValueFromIndex:(NSInteger)idx {

  if (ABS(idx) > self.count) ThrowInvalidIndexArgument(idx);

  NSUInteger location = (idx >= 0 ? idx : self.count - 1 + idx);
  NSUInteger length   = self.count - location;
  NSArray * includedKeys = [self.mutableKeys subarrayWithRange:NSMakeRange(location, length)];
  return [includedKeys componentsJoinedByString:@"."];
  
}

/// firstKey
/// @return NSString *
- (NSString *)firstKey { return [self.mutableKeys firstObject]; }

/// lastKey
/// @return NSString *
- (NSString *)lastKey { return [self.mutableKeys lastObject]; }

/// appendKey:
/// @param key
- (void)appendKey:(NSString *)key { if (isStringKind(key)) [self.mutableKeys addObject:key]; }

/// appendKeys:
/// @param mutableKeys
- (void)appendKeys:(NSArray *)mutableKeys {
  [self.mutableKeys addObjectsFromArray:[mutableKeys filtered:^BOOL(id obj){ return isStringKind(obj); }]];
}

/// popFirst
/// @return NSString *
- (NSString *)popFirst {
  if ([self.mutableKeys isEmpty]) return nil;
  else {
    NSString * key = self.firstKey;
    [self.mutableKeys removeObjectAtIndex:0];
    return key;
  }
}

/// mutableKeys
/// @return NSMutableArray *
- (NSMutableArray *)mutableKeys { if (!_mutableKeys) _mutableKeys = [@[] mutableCopy]; return _mutableKeys; }

/// isEmpty
/// @return BOOL
- (BOOL)isEmpty { return [self.mutableKeys isEmpty]; }

/// count
/// @return NSUInteger
- (NSUInteger)count { return [self.mutableKeys count]; }

/// isSingleKey
/// @return BOOL
- (BOOL)isSingleKey { return (self.count == 1); }

/// popLast
/// @return NSString *
- (NSString *)popLast {
  if ([self.mutableKeys isEmpty]) return nil;
  else {
    NSString * key = self.lastKey;
    [self.mutableKeys removeLastObject];
    return key;
  }
}

/// keys
/// @return NSArray *
- (NSArray *)keys { return [NSArray arrayWithArray:self.mutableKeys]; }

/// description
/// @return NSString *
- (NSString *)description { return self.stringValue; }

@end
