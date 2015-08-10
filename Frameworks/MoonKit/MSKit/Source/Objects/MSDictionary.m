//
//  MSDictionary.m
//  MSKit
//
//  Created by Jason Cardwell on 4/17/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
#import "MSDictionary.h"
#import "NSArray+MSKitAdditions.h"
#import "NSDictionary+MSKitAdditions.h"
#import "NSOrderedSet+MSKitAdditions.h"
#import "NSString+MSKitAdditions.h"
#import "NSValue+MSKitAdditions.h"
//#import "MSJSONSerialization.h"
#import "NSPointerArray+MSKitAdditions.h"
#import "NSNumber+MSKitAdditions.h"
#import "MSKitMacros.h"
#import "MSLog.h"
#import "MSXMLParserDelegate.h"
#import "MSStack.h"
#import "MSKeyPath.h"
#import "NSMutableString+MSKitAdditions.h"
#import "MoonKit/MoonKit-Swift.h"

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

//@interface NSObject ()
//@property (nonatomic, readonly) id         JSONValue;
//@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - MSDictionary
////////////////////////////////////////////////////////////////////////////////

@interface MSDictionary ()

@property (nonatomic, strong, readwrite) NSMutableArray      * keys;
@property (nonatomic, strong, readwrite) NSMutableArray      * values;
@property (nonatomic, strong, readwrite) NSMutableDictionary * dictionary;

@end


@implementation MSDictionary {
  MSDictionary * _userInfo;
  BOOL           _isUserInfo;
  NSSet        * _validKeys;
}

/// init
/// @return id
- (id)init {

  if ((self = [super init])) {
    self.keys       = [@[] mutableCopy];
    self.values     = [@[] mutableCopy];
    self.dictionary = [@{} mutableCopy];
  }

  return self;

}

////////////////////////////////////////////////////////////////////////////////
#pragma mark MSDictionary methods
////////////////////////////////////////////////////////////////////////////////

/// dictionaryWithDictionary:convertFoundationClasses:
/// @param dictionary
/// @param convert
/// @return MSDictionary *
+ (MSDictionary *)dictionaryWithDictionary:(NSDictionary *)dictionary convertFoundationClasses:(BOOL)convert {
  MSDictionary * result = [self dictionaryWithDictionary:dictionary];
  if (convert) [result convertFoundationClasses];
  return result;
}



