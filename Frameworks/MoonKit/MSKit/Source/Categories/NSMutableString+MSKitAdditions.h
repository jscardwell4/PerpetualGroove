//
//  NSMutableString+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 9/16/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

@import Foundation;

@interface NSMutableString (MSKitAdditions)

/// Replaces the character at the specified index with unwrapped character value
- (void)setObject:(NSNumber *)object atIndexedSubscript:(NSUInteger)idx;

/// Convenience for `[NSMutableString replaceOccurrencesOfString:WithString:options:range:]`
- (void)replaceOccurrencesOfString:(NSString *)string withString:(NSString *)replacementString;

/// Replaces occurences of the keys in the specified dictionary with the corresponding values.
- (void)replaceOccurrencesOfStringsWithDictionary:(NSDictionary *)replacements;

/// Inserts a string at multiple locations
- (void)insertString:(NSString *)aString atIndexes:(NSIndexSet *)indexes;

@end

@interface NSMutableString (MSKitStrippingAdditions)

/// Removes occurrences of the specified character
- (void)removeCharacter:(unichar)character;

/// Removes occurrences of characters from the specified character set
- (void)removeCharactersFromSet:(NSCharacterSet *)characterSet;

/// stripTrailingZeroes
- (void)stripTrailingZeroes;

/// trimLeadingWhitespace
- (void)trimLeadingWhitespace;

/// trimTrailingWhitespace
- (void)trimTrailingWhitespace;

/// trimWhitespace
- (void)trimWhitespace;

/// Removes matching substrings for C style single line comments, '//…⏎'
- (void)stripSingleLineComments;

/// Removes matching substrings for C style multiline comments, '/*…*/'
- (void)stripMultiLineComments;

@end

@interface NSMutableString (MSKitTransformingAdditions)

/// Prefixes the start of each new line with spaces of the specified count.
- (void)shiftRight:(NSUInteger)shiftAmount;

/// Prefixes the start of each new line with spaces of the specified count, optionally ignoring the first line.
- (void)shiftRight:(NSUInteger)shiftAmount shiftFirstLine:(BOOL)shiftFirstLine;

/// Introduces newline characters to produce wrapped text
- (void)wrapLinesAtColumn:(NSUInteger)column;

@end

@interface NSMutableString (MSKitRegularExpressionAdditions)

/// Replaces occurences of the specified regular expression with the given string. Replacement strings can include
/// captures using $*capture*. i.e. @"$1". Alternatively, text can be provided to replace a particular capture with
/// $*capture*=*text*=. i.e. @"$1 $2=%0A="
- (void)replaceRegEx:(NSString *)regex withString:(NSString *)string;

/// Replaces occurences of the specified regular expression with the empty string.
- (void)removeMatchesForRegEx:(NSString *)regex;

/// Replaces matches for the regular expression provided using `NSRegularExpression` template substitution.
- (void)sub:(NSString *)regex template:(NSString *)temp;

/// Replaces matches for the regular expression provided using the specified options with `NSRegularExpression`
/// template substitution.
- (void)sub:(NSString *)regex template:(NSString *)temp options:(NSRegularExpressionOptions)opts;

@end
