//
//  NSMutableString+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 9/16/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

#import "NSMutableString+MSKitAdditions.h"
#import "NSString+MSKitAdditions.h"
#import "MSLog.h"

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

@implementation NSMutableString (MSKitAdditions)

/// setObject:atIndexedSubscript:
/// @param object
/// @param idx
- (void)setObject:(NSNumber *)object atIndexedSubscript:(NSUInteger)idx {
  if (idx >= self.length) [[NSException exceptionWithName:NSRangeException
                                                   reason:@"index out of range" userInfo:nil] raise];

  [self replaceCharactersInRange:NSMakeRange(idx, 1) withString:$(@"%c", [object charValue])];
}

/// replaceOccurrencesOfString:withString:
/// @param string
/// @param replacementString
- (void)replaceOccurrencesOfString:(NSString *)string withString:(NSString *)replacementString {
  [self replaceOccurrencesOfString:string withString:replacementString options:0 range:NSMakeRange(0, [self length])];
}

/// replaceOccurrencesOfStringsWithDictionary:
/// @param replacements
- (void)replaceOccurrencesOfStringsWithDictionary:(NSDictionary *)replacements {
  if (!replacements) return;

  [replacements enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * stop) {
    NSRange range = [self rangeOfString:(NSString *)key];

    while (range.location != NSNotFound) {
      [self replaceCharactersInRange:range withString:(NSString *)obj];
      range = [self rangeOfString:(NSString *)key];
    }
  }

   ];
}

/// String containing the specified number of the specified character
/// @param character
/// @param count
/// @return NSString *
+ (instancetype)stringWithCharacter:(unichar)character count:(NSUInteger)count {
  NSMutableString * returnString = [@"" mutableCopy];
  for (int i = 0; i < count; i++) [returnString appendFormat:@"%c",character];
  return returnString;
}

/// String containing the specified number of the specified string
/// @param string
/// @param count
/// @return NSString *
+ (instancetype)stringWithString:(NSString *)string count:(NSUInteger)count {
  NSMutableString * s = [@"" mutableCopy];
  for (int i = 0; i < count; i++) [s appendString:string];
  return s;
}


/// insertString:atIndexes:
/// @param aString
/// @param indexes
- (void)insertString:(NSString *)aString atIndexes:(NSIndexSet *)indexes {
  __block NSUInteger offset       = 0;
  NSUInteger         offsetLength = [aString length];

  [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * stop)
  {
    NSUInteger insertionIndex = idx + offset;

    if (insertionIndex < [self length]) {
      [self insertString:aString atIndex:insertionIndex];
      offset += offsetLength;
    } else if (insertionIndex == [self length]) {
      [self appendString:aString];
      *stop = YES;
    } else {
      *stop = YES;
    }
  }];
}

@end

@implementation NSMutableString (MSKitTransformingAdditions)

/// shiftRight:
/// @param shiftAmount
- (void)shiftRight:(NSUInteger)shiftAmount {
  [self shiftRight:shiftAmount shiftFirstLine:YES];
}

/// shiftRight:shiftFirstLine:
/// @param shiftAmount
/// @param shiftFirstLine
- (void)shiftRight:(NSUInteger)shiftAmount shiftFirstLine:(BOOL)shiftFirstLine {

  NSString * padding = [NSString stringWithCharacter:' ' count:shiftAmount];

  if (shiftFirstLine)
    [self insertString:padding atIndex:0];

  [self replaceOccurrencesOfString:@"\n" withString:$(@"\n%@", padding)
                           options:0
                             range:NSMakeRange(0, [self length])];
}

/// wrapLinesAtColumn:
/// @param column
- (void)wrapLinesAtColumn:(NSUInteger)column {
  if ([self length] < column) return;

  NSLinguisticTagger * tagger = [[NSLinguisticTagger alloc]
                                 initWithTagSchemes:@[NSLinguisticTagSchemeTokenType]
                                 options:0];

  [tagger setString:self];
  __block NSRange     range      = NSMakeRange(0, column);
  NSMutableIndexSet * lineBreaks = [NSMutableIndexSet indexSet];

  while (range.location < [self length] - column) {
    NSArray * tokenRanges = nil;
    NSArray * rangeTags   = [tagger tagsInRange:range
                                         scheme:NSLinguisticTagSchemeTokenType
                                        options:0
                                    tokenRanges:&tokenRanges];

    [rangeTags enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:
     ^(NSString * tag, NSUInteger idx, BOOL * stop)
     {
       if ([NSLinguisticTagPunctuation isEqualToString:tag]) {
         NSRange tagRange = [tokenRanges[idx] rangeValue];
         NSUInteger insertionIndex = NSMaxRange(tagRange);
         [lineBreaks addIndex:insertionIndex];
         range.location = insertionIndex;
         *stop = YES;
       }
     }];
  }

  [self insertString:@"\n" atIndexes:lineBreaks];
  
}

