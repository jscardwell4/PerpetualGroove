//
//  MSKeyPath.h
//  MSKit
//
//  Created by Jason Cardwell on 9/6/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

@import Foundation;

@interface MSKeyPath : NSObject <NSFastEnumeration>

/// keyPathFromString:
/// @param string
/// @return instancetype
+ (instancetype)keyPathFromString:(NSString *)string;

/// objectAtIndexedSubscript:
/// @param idx
/// @return NSString *
- (NSString *)objectAtIndexedSubscript:(NSUInteger)idx;

/// setObject:atIndexedSubscript:
/// @param key
/// @param idx
- (void)setObject:(NSString *)key atIndexedSubscript:(NSUInteger)idx;

/// insertKey:atIndex:
/// @param key
/// @param idx
- (void)insertKey:(NSString *)key atIndex:(NSUInteger)idx;

/// addKey:
/// @param key
- (void)appendKey:(NSString *)key;

/// appendKeys:
/// @param keys
- (void)appendKeys:(NSArray *)keys;

/// popFirst
/// @return NSString *
- (NSString *)popFirst;

/// popLast
/// @return NSString *
- (NSString *)popLast;

/// stringValueToIndex:
/// @param idx Index of the first key to not include. Passing a negative value counts from the end with -1
///            includes all keys but that last key, -2 includes all but the last two keys, etc., ect.
/// @return NSString *
- (NSString *)stringValueToIndex:(NSInteger)idx;

/// Key path string value with the selected number keys from the front omitted
/// @param idx Index of the first key to include. Passing a negative value counts from the end with -1
///            includes only the last key, -2 includes only the last two keys, etc., ect.
/// @return NSString *
- (NSString *)stringValueFromIndex:(NSInteger)idx;

@property (nonatomic, readonly) NSString * stringValue;
@property (nonatomic, readonly) NSString * firstKey;
@property (nonatomic, readonly) NSString * lastKey;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) BOOL       isEmpty;
@property (nonatomic, readonly) BOOL       isSingleKey;
@property (nonatomic, readonly) NSArray  * keys;

@end