/// dictionaryByParsingXML:
/// @param xmlData
/// @return MSDictionary *
+ (MSDictionary *)dictionaryByParsingXML:(NSData *)xmlData {

  __block MSDictionary * dictionary      = [MSDictionary dictionary];
  __block MSKeyPath    * keyPath         = [MSKeyPath new];

  NSXMLParser * parser = [[NSXMLParser alloc] initWithData:xmlData];

  /// Handle element start
  NSString * didStartElementKey =
  SelectorString(@selector(parser:didStartElement:namespaceURI:qualifiedName:attributes:));

  void (^didStartElement)(NSXMLParser *, NSString *, NSString *, NSString *, NSDictionary *) =
  ^(NSXMLParser * parser, NSString * element, NSString * uri, NSString * qName, NSDictionary * attrs) {

    // Create fresh dictionary to be inserted somewhere below
    MSDictionary * elementValue = [MSDictionary dictionaryWithDictionary:attrs];

    // Get the appropriate dictionary to update
    MSDictionary * currentDictionary = [dictionary valueForPath:keyPath];

    // Check if there is an existing entry for element in the current dictionary
    if ([currentDictionary hasKey:element]) {

      // Get the existing entry, wrap it in a dictionary if necessary
      id existingEntry = currentDictionary[element];

      // Check if we already have an array
      if (isArrayKind(existingEntry)) {

        [existingEntry addObject:elementValue];

      }

      // If we don't, create one
      else {

        if (!isDictionaryKind(existingEntry))
          existingEntry = [MSDictionary dictionaryWithObject:existingEntry forKey:element];

        // Replace existing with array containing existing and an empty dictionary
        currentDictionary[element] = [@[existingEntry, elementValue] mutableCopy];

      }

      // Push key to point to last object of array
      [keyPath appendKeys:@[element, @"@lastObject"]];

    }

    // If no existing entry, insert element value
    else {

      currentDictionary[element] = elementValue;

      [keyPath appendKey:element];

    }

  };


  /// Handle characters found
  NSString * foundCharactersKey = SelectorString(@selector(parser:foundCharacters:));

  void (^foundCharacters)(NSXMLParser *, NSString *) = ^(NSXMLParser * parser, NSString * characters) {

    // Don't add characters if they are nothing but whitespace
    if ([[characters stringByRemovingCharactersFromSet:NSWhitespaceAndNewlineCharacters] length]) {

      // Pop last key since we want to replace the dictionary that is there
      NSString * key = [keyPath popLast];
      BOOL pushBack = YES;

      // Get the underlying key if we popped lastObject off and then put it back
      if ([@"@lastObject" isEqualToString:key]) {
        key = keyPath.lastKey;
        [keyPath appendKey:@"@lastObject"];
        pushBack = NO;
      }


      // Get the appropriate dictionary and update
      MSDictionary * currentDictionary = [dictionary valueForPath:keyPath];
      MSDictionary * existingObject = currentDictionary[key];
      if (existingObject && isDictionaryKind(existingObject) && ![existingObject isEmpty])
        currentDictionary = existingObject;

      currentDictionary[key] = characters;

      // Push key back onto key path so it can be popped off when element ends
      if (pushBack) [keyPath appendKey:key];

    }

  };

  /// Handle element end
  NSString * didEndElementKey = SelectorString(@selector(parser:didEndElement:namespaceURI:qualifiedName:));

  void (^didEndElement)(NSXMLParser *, NSString *, NSString *, NSString *) =
  ^(NSXMLParser * parser, NSString * elementName, NSString * namespaceURI, NSString * qName) {

    // Remove the element from the key path
    NSString * previousElement = [keyPath popLast];
    if ([@"@lastObject" isEqualToString:previousElement]) [keyPath popLast];

  };

  /// Create our parser delegate with the handlers we have defined.
  MSXMLParserDelegate * delegate =
  [MSXMLParserDelegate parserDelegateWithHandlers:@{ didStartElementKey : didStartElement,
                                                     foundCharactersKey : foundCharacters,
                                                     didEndElementKey   : didEndElement }];
  parser.delegate = delegate;

  /// Return the dictionary if parse successful and nil otherwise
  return [parser parse] ? dictionary : nil;

}


/// dictionaryByParsingArray:
/// @param array
/// @return MSDictionary *
+ (MSDictionary *)dictionaryByParsingArray:(NSArray *)array {
  return [self dictionaryByParsingArray:array separator:@":"];
}

/// dictionaryByParsingArray:separator:
/// @param array
/// @param separator
/// @return MSDictionary *
+ (MSDictionary *)dictionaryByParsingArray:(NSArray *)array separator:(NSString *)separator {
  if (!separator) ThrowInvalidNilArgument("separator");
  MSDictionary * dictionary = [self new];
  for (NSString * entry in array) {
    if (!isStringKind(entry)) continue;
    NSArray * keyValue = [entry componentsSeparatedByString:separator];
    if ([keyValue count] > 1) {
      NSString * key = [keyValue[0] stringByTrimmingWhitespace];
      NSString * value = nil;
      if ([keyValue count] > 2) {
        NSArray * valueArray = [keyValue subarrayWithRange:NSMakeRange(1, [keyValue count] - 1)];
        value = [[valueArray componentsJoinedByString:separator] stringByTrimmingWhitespace];
      } else value = [keyValue[1] stringByTrimmingWhitespace];
      if (key && value)
        dictionary[key] = value;
    }
  }
  return dictionary.isEmpty ? nil : dictionary;
}

/// setRequiresStringKeys:
/// @param requiresStringKeys
- (void)setRequiresStringKeys:(BOOL)requiresStringKeys {
  if (!requiresStringKeys) _requiresStringKeys = requiresStringKeys;
  else {
    BOOL isCompliant = YES;

    for (id object in self.keys) if (!isStringKind(object)) { isCompliant = NO; break; }

    if (!isCompliant) ThrowInvalidInternalInconsistency(current set of keys are not all strings);
    else _requiresStringKeys = requiresStringKeys;
  }
}

