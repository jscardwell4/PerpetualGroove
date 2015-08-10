//
// NSString+MSKitAdditions.m
// MSKit
//
// Created by Jason Cardwell on 5/2/11.
// Copyright 2011 Moondeer Studios. All rights reserved.
//
#import "MSKitMacros.h"
#import "MSKitLoggingFunctions.h"
#import "NSString+MSKitAdditions.h"
#import "NSNull+MSKitAdditions.h"
#import "NSArray+MSKitAdditions.h"
#import "NSObject+MSKitAdditions.h"
#import "MSLog.h"
#import "NSMutableString+MSKitAdditions.h"
@import CoreText;
#import "NSValue+MSKitAdditions.h"

static int ddLogLevel   = LOG_LEVEL_WARN;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

@implementation NSString (MSKitAdditions)

/// unsignedIntegerValue
/// @return NSUInteger
- (NSUInteger)unsignedIntegerValue { return (NSUInteger)[self integerValue]; }

/// uintValue
/// @return unsigned int
- (unsigned int)uintValue { return (unsigned int)[self intValue]; }

/// Returns a range value with the full length of the string.
- (NSRange)fullRange { return NSMakeRange(0, self.length); }

/// stringWithData:
/// @param data
/// @return NSString *
+ (instancetype)stringWithData:(NSData *)data {
  return (data ? [[self alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil);
}

/// objectAtIndexedSubscript:
/// @param idx
/// @return NSNumber *
- (NSNumber *)objectAtIndexedSubscript:(NSUInteger)idx {
  if (idx >= self.length) [[NSException exceptionWithName:NSRangeException
                                                   reason:@"index out of range" userInfo:nil] raise];

  return @([self characterAtIndex:idx]);
}

/// Replaces occurences of dictionary key with dictionary value
/// @param replacements
/// @return NSString *
- (NSString *)stringByReplacingOccurrencesWithDictionary:(NSDictionary *)replacements {
  NSMutableString * newString = [self mutableCopy];
  [newString replaceOccurrencesOfStringsWithDictionary:replacements];
  return newString;
}

/// String containing the specified number of the specified character
/// @param character
/// @param count
/// @return NSString *
+ (instancetype)stringWithCharacter:(unichar)character count:(NSUInteger)count {
  return [[self alloc] initWithString:[NSMutableString stringWithCharacter:character count:count]];
}

/// String containing the specified number of the specified string
/// @param string
/// @param count
/// @return NSString *
+ (instancetype)stringWithString:(NSString *)string count:(NSUInteger)count {
  return [[self alloc] initWithString:[NSMutableString stringWithString:string count:count]];
}

/// Returns `YES` if the string has zero length or is null or is the null object
/// @param string
/// @return BOOL
+ (BOOL)isEmptyString:(NSString *)string {
  return [NSNull valueIsNil:string] || string.length == 0;
}

/// Returns `YES` if the string has length greater than zero
/// @param string
/// @return BOOL
+ (BOOL)isNotEmptyString:(NSString *)string {
  return ![self isEmptyString:string];
}

/// Convenience for writing to file using `NSUTF8StringEncoding` and logging error if encountered
/// @param filePath
/// @return BOOL
- (BOOL)writeToFile:(NSString *)filePath {
  NSError * error;

  [self writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
  MSHandleErrors(error);

  return (!error);
}

@end

@implementation NSString (MSKitTransformingAdditions)

/// Convert this-string to thisString
/// @return NSString *
- (NSString *)dashCaseToCamelCase {
  NSArray         * components = [self componentsSeparatedByString:@"-"];
  NSMutableString * camel      = nil;

  for (NSString * component in components) {
    if (!camel) camel = [component mutableCopy];
    else [camel appendString:[component capitalizedString]];
  }

  return camel;
}

/// Convert thisString to this-string
/// @return NSString *
- (NSString *)camelCaseToDashCase {
  NSMutableString * string = [@"" mutableCopy];

  for (int i = 0; i < [self length]; i++) {
    unichar character = [self characterAtIndex:i];

    if (character >= 'A' && character <= 'Z')
      [string appendString:@"-"];

    [string appendFormat:@"%C", character];
  }

  return [string lowercaseString];
}

/// Right shifts all lines by the specified amount using leading spaces
/// @param shiftAmount
/// @return NSString *
- (NSString *)stringByShiftingRight:(NSUInteger)shiftAmount {
  return [self stringByShiftingRight:shiftAmount shiftFirstLine:YES];
}

/// Right shifts all lines by the specified amount with the option to leave first line unshifted
/// @param shiftAmount
/// @param shiftFirstLine
/// @return NSString *
- (NSString *)stringByShiftingRight:(NSUInteger)shiftAmount shiftFirstLine:(BOOL)shiftFirstLine {
  NSString * padding = [NSString stringWithCharacter:' ' count:shiftAmount];

  return (shiftFirstLine
          ? [padding stringByAppendingString:
             [self stringByReplacingOccurrencesOfString:@"\n" withString:$(@"\n%@", padding)]]
          : [self stringByReplacingOccurrencesOfString:@"\n" withString:$(@"\n%@", padding)]);
}

/// Left shifts all lines by the specified amount removing leading spaces
/// @param shiftAmount
/// @return NSString *
- (NSString *)stringByShiftingLeft:(NSUInteger)shiftAmount {
  return [self stringByShiftingLeft:shiftAmount shiftFirstLine:YES];
}

/// Left shifts all lines by the specified amount with the option to leave first line unshifted
/// @param shiftAmount
/// @param shiftFirstLine
/// @return NSString *
- (NSString *)stringByShiftingLeft:(NSUInteger)shiftAmount shiftFirstLine:(BOOL)shiftFirstLine {
  NSMutableString * shiftedString = [self mutableCopy];

  [shiftedString replaceRegEx:$(@"\n {%lu}", (unsigned long)shiftAmount)
                   withString:@"\n"];

  if (shiftFirstLine)
    [shiftedString replaceRegEx:$(@"^ {%lu}", (unsigned long)shiftAmount)
                     withString:@""];

  return shiftedString;
}

/// String by right padding to specified length with specified character
/// @param length
/// @param character
/// @return NSString *
- (NSString *)stringByRightPaddingToLength:(NSUInteger)length withCharacter:(unichar)character {
  if (self.length >= length) return self;
  else return $(@"%@%@", self, [NSString stringWithCharacter:character count:length - self.length]);
}

/// String by left padding to specified length with specified character
/// @param length
/// @param character
/// @return NSString *
- (NSString *)stringByLeftPaddingToLength:(NSUInteger)length withCharacter:(unichar)character {
  if (self.length >= length) return self;
  else return $(@"%@%@", [NSString stringWithCharacter:character count:length - self.length], self);
}

/// Turn the string into a camelCase string
/// @return NSString *
- (NSString *)camelCase {

  if (!self.length) return self;

  NSMutableString * string = [@"" mutableCopy];

  [self enumerateSubstringsInRange:NSMakeRange(0, self.length)
                           options:NSStringEnumerationByWords
                        usingBlock:^(NSString * substring, NSRange substringRange, NSRange enclosingRange, BOOL * stop)
  {
    NSMutableString * s = [substring mutableCopy];
    s[0] = @(toupper([s[0] charValue]));
    [string appendString:s];
  }];

  string[0] = @(tolower([string[0] charValue]));

  return string;
}

/// stringByWrappingLinesAtColumn:
/// @param column
/// @return NSString *
- (NSString *)stringByWrappingLinesAtColumn:(NSUInteger)column {
  NSMutableString * string = [self mutableCopy];
  [string wrapLinesAtColumn:column];
  return string;
}

@end

@implementation NSString (MSKitComponentsAdditions)

/// Convenience for `[NSArray componentsJoinedByString:]`
/// @param array
/// @return NSString *
- (NSString *)join:(NSArray *)array {
  return [array componentsJoinedByString:self];
}

/// Convenience for `[NSString componentsSeparatedByString:]`
/// @param string
/// @return NSArray *
- (NSArray *)split:(NSString *)string { return [string componentsSeparatedByString:self]; }

/// Divide the string in two near the middle
/// @return NSArray *
- (NSArray *)componentsSplitNearCenterOfString {
  NSArray * components = nil;
  NSInteger length     = [self length];

  if (length <= 0) return nil;

  NSInteger midPoint = length / 2;

  __block NSInteger splitPoint = 0;

  [self enumerateSubstringsInRange:NSMakeRange(0, length)
                           options:NSStringEnumerationByWords
                        usingBlock:^(NSString * substring, NSRange substringRange, NSRange enclosingRange, BOOL * stop) {
                          if (substringRange.location <= midPoint) splitPoint = substringRange.location;
                          else if (substringRange.location > midPoint && substringRange.location < length) {
                            if (splitPoint == 0 || substringRange.location - midPoint < midPoint - splitPoint)
                              splitPoint = substringRange.location;

                            *stop = YES;
                          }
                        }

  ];
  components = @[[[self substringToIndex:splitPoint] stringByTrimmingWhitespace], [[self substringFromIndex:splitPoint] stringByTrimmingWhitespace]];

//    // NSLog(@"splitPoint = %i, components = %@",splitPoint,components);
  return components;
}

/// Divide the string into segements no longer than the specified width
/// @param charactersPerLine
/// @return NSArray *
- (NSArray *)componentsSplitWithMaxCharactersPerLine:(NSUInteger)charactersPerLine {
  NSInteger length = [self length];

  if (length <= 0) return nil;

  else if (length < charactersPerLine)
    return @[self];
  else {
    NSMutableArray * components = [@[] mutableCopy];

    [self enumerateSubstringsInRange:NSMakeRange(0, self.length)
                             options:NSStringEnumerationByLines
                          usingBlock:^(NSString * line, NSRange lineRange, NSRange enclosingRange, BOOL * stop) {
                            if (line.length < charactersPerLine)
                              [components addObject:[line copy]];
                            else {
                              NSMutableString * currentLine = [NSMutableString stringWithCapacity:charactersPerLine];
                              [line enumerateSubstringsInRange:NSMakeRange(0, line.length)
                                                       options:NSStringEnumerationByWords
                                                    usingBlock:^(NSString * word, NSRange wordRange, NSRange enclosingRange, BOOL * stop) {
                                 if (currentLine.length + word.length + 1 < charactersPerLine)
                                   [currentLine appendFormat:@" %@", word];
                                 else {
                                   [components addObject:[currentLine copy]];
                                   [currentLine setString:word];
                                 }
                               }

                              ];
                              [components addObject:[currentLine copy]];
                            }
                          }

    ];

    return components;
  }
}

/// Splits string on '.'
/// @return NSArray *
- (NSArray *)keyPathComponents { return [self componentsSeparatedByString:@"."]; }

@end

@implementation NSString (MSKitStrippingAdditions)

/// Remove leading whitespace and line breaks
/// @return NSString *
- (NSString *)stringByTrimmingLeadingWhitespace {
  NSInteger i = 0;
  while ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[self characterAtIndex:i]]) i++;
  return [self substringFromIndex:i];
}

/// Remove trailing whitespace and line breaks
/// @return NSString *
- (NSString *)stringByTrimmingTrailingWhitespace {
  NSInteger i = [self length] - 1;
  while ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[self characterAtIndex:i]]) i--;
  return [self substringToIndex:i + 1];
}

