//
// NSString+MSKitAdditions.h
// MSKit
//
// Created by Jason Cardwell on 5/2/11.
// Copyright 2011 Moondeer Studios. All rights reserved.
//

@import Foundation;
#import "MSKitLoggingFunctions.h"

// Convenience macros
#define NSStringFromBOOL(bool) (bool ? @"YES" : @"NO")
#define StringIsEmpty(s)       [NSString isEmptyString:s]
#define StringIsNotEmpty(s)    [NSString isNotEmptyString:s]
#define $(...)                 [NSString stringWithFormat:__VA_ARGS__]
#define UTF8(s)                [s UTF8String]
#define StripTrailingZeros(s)  [s stringByStrippingTrailingZeroes]

#define BOOLString(bool)                  NSStringFromBOOL(bool)
#define CGPointString(v)                  NSStringFromCGPoint(v)
#define CGSizeString(v)                   NSStringFromCGSize(v)
#define CGRectString(v)                   NSStringFromCGRect(v)
#define CGAffineTransformString(v)        NSStringFromCGAffineTransform(v)
#define UIEdgeInsetsString(v)             NSStringFromUIEdgeInsets(v)
#define UIOffsetString(v)                 NSStringFromUIOffset(v)
#define ClassString(v)                    NSStringFromClass(v)
#define SelectorString(v)                 NSStringFromSelector(v)
#define NSRangeString(v)                  NSStringFromRange(v)
#define MSBoundaryString(v)               NSStringFromMSBoundary(v)
#define CATransform3DString(v)            NSStringFromCATransform3D(v)
#define CATransform3DTString(v)           NSStringFromCATransform3DT(v)
#define NSAttributeTypeString(v)          NSStringFromNSAttributeType(v)
#define NSDeleteRuleString(v)             NSStringFromNSDeleteRule(v)
#define CGImageAlphaInfoString(v)         NSStringFromCGImageAlphaInfo(v)
#define CGBitmapInfoByteOrderString(v)    NSStringFromCGBitmapInfoByteOrder(v)
#define CGColorRenderingIntentString(v)   NSStringFromCGColorRenderingIntent(v)
#define ImageInfoString(v)                NSStringFromImageInfo(v)
#define UIControlStateString(v)           NSStringFromUIControlState(v)
#define UIGestureRecognizerStateString(v) NSStringFromUIGestureRecognizerState(v)
#define CGColorSpaceModelString(v)        NSStringFromCGColorSpaceModel(v)
#define vImage_ErrorString(v)             NSStringFromvImage_Error(v)


@interface NSString (MSKitAdditions)

/// Convenience for creating string using `NSUTF8StringEncoding`
+ (instancetype)stringWithData:(NSData *)data;

/// Casting convenience for `unsigned int` string values
- (unsigned int)uintValue;

/// Returns a range value with the full length of the string.
@property (nonatomic, readonly) NSRange fullRange;

/// Casting convenience for `NSUInteger` string values
- (NSUInteger)unsignedIntegerValue;

/// Returns the character at the specified index wrapped by boxed expression
- (NSNumber *)objectAtIndexedSubscript:(NSUInteger)idx;

/// Replaces occurences of dictionary key with dictionary value
- (NSString *)stringByReplacingOccurrencesWithDictionary:(NSDictionary *)replacements;

/// String containing the specified number of the specified character
+ (instancetype)stringWithCharacter:(unichar)character count:(NSUInteger)count;

/// String containing the specified number of the specified string
+ (instancetype)stringWithString:(NSString *)string count:(NSUInteger)count;

/// Returns `YES` if the string has zero length or is null or is the null object
+ (BOOL)isEmptyString:(NSString *)string;

/// Returns `YES` if the string has length greater than zero
+ (BOOL)isNotEmptyString:(NSString *)string;

/// Convenience for writing to file using `NSUTF8StringEncoding` and logging error if encountered
- (BOOL)writeToFile:(NSString *)filePath;