/// dictionaryWithValuesForKeys:usingBlock:
/// @param keys
/// @param block
/// @return MSDictionary *
+ (MSDictionary *)dictionaryWithValuesForKeys:(NSArray *)keys usingBlock:(id (^)(id<NSCopying> key))block {

  if (!block) ThrowInvalidNilArgument(block);

  MSDictionary * dictionary = [MSDictionary dictionary];

  for (NSString * key in keys) {
    id value = block(key);
    if (value) dictionary[key] = value;
  }

  return dictionary;

}

/// compactedDictionary
/// @return MSDictionary *
- (MSDictionary *)compactedDictionary {
  MSDictionary * dictionary = [self copy];
  [dictionary compact];
  return dictionary;
}

/// dictionaryWithValuesForKeys:
/// @param keys
/// @return MSDictionary *
- (MSDictionary *)dictionaryWithValuesForKeys:(NSArray *)keys {
  NSDictionary * source     = [super dictionaryWithValuesForKeys:keys];
  MSDictionary * dictionary = [MSDictionary dictionaryWithDictionary:source];
  [dictionary compact];

  return dictionary;
}

/// valueForPath:
/// @param path
/// @return id
- (id)valueForPath:(MSKeyPath *)path { return path.count ? [self valueForKeyPath:path.stringValue] : self; }

/// convertFoundationClasses
- (void)convertFoundationClasses {

  __weak MSDictionary * weakself = self;

  [self.dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    if (isDictionaryKind(obj) && ![obj isKindOfClass:[MSDictionary class]])
      weakself[key] = [MSDictionary dictionaryWithDictionary:obj convertFoundationClasses:YES];
  }];

}

/// isEmpty
/// @return BOOL
- (BOOL)isEmpty { return ([self count] == 0); }

/// firstKey
/// @return id<NSCopying>
- (id<NSCopying>)firstKey { return self.isEmpty ? nil : [self.keys firstObject]; }

/// lastKey
/// @return id<NSCopying>
- (id<NSCopying>)lastKey { return self.isEmpty ? nil : [self.keys lastObject]; }

/// firstValue
/// @return id
- (id)firstValue { return self.isEmpty ? nil : [self.values firstObject]; }

/// lastValue
/// @return id
- (id)lastValue { return self.isEmpty ? nil : [self.values lastObject]; }

/// dictionaryWithValuesForKeys:fromDictionary:
/// @param keys
/// @param dictionary
/// @return MSDictionary *
+ (MSDictionary *)dictionaryWithValuesForKeys:(NSArray *)keys
                               fromDictionary:(NSDictionary *)dictionary {
  MSDictionary * sourceDictionary = [MSDictionary dictionaryWithDictionary:dictionary];
  MSDictionary * returnDictionary = [sourceDictionary dictionaryWithValuesForKeys:keys];
  [returnDictionary compact];

  return returnDictionary;
}

/// formattedDescription
/// @return NSString *
- (NSString *)formattedDescription { return [self formattedDescriptionWithOptions:0 levelIndent:0]; }

/// formattedDescriptionWithLevelIndent:
/// @param levelIndent
/// @return NSString *
- (NSString *)formattedDescriptionWithLevelIndent:(NSUInteger)levelIndent {
  return [self formattedDescriptionWithOptions:0 levelIndent:levelIndent];
}

/// formattedDescriptionWithOptions:levelIndent:
/// @param options
/// @param levelIndent
/// @return NSString *
- (NSString *)formattedDescriptionWithOptions:(NSUInteger)options levelIndent:(NSUInteger)levelIndent {

//  NSMutableString * description = [self.JSONString mutableCopy];
//  [description replaceRegEx:@"(?<=\\s)[\\{\\[]|[\\]\\}],?$|,$|\\b\\\"|\\\"\\b|\\\",?$|(?<=: )\\\"|^[\\{\\[]"
//                 withString:@""];
//  [description shiftRight:levelIndent];

//  return description;
  return [self description];

}

