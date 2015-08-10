//
//  MSJSONSerialization.m
//  MSKit
//
//  Created by Jason Cardwell on 10/20/13.
//  Copyright (c) 2013 Jason Cardwell. All rights reserved.
//

#import "MSJSONSerialization.h"
#import "MSLogMacros.h"
@import CocoaLumberjack;
#import "MSStack.h"
#import "MSDictionary.h"
#import "NSArray+MSKitAdditions.h"
#import "NSDictionary+MSKitAdditions.h"
#import "NSString+MSKitAdditions.h"
#import "NSMutableString+MSKitAdditions.h"
#import "NSObject+MSKitAdditions.h"
#import "MSLog.h"
#import <MoonKit/MoonKit-Swift.h>

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

MSKEY_DEFINITION(MSJSONComment);
MSKEY_DEFINITION(MSJSONLeadingComment);
MSKEY_DEFINITION(MSJSONTrailingComment);


@implementation MSJSONSerialization

////////////////////////////////////////////////////////////////////////////////
#pragma mark Utilities
////////////////////////////////////////////////////////////////////////////////


/// Returns whether value inherits from NSString, NSNumber, NSDictionary, NSArray, or NSNull/// isValidJSONValue:
/// @param value
/// @return BOOL
+ (BOOL)isValidJSONValue:(id)value {
  return (  [value isKindOfClass:[NSString class]]
         || [value isKindOfClass:[NSArray class]]
         || [value isKindOfClass:[NSDictionary class]]
         || [value isKindOfClass:[NSNumber class]]
         || [value isKindOfClass:[NSNull class]]);
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Producing a string from JSON content
////////////////////////////////////////////////////////////////////////////////


/// Returns the json string representation of the specified object using default options.
/// @param object
/// @return NSString *
+ (NSString *)JSONFromObject:(id)object {
  return [self JSONFromObject:object options:MSJSONWriteFormatOptionsDefault];
}


/// Returns the json string representation of the specified object using specified options.
/// @param object
/// @param options
/// @return NSString *
+ (NSString *)JSONFromObject:(id)object options:(MSJSONWriteFormatOptions)options {

  NSString *(^__weak __block weakStringFromObject)(id, NSUInteger);
  NSString *(^__block stringFromObject)(id, NSUInteger);
  weakStringFromObject = stringFromObject = ^(id object, NSUInteger depth) {

    NSString        * indent = [NSString stringWithCharacter:' ' count:depth * 4];
    NSMutableString * string = [indent mutableCopy];

    if ([object isKindOfClass:[NSArray class]]) {

      [string appendString:@"["];
      NSArray * array = (NSArray *)object;

      NSString * comment = array.comment;

      if (comment) [string appendFormat:@" %@", comment];

      NSUInteger objectCount = [array count];

      for (NSUInteger i = 0; i < objectCount; i++) {

        NSString * valueString = weakStringFromObject(array[i], depth + 1);
        valueString = [valueString stringByTrimmingTrailingWhitespace];
        [string appendFormat:@"\n%@", valueString];

        if (i + 1 < objectCount) [string appendString:@","];

        comment = [array[i] comment];

        if (comment) [string appendString:comment];

      }

      if (objectCount) [string appendFormat:@"\n%@", indent];

      [string appendString:@"]"];

    }

    else if ([object isKindOfClass:[NSDictionary class]])   {

      [string appendString:@"{"];
      MSDictionary * comments = nil;

      if (isMSDictionary(object))
        comments = ((MSDictionary *)object).userInfo[MSJSONCommentKey];

      if ([comments hasKey:MSJSONLeadingCommentKey])
        [string appendFormat:@" /* %@ */", comments[MSJSONLeadingCommentKey]];

      else if ([object comment])
        [string appendString:[object comment]];

      NSDictionary * dictionary = (NSDictionary *)object;
      NSArray      * keys       = [dictionary allKeys];
      NSUInteger     keyCount   = [keys count];

      for (NSUInteger i = 0; i < keyCount; i++) {

        id         key         = keys[i];
        NSString * keyString   = weakStringFromObject(key, depth + 1);
        NSString * valueString = weakStringFromObject(dictionary[key], depth + 1);
        valueString = [valueString stringByTrimmingWhitespace];

        [string appendFormat:@"\n%@: %@", keyString, valueString];

        if (i + 1 < keyCount) [string appendString:@","];

        if ([comments hasKey:key]) [string appendFormat:@" /* %@ */", comments[key]];
        else if ([dictionary[key] comment]) [string appendString:[dictionary[key] comment]];

      }

      if (keyCount) [string appendFormat:@"\n%@", indent];

      [string appendString:@"}"];

      if ([comments hasKey:MSJSONTrailingCommentKey])
        [string appendFormat:@" /* %@ */", comments[MSJSONTrailingCommentKey]];

    }

    else if ([object isKindOfClass:[NSNumber class]])   {

      if (object == (void *)kCFBooleanFalse || object == (void *)kCFBooleanTrue)
        [string appendString:([object boolValue] ? @"true" : @"false")];

      // num is not boolean
      else [string appendString:[object stringValue]];

    }

    else if ([object isKindOfClass:[NSNull class]]) [string appendString:@"null"];

    else if ([object isKindOfClass:[NSString class]])
      [string appendFormat:@"\"%@\"", [object stringByEscapingControlCharacters]];

    return (NSString *)string;

  };

  return ([NSJSONSerialization isValidJSONObject:object]
          ? [stringFromObject(object, 0) stringByAppendingString:@"\n"]
          : nil);

}

/// Convenience method for parsing file with default options
/// @param filePath
/// @param error
/// @return NSString *
+ (NSString *)parseFile:(NSString *)filePath error:(NSError * __autoreleasing *)error {
  return [self parseFile:filePath options:MSJSONWriteFormatOptionsDefault error:error];
}

/// Convenience method for parsing string with default options
/// @param string
/// @param error
/// @return NSString *
+ (NSString *)parseString:(NSString *)string error:(NSError * __autoreleasing *)error {
  return [self parseString:string options:MSJSONWriteFormatOptionsDefault error:error];
}

/// Parses a file from and then back to json using the specified options and returns the resulting json string.
/// @param filePath
/// @param options
/// @param error
/// @return NSString *
+ (NSString *)parseFile:(NSString *)filePath
                options:(MSJSONWriteFormatOptions)options
                  error:(NSError * __autoreleasing *)error
{
  NSString * string = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:error];
  return (string ? [self parseString:string options:options error:error] : nil);
}