/// Remove leading and trailing whitespace and line breaks
/// @return NSString *
- (NSString *)stringByTrimmingWhitespace {
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/// Remove trailing '0's
/// @return NSString *
- (NSString *)stringByStrippingTrailingZeroes {
  return [self stringByReplacingRegEx:@"(?:([0-9]+\\.[0-9]*[1-9])0+)|(?:([0-9]+)\\.0+)" withString:@"$1$2"];
}

/// Remove the specified character
/// @param character
/// @return NSString *
- (NSString *)stringByRemovingCharacter:(unichar)character {
  return [self stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%c", character]
                                         withString:@""];
}

/// Remove characters from the specified set of characters
/// @param characterSet
/// @return NSString *
- (NSString *)stringByRemovingCharactersFromSet:(NSCharacterSet *)characterSet {
  return [[self componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:@""];
}

/// Remove line break characters
/// @return NSString *
- (NSString *)stringByRemovingLineBreaks {
  return [self stringByRemovingCharactersFromSet:NSNewlineCharacters];
}

/// Removes matching substrings for C style single line comments, '//…⏎'
- (NSString *)stringByStrippingSingleLineComments {
  NSMutableString * string = [self mutableCopy];
  [string stripSingleLineComments];
  return string;
}

/// Removes matching substrings for C style multiline comments, '/*…*/'
- (NSString *)stringByStrippingMultiLineComments {
  NSMutableString * string = [self mutableCopy];
  [string stripMultiLineComments];
  return string;
}

@end

@implementation NSString (MSKitEscapingAdditions)

/// quotedString
/// @return NSString *
- (NSString *)quotedString { return [NSString stringWithFormat:@"\"%@\"", self]; }

/// Replace '\\n' and '\\r'  with ⏎
/// @return NSString *
- (NSString *)stringByReplacingReturnsWithSymbol {
  return [self stringByReplacingRegEx:@"[\n\r]" withString:@"⏎"];    // \u23CE
}

/// Replace ⏎ with '\\n'
/// @return NSString *
- (NSString *)stringByReplacingReturnSymbolsWithNewline {
  return [self stringByReplacingOccurrencesOfString:@"⏎" withString:@"\n"];    // \u23CE
}

/// Escape new line characters
/// @return NSString *
- (NSString *)stringByEscapingNewlines {
  unichar    newLineCharacters[] = { 0x000A, 0x000B, 0x000C, 0x000D, 0x0085 };
  NSString * escapedString       = [self copy];

  for (int i = 0; i < 5; i++) {
    escapedString = [escapedString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%C", newLineCharacters[i]] withString:@"\\n"];
  }

  return escapedString;
}

/// Escape control characters
/// @return NSString *
- (NSString *)stringByEscapingControlCharacters {
  unichar    newLineCharacters[] = { 0x000A, 0x000B, 0x000C, 0x000D, 0x0085 };
  NSString * escapedString       = [self copy];

  for (int i = 0; i < 5; i++) {
    escapedString = [escapedString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%C", newLineCharacters[i]] withString:@"\\n"];
  }

  escapedString = [escapedString stringByReplacingOccurrencesOfString:@"  "withString:@"\\t"];

  return escapedString;
}

/// Unescape control characters
/// @return NSString *
- (NSString *)stringByUnescapingControlCharacters {
  return [[[self stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
           stringByReplacingRegEx:@"%5C(?:(%[0-9A-F]{2})|(n))" withString:@"$1$2=%0A="]
          stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end

@implementation NSString (MSKitRegularExpressionAdditions)

/// Returns the range of the specified capture in the first match for the regular expression provided.
/// @param capture
/// @param regex
/// @return NSRange
- (NSRange)rangeOfCapture:(NSUInteger)capture forRegEx:(NSString *)regex {
  return [self rangeOfCapture:capture inMatch:0 forRegEx:regex];
}

/// Returns the range of the specified capture in the specified match for the regular expression provided.
/// @param capture
/// @param match
/// @param regex
/// @return NSRange
- (NSRange)rangeOfCapture:(NSUInteger)capture inMatch:(NSUInteger)match forRegEx:(NSString *)regex {
  NSError             * error;
  NSRegularExpression * re = [NSRegularExpression
                              regularExpressionWithPattern:regex
                                                   options:NSRegularExpressionAnchorsMatchLines
                                                     error:&error];

  if (MSHandleErrors(error)) return NSNotFoundRange;

  NSArray * matches = [re matchesInString:self options:0 range:NSMakeRange(0, [self length])];

  return ([matches count] > match && [matches[match] numberOfRanges] > capture
          ? [matches[match] rangeAtIndex:capture]
          : NSNotFoundRange);
}


/// Returns the range for the first match for the regular expression provided.
- (NSRange)rangeOfRegEx:(NSString *)regex { return [self rangeOfMatch:0 forRegEx:regex]; }

/// Returns the range for the specified match for the regular expression provided.
/// @param match
/// @param regex
/// @return NSRange
- (NSRange)rangeOfMatch:(NSUInteger)match forRegEx:(NSString *)regex {
  return [self rangeOfCapture:0 inMatch:match forRegEx:regex];
}

/// Returns an array containing the ranges of any matches for the regular expression provided.
/// @param regex
/// @return NSArray *
- (NSArray *)rangesOfMatchesForRegEx:(NSString *)regex {
  NSError             * error;
  NSRegularExpression * re = [NSRegularExpression
                              regularExpressionWithPattern:regex
                                                   options:NSRegularExpressionAnchorsMatchLines
                                                     error:&error];
  return (MSHandleErrors(error)
          ? nil
          : [[re matchesInString:self options:0 range:self.fullRange] valueForKeyPath:@"range"]);
}

/// Returns the string formed by the range of the first match for the regular expression provided.
/// @param regex
/// @return NSString *
- (NSString *)stringByMatchingFirstOccurrenceOfRegEx:(NSString *)regex {
  return [self stringByMatchingRegEx:regex match:0 capture:0];
}

/// Returns the string formed by the range of the specified capture in the first match for the expression provided.
/// @param regex
/// @param capture
/// @return NSString *
- (NSString *)stringByMatchingFirstOccurrenceOfRegEx:(NSString *)regex capture:(NSUInteger)capture {
  return [self stringByMatchingRegEx:regex match:0 capture:capture];
}

/// Returns the string formed by the range of the specified capture in the specified match for the expression provided.
/// @param regex
/// @param match
/// @param capture
/// @return NSString *
- (NSString *)stringByMatchingRegEx:(NSString *)regex match:(NSUInteger)match capture:(NSUInteger)capture {
  NSRange range = [self rangeOfCapture:capture inMatch:match forRegEx:regex];
  return (range.location == NSNotFound ? nil : [self substringWithRange:range]);
}


/// Replaces occurences of the specified regular expression with the given string. Replacement strings can include
/// captures using $*capture*. i.e. @"$1". Alternatively, text can be provided to replace a particular capture with
/// $*capture*=*text*=. i.e. @"$1 $2=%0A="
/// @param regex The regular expression used to locate text to replace.
/// @param string The replacement text
- (NSString *)stringByReplacingRegEx:(NSString *)regex withString:(NSString *)string {
  NSMutableString * newString = [self mutableCopy];
  [newString replaceRegEx:regex withString:string];
  return newString;
}

/// Returns an array of substrings created by splitting the string on matches for the regular expression provided.
/// @param regex
/// @return NSArray *
- (NSArray *)componentsSeparatedByRegEx:(NSString *)regex {
  NSMutableString     * string = [self mutableCopy];
  [string sub:regex template:@"<match>"];
  return [string componentsSeparatedByString:@"<match>"];
}

/// Returns the array of `NSTextCheckingResults` obtained by matching the regular expression provided.
/// @param regex
/// @return NSArray *
- (NSArray *)matchesForRegEx:(NSString *)regex {
  NSError             * error = NULL;
  NSRegularExpression * re    = [NSRegularExpression
                                 regularExpressionWithPattern:regex
                                                      options:NSRegularExpressionAnchorsMatchLines
                                                        error:&error];

  if (error) { MSHandleErrors(error); return nil; }

  NSArray * matches = [re matchesInString:self options:0 range:NSMakeRange(0, [self length])];

  return matches;
}

/// Returns an array of the substrings formed by matching the string against the regular expression provided.
/// @param regex
/// @return NSArray *
- (NSArray *)matchingSubstringsForRegEx:(NSString *)regex {
  return [[self rangesOfMatchesForRegEx:regex] mapped:^(NSValue * range, NSUInteger idx) {
    NSRange r = RangeValue(range);
    return (r.location == NSNotFound ? @"" : [self substringWithRange:r]);
  }];
}

/// Returns a dictionary of the captured strings in the first match for the regular expression provided using specified
/// array as keys for the dictionary entries, or `NSNumber` objects if keys are not provided.
/// @param regex
/// @param keys
/// @return NSDictionary *
- (NSDictionary *)dictionaryOfCapturedStringsByMatchingFirstOccurrenceOfRegex:(NSString *)regex keys:(NSArray *)keys {
  return [self dictionaryOfCapturedStringsByMatchingFirstOccurrenceOfRegex:regex keys:keys options:0];
}

/// Returns a dictionary of the captured strings in the first match for the regular expression provided using specified
/// array as keys for the dictionary entries, or `NSNumber` objects if keys are not provided and the specified options.
/// @param regex
/// @param keys
/// @param options
/// @return NSDictionary *
- (NSDictionary *)dictionaryOfCapturedStringsByMatchingFirstOccurrenceOfRegex:(NSString *)regex
                                                                         keys:(NSArray *)keys
                                                                      options:(NSRegularExpressionOptions)options
{

  NSError * error = nil;
  NSRegularExpression * re = [NSRegularExpression regularExpressionWithPattern:regex options:options error:&error];
  NSUInteger keyMax = [keys count];
  if (MSHandleErrors(error)) return nil;
  NSMutableDictionary * dict = [@{} mutableCopy];
  NSTextCheckingResult * match = [re firstMatchInString:self options:9 range:self.fullRange];
  if (match) {
    for (NSUInteger i = 0; i < re.numberOfCaptureGroups; i++) {
      NSRange r = [match rangeAtIndex:i + 1];
      dict[(i < keyMax ? keys[i] : @(i))] = (r.location == NSNotFound ? NullObject : [self substringWithRange:r]);
    }
  }
  return dict;
}

/// Returns an array of the substrings captured in the first match for the regular expression provided.
/// @param regex
/// @return NSArray *
- (NSArray *)capturedStringsByMatchingFirstOccurrenceOfRegex:(NSString *)regex {
  return [self capturedStringsByMatchingFirstOccurrenceOfRegex:regex options:0];
}


/// Array of the substrings captured in the first match for the expression provided using the specified options.
/// @param regex
/// @param options
/// @return NSArray *
- (NSArray *)capturedStringsByMatchingFirstOccurrenceOfRegex:(NSString *)regex
                                                     options:(NSRegularExpressionOptions)options
{
  return [[self dictionaryOfCapturedStringsByMatchingFirstOccurrenceOfRegex:regex keys:nil options:options] allValues];
}

/// Returns the number of matches for the regular expression provided.
/// @param regex
/// @return NSUInteger
- (NSUInteger)numberOfMatchesForRegEx:(NSString *)regex { return [self numberOfMatchesForRegEx:regex options:0]; }

/// Returns the number of matches for the regular expression provided using the specified options.
/// @param regex
/// @param opts
/// @return NSUInteger
- (NSUInteger)numberOfMatchesForRegEx:(NSString *)regex options:(NSRegularExpressionOptions)opts {
  NSError             * error = nil;
  NSRegularExpression * re    = [NSRegularExpression regularExpressionWithPattern:regex options:opts error:&error];
  return (MSHandleErrors(error) ? 0 : [re numberOfMatchesInString:self options:0 range:NSMakeRange(0, [self length])]);
}

/// Returns whether a match is found for the regular expression provided using the specified options.
/// @param substring
/// @param options
/// @return BOOL
- (BOOL)hasSubstring:(NSString *)substring options:(NSRegularExpressionOptions)options {
  return ([self numberOfMatchesForRegEx:substring options:options]);
}

/// Returns whether a match is found for the regular expression provided.
/// @param substring
/// @return BOOL
- (BOOL)hasSubstring:(NSString *)substring { return [self hasSubstring:substring options:0]; }

@end