/// objectAtIndexedSubscript:
/// @param idx
/// @return id
- (id)objectAtIndexedSubscript:(NSUInteger)idx { return self.values[idx]; }

/// objectAtIndex:
/// @param idx
/// @return id
- (id)objectAtIndex:(NSUInteger)idx { return [self objectAtIndexedSubscript:idx]; }

/// keyAtIndex:
/// @param idx
/// @return id
- (id)keyAtIndex:(NSUInteger)idx { return self.keys[idx]; }

/// dictionaryBySortingByKeys:
/// @param sortedKeys
/// @return MSDictionary *
- (MSDictionary *)dictionaryBySortingByKeys:(NSArray *)sortedKeys {
  MSDictionary * dictionary = [MSDictionary dictionaryWithDictionary:self];
  [dictionary sortByKeys:sortedKeys];
  return dictionary;
}

/// validKeys
/// @return NSSet *
- (NSSet *)validKeys { return _validKeys; }

/// isValidKey:
/// @param key
/// @return BOOL
- (BOOL)isValidKey:(id<NSCopying>)key {
  if (_validKeys)
    return [_validKeys containsObject:key];

  else if (_requiresStringKeys)
    return isStringKind((id)key);

  else return YES;
}

/// popObjectForKey:
/// @param key
/// @return id
- (id)popObjectForKey:(id<NSCopying>)key {
  id object = self[key];
  if (object) [self removeObjectForKey:key];
  return object;
}

/// filter:
/// @param predicate
- (void)filter:(BOOL (^)(id<NSCopying> key, id value))predicate {
  NSMutableIndexSet * indexesToRemove = [NSMutableIndexSet indexSet];
  for (NSUInteger i = 0; i < [self count]; i++) {
    id<NSCopying> key   = self.keys[i];
    id            value = self.values[i];
    assert(key && value);
    if (!predicate(key, value)) [indexesToRemove addIndex:i];
  }
  if ([indexesToRemove count]) [self removeObjectsAtIndexes:indexesToRemove];
}

/// compact
- (void)compact {

  [self.dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    if ([obj isMemberOfClass:[MSDictionary class]]) {
      [obj compact];
      if ([obj isEmpty]) self[key] = NullObject;
    } else if ([obj respondsToSelector:@selector(count)] && ![obj count])
      self[key] = NullObject;
  }];

  NSDictionaryPredicateBlock test = ^BOOL (id key, id obj, BOOL * stop) {
    return ValueIsNil(obj);
  };
  NSArray * keysToRemove          = [[self.dictionary keysOfEntriesPassingTest:test] allObjects];
  [self removeObjectsForKeys:keysToRemove];
}

/// compress
- (void)compress {

  for (id value in self.values) if ([value isMemberOfClass:[self class]]) [value compress];

  MSDictionary * replacementKeys   = [MSDictionary dictionary];
  MSDictionary * replacementValues = [MSDictionary dictionary];

  NSDictionaryEnumerationBlock enumerate = ^(id key, id obj, BOOL * stop) {

    if (!(isStringKind(key) && isDictionaryKind(obj) && [obj count] == 1)) return;

    id innerKey = [obj allKeys][0];

    if (!isStringKind(innerKey)) return;

    NSString * keypath = [@"." join:@[key, innerKey]];
    id         value   = obj[innerKey];
    NSUInteger index   = [self.keys indexOfObject:key];
    replacementKeys[@(index)]   = keypath;
    replacementValues[@(index)] = value;

  };

  [self enumerateKeysAndObjectsUsingBlock:enumerate];

  for (NSNumber * indexValue in replacementKeys) {
    NSUInteger index = UnsignedIntegerValue(indexValue);
    id         key   = self.keys[index];
    [self removeObjectForKey:key];

    NSString * replacementKey = replacementKeys[indexValue];
    id         value          = replacementValues[indexValue];

    while (isDictionaryKind(value) && [value count] == 1 && isStringKind([value allKeys][0])) {
      replacementKey = [@"." join:@[replacementKey, [value allKeys][0]]];
      value          = value[[value allKeys][0]];
    }

    self.dictionary[replacementKey] = value;
    [self.keys insertObject:replacementKey atIndex:index];
    [self.values insertObject:value atIndex:index];

  }

}