/// Parses a string from and then back into json using the specified options and returns the resulting json string.
/// @param string
/// @param options
/// @param error
/// @return NSString *
+ (NSString *)parseString:(NSString *)string
                  options:(MSJSONWriteFormatOptions)options
                    error:(NSError * __autoreleasing *)error
{
  id assembledObject = [self objectByParsingString:string error:error];
  return (assembledObject ? [self JSONFromObject:assembledObject options:options] : nil);
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Producing Objective-C objects from JSON content
////////////////////////////////////////////////////////////////////////////////


/// Convenience method for creating an object out the specified json string using the default options
/// @param string
/// @param error
/// @return id
+ (id)objectByParsingString:(NSString *)string error:(NSError * __autoreleasing *)error {
  return [self objectByParsingString:string options:MSJSONReadFormatOptionsDefault error:error];
}

/// Creates an object out the specified json string using the specified options.
/// @param string
/// @param options
/// @param error
/// @return id
+ (id)objectByParsingString:(NSString *)string
                    options:(MSJSONReadFormatOptions)options
                      error:(NSError * __autoreleasing *)error
{

  id object = nil;

  // We can only parse a string with actual text
  if (StringIsNotEmpty(string)) {

    // Create an actual object out of the json string making sure containers are mutable
    JSONParser * parser = [[JSONParser alloc] initWithString:string];
    object = [parser parseWithError:error];

    // Return now if we aren't meant to inflate keypaths
    if ((options & MSJSONReadFormatOptionInflateKeyPaths) != MSJSONReadFormatOptionInflateKeyPaths) return object;

    // Create a recursive block for visiting each object-containing object
    __block void (^visitContainingObjects)(id<MSObjectContaining>) = nil;
    __block void (^weakvisitContainingObjects)(id<MSObjectContaining>) = nil;

    visitContainingObjects = ^(id<MSObjectContaining> containing) {

      // Check if the containing object is an array
      if (isArrayKind(containing)) {

        NSMutableArray * array = (NSMutableArray *)containing;

        // Enumerate array converting any dictionaries we find
        for (NSUInteger i = 0; i < [array count]; i++)
          if (isDictionaryKind(array[i]))
            array[i] = [MSDictionary dictionaryWithDictionary:array[i] convertFoundationClasses:YES];
      }

      // Get any contained objects that also conform to `MSObjectContaining` protocol
      NSArray * contained = [containing topLevelObjectsConformingTo:@protocol(MSObjectContaining)];

      // Enumerate contained objects to visit each in turn
      [contained enumerateObjectsUsingBlock:^(id<MSObjectContaining> obj, NSUInteger idx, BOOL *stop) {
        weakvisitContainingObjects(obj);
      }];

    };

    // Update our weak block pointer so we don't have a `NULL` block, this must be done after creating the block body
    weakvisitContainingObjects = visitContainingObjects;

    // Check that our root object conforms to `MSObjectContaining` protocol, which it should assuming we have
    // an array or dictionary object
    if ([object conformsToProtocol:@protocol(MSObjectContaining)]) {

      // Check if our root object is a dictionary
      if (isDictionaryKind(object)) {
        // Convert and inflate the root dictionary object
        object = [MSDictionary dictionaryWithDictionary:object convertFoundationClasses:YES];
        [object inflate];
      }

      // Recursively visit objects contained by the root object that also conform to `MSObjectContaining` protocol
      visitContainingObjects(object);

      // With all dictionaries converted to `MSDictionary` objects, retrieve and inflate them
      [[object allObjectsOfKind:[MSDictionary class]] makeObjectsPerformSelector:@selector(inflate)];
    }

  }

  return object;

}

/// Convenience method for creating an object out the specified json file using the default options
/// @param filePath
/// @param error
/// @return id
+ (id)objectByParsingFile:(NSString *)filePath error:(NSError **)error {
  return [self objectByParsingFile:filePath options:MSJSONReadFormatOptionsDefault error:error];
}

/// Creates an object out the specified json file using the specified options.
/// @param filePath
/// @param options
/// @param error
/// @return id
+ (id)objectByParsingFile:(NSString *)filePath
                  options:(MSJSONReadFormatOptions)options
                    error:(NSError * __autoreleasing *)error
{
  NSString * string = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:error];
  return (string ? [self objectByParsingString:string options:options error:error] : nil);
}

@end
