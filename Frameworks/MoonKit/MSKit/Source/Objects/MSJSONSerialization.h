//
//  MSJSONSerialization.h
//  MSKit
//
//  Created by Jason Cardwell on 10/20/13.
//  Copyright (c) 2013 Jason Cardwell. All rights reserved.
//
@import Foundation;
@import UIKit;
#import "MSKitDefines.h"
#import "MSKitProtocols.h"
#import "MSKitMacros.h"

typedef NS_OPTIONS(NSUInteger, MSJSONReadFormatOptions) {

  /// Just parse
  MSJSONReadFormatOptionsDefault = 0,

  /// Inflate "keypath" keys, i.e. "key.path.type.key" : value → "key": { "path": { "type": { "key": value } } }
  MSJSONReadFormatOptionInflateKeyPaths = 1

};

typedef NS_OPTIONS(NSUInteger, MSJSONWriteFormatOptions) {
    /// default is to strip all whitespace and comments, and convert "keypath" keys
    MSJSONWriteFormatOptionsDefault = 0b0,

    /// don't remove or add any line breaks
    MSJSONWriteFormatOptionsPreserveWhitespace = 0b1,

    /// create "keypath" keys for single entry objects
    MSJSONWriteFormatOptionsCreateKeyPaths = 0b10,

    /// don't remove comments
    MSJSONWriteFormatOptionsKeepComments = 0b100,

    /// indent by nested depth
    MSJSONWriteFormatOptionsIndentByDepth = 0b1000,

    /// keep one line arrays/objects
    MSJSONWriteFormatOptionsKeepOneLiners = 0b10000,

    /// create one line arrays/objects for single entry/element
    MSJSONWriteFormatOptionsForceOneLiners = 0b110000,

    /// options affecting line breaks around array brackets
    MSJSONWriteFormatOptionsLineBreakAfterOpenBracket        = 0b01000000,
    MSJSONWriteFormatOptionsLineBreakBeforeCloseBracket      = 0b10000000,
    MSJSONWriteFormatOptionsLineBreaksInsideBrackets         = 0b11000000,

    /// options affecting line breaks around object braces
    MSJSONWriteFormatOptionsLineBreakAfterOpenBrace          = 0b0100000000,
    MSJSONWriteFormatOptionsLineBreakBeforeCloseBrace        = 0b1000000000,
    MSJSONWriteFormatOptionsLineBreaksInsideBraces           = 0b1100000000,

    /// between elements/key-value pairs
    MSJSONWriteFormatOptionsLineBreakAfterComma              = 0b0010000000000,
    MSJSONWriteFormatOptionsLineBreakBetweenColonAndArray    = 0b0100000000000,
    MSJSONWriteFormatOptionsLineBreakBetweenColonAndObject   = 0b1000000000000

};

@interface MSJSONSerialization : NSObject

/// Returns whether value inherits from NSString, NSNumber, NSDictionary, NSArray, or NSNull
+ (BOOL)isValidJSONValue:(id)value;

/// Returns the json string representation of the specified object using default options.
+ (NSString *)JSONFromObject:(id)object;

/// Returns the json string representation of the specified object using specified options.
+ (NSString *)JSONFromObject:(id)object options:(MSJSONWriteFormatOptions)options;

/// Convenience method for parsing string with default options
+ (NSString *)parseString:(NSString *)string error:(NSError *__autoreleasing *)error;

/// Convenience method for parsing file with default options
+ (NSString *)parseFile:(NSString *)filePath error:(NSError *__autoreleasing *)error;

/// Parses a string from and then back into json using the specified options and returns the resulting json string.
+ (NSString *)parseString:(NSString *)string
                  options:(MSJSONWriteFormatOptions)options
                    error:(NSError *__autoreleasing *)error;

/// Parses a file from and then back to json using the specified options and returns the resulting json string.
+ (NSString *)parseFile:(NSString *)filePath
                options:(MSJSONWriteFormatOptions)options
                  error:(NSError *__autoreleasing *)error;

/// Convenience method for creating an object out the specified json string using the default options
+ (id)objectByParsingString:(NSString *)string error:(NSError *__autoreleasing *)error;

/// Convenience method for creating an object out the specified json file using the default options
+ (id)objectByParsingFile:(NSString *)filePath error:(NSError *__autoreleasing *)error;

/// Creates an object out the specified json string using the specified options.
+ (id)objectByParsingString:(NSString *)string
                    options:(MSJSONReadFormatOptions)options
                      error:(NSError *__autoreleasing *)error;

/// Creates an object out the specified json file using the specified options.
+ (id)objectByParsingFile:(NSString *)filePath
                  options:(MSJSONReadFormatOptions)options
                    error:(NSError *__autoreleasing *)error;

@end

MSEXTERN_KEY(MSJSONComment);
MSEXTERN_KEY(MSJSONLeadingComment);
MSEXTERN_KEY(MSJSONTrailingComment);

#import "MSDictionary.h"

MSSTATIC_INLINE NSString * NSStringFromMSJSONWriteFormatOptions(MSJSONWriteFormatOptions o)
{
    MSDictionary * d = [MSDictionary dictionary];

    d[@"preserveWhitespace"]             = BOOLString((o & MSJSONWriteFormatOptionsPreserveWhitespace));
    d[@"createKeyPaths"]                 = BOOLString((o & MSJSONWriteFormatOptionsCreateKeyPaths));
    d[@"keepComments"]                   = BOOLString((o & MSJSONWriteFormatOptionsKeepComments));
    d[@"indentByDepth"]                  = BOOLString((o & MSJSONWriteFormatOptionsIndentByDepth));
    d[@"keepOneLiners"]                  = BOOLString((o & MSJSONWriteFormatOptionsKeepOneLiners));
    d[@"forceOneLiners"]                 = BOOLString((o & MSJSONWriteFormatOptionsForceOneLiners));
    d[@"lineBreakAfterOpenBracket"]      = BOOLString((o & MSJSONWriteFormatOptionsLineBreakAfterOpenBracket));
    d[@"lineBreakBeforeCloseBracket"]    = BOOLString((o & MSJSONWriteFormatOptionsLineBreakBeforeCloseBracket));
    d[@"lineBreakAfterOpenBrace"]        = BOOLString((o & MSJSONWriteFormatOptionsLineBreakAfterOpenBrace));
    d[@"lineBreakBeforeCloseBrace"]      = BOOLString((o & MSJSONWriteFormatOptionsLineBreakBeforeCloseBrace));
    d[@"lineBreakAfterComma"]            = BOOLString((o & MSJSONWriteFormatOptionsLineBreakAfterComma));
    d[@"lineBreakBetweenColonAndArray"]  = BOOLString((o & MSJSONWriteFormatOptionsLineBreakBetweenColonAndArray));
    d[@"lineBreakBetweenColonAndObject"] = BOOLString((o & MSJSONWriteFormatOptionsLineBreakBetweenColonAndObject));


    return [d formattedDescriptionWithOptions:0 levelIndent:0];
}