/// sortByKeys:
/// @param sortedKeys
- (void)sortByKeys:(NSArray *)sortedKeys {
  NSMutableOrderedSet * keys = [NSMutableOrderedSet orderedSetWithArray:sortedKeys];
  [keys intersectOrderedSet:[NSOrderedSet orderedSetWithArray:self.keys]];

  NSMutableOrderedSet * extraKeys = [keys mutableCopy];
  [extraKeys minusOrderedSet:keys];

  NSMutableArray * values = [@[] mutableCopy];

  for (id key in keys) [values addObject:self[key]];

  for (id key in extraKeys) [values addObject:self[key]];

  [keys addObjectsFromArray:[extraKeys array]];

  self.keys   = [[keys array] mutableCopy];
  self.values = values;
}

/// sortKeysUsingSelector:
/// @param comparator
- (void)sortKeysUsingSelector:(SEL)comparator {
  [self.keys sortUsingSelector:comparator];
  self.values = [[self.dictionary objectsForKeys:self.keys notFoundMarker:NullObject] mutableCopy];
}

/// removeObjectAtIndex:
/// @param index
- (void)removeObjectAtIndex:(NSUInteger)index {
  if (index >= [self.keys count]) ThrowInvalidIndexArgument(index);
  else [self removeObjectForKey:self.keys[index]];
}

/// removeObjectsAtIndexes:
/// @param indexes
- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes {
  [self removeObjectsForKeys:[self.keys objectsAtIndexes:indexes]];
}

/// replaceKey:withKey:
/// @param key
/// @param replacementKey
- (void)replaceKey:(id)key withKey:(id)replacementKey {
  if (!replacementKey)
    ThrowInvalidNilArgument(replacementKey);

  else if ([self.keys containsObject:replacementKey])
    ThrowInvalidArgument(replacementKey, "already has an entry");

  else if ([self.keys containsObject:key]) {
    NSUInteger idx   = [self.keys indexOfObject:key];
    id         value = self.values[idx];
    [self.keys replaceObjectAtIndex:idx withObject:replacementKey];
    self.dictionary[replacementKey] = value;
    [self.dictionary removeObjectForKey:key];
  }
}

/// replaceKeysUsingKeyMap:
/// @param keyMap
- (void)replaceKeysUsingKeyMap:(NSDictionary *)keyMap {

  // Make sure all values are unique
  if ([[keyMap allValues] count] != [[[keyMap allValues] set] count])
    ThrowInvalidArgument(keyMap, "key map values are not all unique");

  else
    [keyMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      [self replaceKey:key withKey:obj];
    }];

}

/// exchangeKeyValueAtIndex:withKeyValueAtIndex:
/// @param index
/// @param otherIndex
- (void)exchangeKeyValueAtIndex:(NSUInteger)index withKeyValueAtIndex:(NSUInteger)otherIndex {
  if (index >= [self count]) ThrowInvalidIndexArgument(index);
  else if (otherIndex >= [self count]) ThrowInvalidIndexArgument(otherIndex);
  else {
    [self.keys exchangeObjectAtIndex:index withObjectAtIndex:otherIndex];
    [self.values exchangeObjectAtIndex:index withObjectAtIndex:otherIndex];
  }
}

/// indexForKey:
/// @param key
/// @return NSUInteger
- (NSUInteger)indexForKey:(id)key { return [_keys indexOfObject:key]; }

/// indexForValue:
/// @param value
/// @return NSUInteger
- (NSUInteger)indexForValue:(id)value { return [self indexOfObject:value]; }


/// insertObject:forKey:atIndex:
/// @param object
/// @param key
/// @param index
- (void)insertObject:(id)object forKey:(id<NSCopying>)key atIndex:(NSUInteger)index {
  if (!object) ThrowInvalidNilArgument(object);
  else if (!key) ThrowInvalidNilArgument(key);
  else if (index > [self count]) ThrowInvalidIndexArgument(index);
  else if (index == [self count]) self[key] = object;
  else {
    [_keys insertObject:key atIndex:index];
    [_values insertObject:object atIndex:index];
    [_dictionary setObject:object forKey:key];
  }
}