@end

@interface NSString (MSKitTransformingAdditions)

/// Convert this-string to thisString
- (NSString *)dashCaseToCamelCase;

/// Convert thisString to this-string
- (NSString *)camelCaseToDashCase;

/// Right shifts all lines by the specified amount using leading spaces
- (NSString *)stringByShiftingRight:(NSUInteger)shiftAmount;

/// Right shifts all lines by the specified amount with the option to leave first line unshifted
- (NSString *)stringByShiftingRight:(NSUInteger)shiftAmount shiftFirstLine:(BOOL)shiftFirstLine;

/// Left shifts all lines by the specified amount removing leading spaces
- (NSString *)stringByShiftingLeft:(NSUInteger)shiftAmount;

/// Left shifts all lines by the specified amount with the option to leave first line unshifted
- (NSString *)stringByShiftingLeft:(NSUInteger)shiftAmount shiftFirstLine:(BOOL)shiftFirstLine;

/// String by right padding to specified length with specified character
- (NSString *)stringByRightPaddingToLength:(NSUInteger)length withCharacter:(unichar)character;

/// String by left padding to specified length with specified character
- (NSString *)stringByLeftPaddingToLength:(NSUInteger)length withCharacter:(unichar)character;

/// Turn the string into a camelCase string
- (NSString *)camelCase;

/// Introduces newline characters to produce wrapped text
- (NSString *)stringByWrappingLinesAtColumn:(NSUInteger)column;

@end

@interface NSString (MSKitComponentsAdditions)

/// Convenience for `[NSArray componentsJoinedByString:]`
- (NSString *)join:(NSArray *)array;

/// Convenience for `[NSString componentsSeparatedByString:]`
- (NSArray *)split:(NSString *)string;

/// Divide the string in two near the middle
- (NSArray *)componentsSplitNearCenterOfString;

/// Divide the string into segements no longer than the specified width
- (NSArray *)componentsSplitWithMaxCharactersPerLine:(NSUInteger)charactersPerLine;

/// Splits string on '.'
- (NSArray *)keyPathComponents;

@end

@interface NSString (MSKitStrippingAdditions)

/// Remove leading whitespace and line breaks
- (NSString *)stringByTrimmingLeadingWhitespace;

/// Remove trailing whitespace and line breaks
- (NSString *)stringByTrimmingTrailingWhitespace;

/// Remove leading and trailing whitespace and line breaks
- (NSString *)stringByTrimmingWhitespace;

/// Remove trailing '0's
- (NSString *)stringByStrippingTrailingZeroes;

/// Remove the specified character
- (NSString *)stringByRemovingCharacter:(unichar)character;

/// Remove characters from the specified set of characters
- (NSString *)stringByRemovingCharactersFromSet:(NSCharacterSet *)characterSet;

/// Remove line break characters
- (NSString *)stringByRemovingLineBreaks;

/// Removes matching substrings for C style single line comments, '//…⏎'
- (NSString *)stringByStrippingSingleLineComments;

/// Removes matching substrings for C style multiline comments, '/*…*/'
- (NSString *)stringByStrippingMultiLineComments;


@end

@interface NSString (MSKitEscapingAdditions)

- (NSString *)quotedString;

/// Replace '\\n' and '\\r' with ⏎
- (NSString *)stringByReplacingReturnsWithSymbol;

/// Replace ⏎ with '\\n'
- (NSString *)stringByReplacingReturnSymbolsWithNewline;

/// Escape new line characters
- (NSString *)stringByEscapingNewlines;

/// Escape control characters
- (NSString *)stringByEscapingControlCharacters;

/// Unescape control characters
- (NSString *)stringByUnescapingControlCharacters;

@end

@interface NSString (MSKitRegularExpressionAdditions)

/// Returns the range of the specified capture in the first match for the regular expression provided.
- (NSRange)rangeOfCapture:(NSUInteger)capture forRegEx:(NSString *)regex;