@end

@implementation NSMutableString (MSKitStrippingAdditions)

/// removeCharacter:
/// @param character
- (void)removeCharacter:(unichar)character {
  [self replaceOccurrencesOfString:[NSString stringWithFormat:@"%c", character]
                        withString:@""
                           options:0 range:NSMakeRange(0, self.length)];
}

/// removeCharactersFromSet:
/// @param characterSet
- (void)removeCharactersFromSet:(NSCharacterSet *)characterSet {
  self.string = [self stringByRemovingCharactersFromSet:characterSet];
}

/// stripTrailingZeroes
- (void)stripTrailingZeroes {
  [self replaceRegEx:@"(?:([0-9]+\\.[0-9]*[1-9])0+)|(?:([0-9]+)\\.0+)" withString:@"$1$2"];
}

/// trimLeadingWhitespace
- (void)trimLeadingWhitespace {
  NSInteger i = 0;
  while ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[self characterAtIndex:i]]) i++;
  [self setString:[self substringFromIndex:i]];
}

/// trimTrailingWhitespace
- (void)trimTrailingWhitespace {
  NSInteger i = [self length] - 1;
  while ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[self characterAtIndex:i]]) i--;
  [self setString:[self substringToIndex:i + 1]];
}

/// trimWhitespace
- (void)trimWhitespace {
  [self setString:[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

/// Removes matching substrings for C style single line comments, '//…⏎'
- (void)stripSingleLineComments {
//  NSString * regex = [@"" join:@[@"(?:^\\s*//[^\\n]*[^\\n](?=\\n))",  // any amount of whitespace followed by comment
//                                 @"|",                                // or
//                                 @"(?:^\\s*)"]];
  [self removeMatchesForRegEx:@"(?:[^\"]*|\"[^\"]*\")*//[^\\n]*"];
}

/// Removes matching substrings for C style multiline comments, '/*…*/'
- (void)stripMultiLineComments { [self removeMatchesForRegEx:@"/\\*(?:[^\\*]|\\*(?!=/))*\\*/"]; }

@end

@implementation NSMutableString (MSKitRegularExpressionAdditions)

/// Replaces occurences of the specified regular expression with the given string. Replacement strings can include
/// captures using $*capture*. i.e. @"$1". Alternatively, text can be provided to replace a particular capture with
/// $*capture*=*text*=. i.e. @"$1 $2=%0A="
/// @param regex The regular expression used to locate text to replace.
/// @param string The replacement text
- (void)replaceRegEx:(NSString *)regex withString:(NSString *)string {

  NSInteger startingLength = self.length;
  NSArray * matches        = [self matchesForRegEx:regex];
  NSArray * captures       = [string matchingSubstringsForRegEx:@"\\$[0-9]([=][^=]+[=])?"];

  for (NSTextCheckingResult * match in matches) {
    NSRange matchRange = [match range];

    matchRange.location -= startingLength - self.length;
    NSMutableString * replaceString = [string mutableCopy];

    for (NSString * capture in captures) {
      NSString * capReplace = [capture stringByMatchingFirstOccurrenceOfRegEx:@"\\$[0-9][=]([^=]+)[=]" capture:1];
      NSString * capNum     = [capture stringByRemovingCharacter:'$'];

      if (capNum) {
        NSInteger  n       = [capNum integerValue];
        NSString * rString = @"";
        NSRange    r       = [match rangeAtIndex:n];

        if (n <= [match numberOfRanges] && r.location != NSNotFound) {

          r.location -= startingLength - self.length;

          if (capReplace) rString = capReplace;
          else            rString = [self substringWithRange:r];

        }

        [replaceString replaceOccurrencesOfString:capture withString:rString];

      }

    }

    [self replaceCharactersInRange:matchRange withString:replaceString];
    
  }

}

/// Replaces occurences of the specified regular expression with the empty string.
/// @param regex
- (void)removeMatchesForRegEx:(NSString *)regex { [self replaceRegEx:regex withString:@""]; }

/// Replaces matches for the regular expression provided using `NSRegularExpression` template substitution.
/// @param regex
/// @param temp
- (void)sub:(NSString *)regex template:(NSString *)temp { [self sub:regex template:temp options:0]; }

/// Replaces matches for the regular expression provided using the specified options with `NSRegularExpression`
/// template substitution.
/// @param regex
/// @param temp
/// @param opts
- (void)sub:(NSString *)regex template:(NSString *)temp options:(NSRegularExpressionOptions)opts {
  NSError             * error             = nil;
  NSRegularExpression * re = [NSRegularExpression regularExpressionWithPattern:regex options:opts error:&error];
  if (MSHandleErrors(error)) return;
  [re replaceMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:temp];
}

@end