/// setUserInfo:
/// @param userInfo
- (void)setUserInfo:(MSDictionary *)userInfo {
  if (_isUserInfo) ThrowInvalidInternalInconsistency(cannot add userInfo to a userInfo dictionary);
  else {
    _userInfo = userInfo;

    if (_userInfo) _userInfo->_isUserInfo = YES;
  }
}

/// userInfo
/// @return MSDictionary *
- (MSDictionary *)userInfo {
  if (!_isUserInfo && !_userInfo) self.userInfo = [MSDictionary dictionary];

  return _userInfo;
}

/// keyForObject:
/// @param object
/// @return id
- (id)keyForObject:(id)object {
  NSUInteger index = [self indexOfObject:object];
  return (index == NSNotFound ? nil : _keys[index]);
}

/// indexOfObject:
/// @param object
/// @return NSUInteger
- (NSUInteger)indexOfObject:(id)object { return [_values indexOfObject:object]; }


////////////////////////////////////////////////////////////////////////////////
#pragma mark JSON export
////////////////////////////////////////////////////////////////////////////////

/// JSONDictionary
/// @return MSDictionary *
- (MSDictionary *)JSONDictionary { return self; }


////////////////////////////////////////////////////////////////////////////////
#pragma mark Superclass overrides
////////////////////////////////////////////////////////////////////////////////


/// count
/// @return NSUInteger
- (NSUInteger)count { return [self.dictionary count]; }

/// objectForKey:
/// @param aKey
/// @return id
- (id)objectForKey:(id)aKey { return [self.dictionary objectForKey:aKey]; }

/// classForCoder
/// @return Class
- (Class)classForCoder { return [self class]; }

MSSTATIC_KEY(MSDictionaryKeysStorage);
MSSTATIC_KEY(MSDictionaryValuesStorage);
MSSTATIC_KEY(MSDictionaryDictionaryStorage);
MSSTATIC_KEY(MSDictionaryStringKeysStorage);
MSSTATIC_KEY(MSDictionaryIsUserInfoStorage);
MSSTATIC_KEY(MSDictionaryUserInfoStorage);
MSSTATIC_KEY(MSDictionaryValidKeysStorage);

/// encodeWithCoder:
/// @param aCoder
- (void)encodeWithCoder:(NSCoder *)aCoder {
  if ([aCoder allowsKeyedCoding]) {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_keys forKey:MSDictionaryKeysStorageKey];
    [aCoder encodeObject:_values forKey:MSDictionaryValuesStorageKey];
    [aCoder encodeObject:_dictionary forKey:MSDictionaryDictionaryStorageKey];
    [aCoder encodeBool:_requiresStringKeys forKey:MSDictionaryStringKeysStorageKey];
    [aCoder encodeObject:_validKeys forKey:MSDictionaryValidKeysStorageKey];
    [aCoder encodeBool:_isUserInfo forKey:MSDictionaryIsUserInfoStorageKey];
    [aCoder encodeObject:_userInfo forKey:MSDictionaryUserInfoStorageKey];
  }
}

/// initWithCoder:
/// @param aDecoder
/// @return MSDictionary *
- (MSDictionary *)initWithCoder:(NSCoder *)aDecoder {
  if ((self = [super initWithCoder:aDecoder]) && [aDecoder allowsKeyedCoding]) {
    _keys               = [aDecoder decodeObjectForKey:MSDictionaryKeysStorageKey];
    _values             = [aDecoder decodeObjectForKey:MSDictionaryValuesStorageKey];
    _dictionary         = [aDecoder decodeObjectForKey:MSDictionaryDictionaryStorageKey];
    _requiresStringKeys = [aDecoder decodeBoolForKey:MSDictionaryStringKeysStorageKey];
    _validKeys          = [aDecoder decodeObjectForKey:MSDictionaryValidKeysStorageKey];
    _isUserInfo         = [aDecoder decodeBoolForKey:MSDictionaryIsUserInfoStorageKey];
    _userInfo           = [aDecoder decodeObjectForKey:MSDictionaryUserInfoStorageKey];
  }

  return self;
}