/// Returns the range of the specified capture in the specified match for the regular expression provided.
- (NSRange)rangeOfCapture:(NSUInteger)capture inMatch:(NSUInteger)match forRegEx:(NSString *)regex;

/// Returns the range for the first match for the regular expression provided.
- (NSRange)rangeOfRegEx:(NSString *)regex;

/// Returns the range for the specified match for the regular expression provided.
- (NSRange)rangeOfMatch:(NSUInteger)match forRegEx:(NSString *)regex;

/// Returns an array containing the ranges of any matches for the regular expression provided.
- (NSArray *)rangesOfMatchesForRegEx:(NSString *)regex;

/// Returns the string formed by the range of the first match for the regular expression provided.
- (NSString *)stringByMatchingFirstOccurrenceOfRegEx:(NSString *)regex;

/// Returns the string formed by the range of the specified capture in the first match for the expression provided.
- (NSString *)stringByMatchingFirstOccurrenceOfRegEx:(NSString *)regex capture:(NSUInteger)capture;

/// Returns the string formed by the range of the specified capture in the specified match for the expression provided.
- (NSString *)stringByMatchingRegEx:(NSString *)regex match:(NSUInteger)match capture:(NSUInteger)capture;

/// Returns the string created by replacing occurences of the specified regular expression with the given string.
/// Replacement strings can include captures using $*capture*. i.e. @"$1". Alternatively, text can be provided to
/// replace a particular capture with $*capture*=*text*=. i.e. @"$1 $2=%0A="
- (NSString *)stringByReplacingRegEx:(NSString *)regex withString:(NSString *)string;

/// Returns an array of substrings created by splitting the string on matches for the regular expression provided.
- (NSArray *)componentsSeparatedByRegEx:(NSString *)regex;

/// Returns the array of `NSTextCheckingResults` obtained by matching the regular expression provided.
- (NSArray *)matchesForRegEx:(NSString *)regex;

/// Returns an array of the substrings formed by matching the string against the regular expression provided.
- (NSArray *)matchingSubstringsForRegEx:(NSString *)regex;

/// Returns a dictionary of the captured strings in the first match for the regular expression provided using specified
/// array as keys for the dictionary entries, or `NSNumber` objects if keys are not provided.
- (NSDictionary *)dictionaryOfCapturedStringsByMatchingFirstOccurrenceOfRegex:(NSString *)regex keys:(NSArray *)keys;

/// Returns a dictionary of the captured strings in the first match for the regular expression provided using specified
/// array as keys for the dictionary entries, or `NSNumber` objects if keys are not provided and the specified options.
- (NSDictionary *)dictionaryOfCapturedStringsByMatchingFirstOccurrenceOfRegex:(NSString *)regex
                                                                         keys:(NSArray *)keys
                                                                      options:(NSRegularExpressionOptions)options;

/// Returns an array of the substrings captured in the first match for the regular expression provided.
- (NSArray *)capturedStringsByMatchingFirstOccurrenceOfRegex:(NSString *)regex;

/// Array of the substrings captured in the first match for the expression provided using the specified options.
- (NSArray *)capturedStringsByMatchingFirstOccurrenceOfRegex:(NSString *)regex
                                                     options:(NSRegularExpressionOptions)opts;

/// Returns the number of matches for the regular expression provided.
- (NSUInteger)numberOfMatchesForRegEx:(NSString *)regex;

/// Returns the number of matches for the regular expression provided using the specified options.
- (NSUInteger)numberOfMatchesForRegEx:(NSString *)regex options:(NSRegularExpressionOptions)opts;

/// Returns whether a match is found for the regular expression provided.
- (BOOL)hasSubstring:(NSString *)substring;

/// Returns whether a match is found for the regular expression provided using the specified options.
- (BOOL)hasSubstring:(NSString *)substring options:(NSRegularExpressionOptions)options;

@end