/// isEqualToDictionary:
/// @param otherDictionary
/// @return BOOL
- (BOOL)isEqualToDictionary:(MSDictionary *)otherDictionary {
  if (self == otherDictionary) return YES;
  else if (!isMSDictionary(otherDictionary)) return NO;
  else return (  [_keys isEqualToArray:otherDictionary->_keys]
               && [_values isEqualToArray:otherDictionary->_values]);
}

/// keyEnumerator
/// @return NSEnumerator *
- (NSEnumerator *)keyEnumerator { return [self.keys objectEnumerator]; }

/// allKeysForObject:
/// @param anObject
/// @return NSArray *
- (NSArray *)allKeysForObject:(id)anObject {
  BOOL (^test)(id, NSUInteger, BOOL *) = ^BOOL (id obj, NSUInteger idx, BOOL * stop) {
    return [obj isEqual:anObject];
  };

  NSIndexSet * indexes = [self.values indexesOfObjectsPassingTest:test];

  return (indexes.count ? [self.keys objectsAtIndexes:indexes] : nil);
}

/// allKeys
/// @return NSArray *
- (NSArray *)allKeys { return self.keys; }

/// allValues
/// @return NSArray *
- (NSArray *)allValues { return self.values; }

/// description
/// @return NSString *
- (NSString *)description {
  NSMutableArray * keyValuePairs = [@[] mutableCopy];

  for (int i = 0; i < [self count]; i++)
    [keyValuePairs addObject:$(@"'%@': '%@'", self.keys[i], self.values[i])];

  return $(@"<%@:%p> {\n\t%@\n};",
           ClassString([self class]),
           self,
           [keyValuePairs componentsJoinedByString:@",\n\t"]);
}

/// debugDescription
/// @return NSString *
- (NSString *)debugDescription { return [self description]; }

/// objectEnumerator
/// @return NSEnumerator *
- (NSEnumerator *)objectEnumerator { return [self.values objectEnumerator]; }

/// objectsForKeys:notFoundMarker:
/// @param keys
/// @param marker
/// @return NSArray *
- (NSArray *)objectsForKeys:(NSArray *)keys notFoundMarker:(id)marker {
  NSMutableArray * objects = [@[] mutableCopy];

  for (id key in keys) [objects addObject:(self[key] ?: marker)];

  return objects;
}

/// getObjects:andKeys:
/// @param objects
/// @param keys
- (void)getObjects:(id __unsafe_unretained [])objects andKeys:(id __unsafe_unretained [])keys {
  NSRange r = NSMakeRange(0, [self count]);

  if (objects) [self.values getObjects:objects range:r];

  if (keys) [self.keys getObjects:keys range:r];
}

/// initWithObjects:forKeys:count:
/// @param objects
/// @param keys
/// @param cnt
/// @return MSDictionary *
- (MSDictionary *)initWithObjects:(const id [])objects
                          forKeys:(const id<NSCopying> [])keys
                            count:(NSUInteger)cnt {
  if (self = [super initWithObjects:objects forKeys:keys count:cnt]) {
    self.dictionary = [[NSMutableDictionary alloc] initWithObjects:objects
                                                           forKeys:keys
                                                             count:cnt];
    self.keys   = [NSMutableArray arrayWithObjects:keys count:cnt];
    self.values = [NSMutableArray arrayWithObjects:objects count:cnt];
  }

  return self;
}

/// copyWithZone:
/// @param zone
/// @return id
- (id)copyWithZone:(NSZone *)zone {
  return [MSDictionary dictionaryWithObjects:self.values forKeys:self.keys];
}

/// mutableCopyWithZone:
/// @param zone
/// @return id
- (id)mutableCopyWithZone:(NSZone *)zone { return [self copyWithZone:zone]; }

/// countByEnumeratingWithState:objects:count:
/// @param state
/// @param buffer
/// @param len
/// @return NSUInteger
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
  return [self.keys countByEnumeratingWithState:state objects:buffer count:len];
}

/// dictionaryWithSharedKeySet:
/// @param keyset
/// @return instancetype
+ (instancetype)dictionaryWithSharedKeySet:(id)keyset {
  return [[self alloc] initWithSharedKeySet:keyset];
}

/// initWithSharedKeySet:
/// @param keyset
/// @return MSDictionary *
- (MSDictionary *)initWithSharedKeySet:(id)keyset {
  if (self = [super init]) {
    _validKeys = [[keyset allKeys] set];

    NSUInteger capacity = [keyset count];

    _keys       = [NSMutableArray arrayWithCapacity:capacity];
    _values     = [NSMutableArray arrayWithCapacity:capacity];
    _dictionary = [NSMutableDictionary dictionaryWithSharedKeySet:keyset];
  }

  return self;
}

/// initWithValues:forKeys:
/// @param values
/// @param keys
/// @return instancetype
- (instancetype)initWithValues:(NSArray *)values forKeys:(NSArray *)keys {
  if ((self = [super initWithObjects:values forKeys:keys])) {
    self.keys = [keys mutableCopy];
    self.values = [values mutableCopy];
  }
  return self;
}

/// removeObjectForKey:
/// @param aKey
- (void)removeObjectForKey:(id)aKey {
  if ([self.keys containsObject:aKey]) {
    NSUInteger index = [self.keys indexOfObject:aKey];
    [self.keys removeObjectAtIndex:index];
    [self.values removeObjectAtIndex:index];
    [self.dictionary removeObjectForKey:aKey];
  }
}

/// setObject:forKeyedSubscript:
/// @param obj
/// @param key
- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key { [self setObject:obj forKey:key]; }

/// setObject:forKey:
/// @param anObject
/// @param aKey
- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
  if ([self.keys containsObject:aKey]) {
    NSUInteger index = [_keys indexOfObject:aKey];

    [self willChange:NSKeyValueChangeReplacement
     valuesAtIndexes:NSIndexSetMake(index)
              forKey:@"allKeys"];

    [self.values replaceObjectAtIndex:index withObject:anObject];
    [self.dictionary setObject:anObject forKey:aKey];

    [self didChange:NSKeyValueChangeReplacement
    valuesAtIndexes:NSIndexSetMake(index)
             forKey:@"allKeys"];
  }   else {
    NSUInteger count = [_keys count];

    [self willChange:NSKeyValueChangeInsertion
     valuesAtIndexes:NSIndexSetMake(count++)
              forKey:@"allKeys"];

    [self.keys addObject:aKey];
    [self.values addObject:anObject];
    [self.dictionary setObject:anObject forKey:aKey];

    [self didChange:NSKeyValueChangeInsertion
    valuesAtIndexes:NSIndexSetMake(count)
             forKey:@"allKeys"];
  }
}

/// removeAllObjects
- (void)removeAllObjects {
  [self.dictionary removeAllObjects];
  [self.keys removeAllObjects];
  [self.values removeAllObjects];
}

/// removeObjectsForKeys:
/// @param keyArray
- (void)removeObjectsForKeys:(NSArray *)keyArray {
  BOOL (^test)(id, NSUInteger, BOOL *) = ^BOOL (id obj, NSUInteger idx, BOOL * stop) {
    return [keyArray containsObject:obj];
  };

  NSIndexSet * indexes = [_keys indexesOfObjectsPassingTest:test];

  [self.keys removeObjectsAtIndexes:indexes];
  [self.values removeObjectsAtIndexes:indexes];
  [self.dictionary removeObjectsForKeys:keyArray];
}

/// initWithCapacity:
/// @param numItems
/// @return MSDictionary *
- (MSDictionary *)initWithCapacity:(NSUInteger)numItems {
  if (self = [super init]) {
    self.keys       = [NSMutableArray arrayWithCapacity:numItems];
    self.values     = [NSMutableArray arrayWithCapacity:numItems];
    self.dictionary = [NSMutableDictionary dictionaryWithCapacity:numItems];
  }

  return self;
}


/// NSDictionaryValue
/// @return NSDictionary *
- (NSDictionary *)NSDictionaryValue { return self.dictionary; }
@end
