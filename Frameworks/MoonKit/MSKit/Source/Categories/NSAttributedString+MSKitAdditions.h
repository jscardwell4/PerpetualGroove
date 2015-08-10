//
//  NSAttributedString+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 3/24/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//


@import Foundation;
@import UIKit;

@class MSDictionary;
@interface NSAttributedString (_MSKitAdditions)
- (instancetype)initWithString:(NSString *)str attributes:(MSDictionary *)attrs;
@end

@interface NSAttributedString (MSKitAdditions)

+ (instancetype)attributedStringWithString:(NSString *)string
                                attributes:(NSDictionary *)attributes;

+ (instancetype)attributedStringWithString:(NSString *)string;
- (NSAttributedString *)attributedStringWithAttribute:(NSString *)attribute value:(id)value;
- (NSAttributedString *)attributedStringWithAttributes:(NSDictionary *)attributes;
#if TARGET_OS_IPHONE
- (NSAttributedString *)attributedStringWithForegroundColor:(UIColor *)color;
- (NSAttributedString *)attributedStringWithBackgroundColor:(UIColor *)color;
- (NSAttributedString *)attributedStringWithStrokeColor:(UIColor *)color;
- (NSAttributedString *)attributedStringWithFont:(UIFont *)font;
#endif
- (NSAttributedString *)attributedStringWithParagraphStyle:(NSParagraphStyle *)paragraphStyle;
- (NSAttributedString *)attributedStringWithLigature:(NSNumber *)ligature;
- (NSAttributedString *)attributedStringWithKern:(NSNumber *)kern;
- (NSAttributedString *)attributedStringWithStrikethroughStyle:(NSNumber *)strikethroughStyle;
- (NSAttributedString *)attributedStringWithUnderlineStyle:(NSNumber *)underlineStyle;
- (NSAttributedString *)attributedStringWithStrokeWidth:(NSNumber *)strokeWidth;
- (NSAttributedString *)attributedStringWithShadow:(NSShadow *)shadow;

@end

@interface NSMutableAttributedString (MSKitAdditions)

- (void)applyAttribute:(NSString *)attribute value:(id)value;
- (void)applyAttributes:(NSDictionary *)attributes;

#if TARGET_OS_IPHONE
- (void)applyFont:(UIFont *)font;
- (void)applyForegroundColor:(UIColor *)color;
- (void)applyBackgroundColor:(UIColor *)color;
- (void)applyStrokeColor:(UIColor *)color;
#endif
- (void)applyParagraphStyle:(NSParagraphStyle *)paragraphStyle;
- (void)applyLigature:(NSNumber *)ligature;
- (void)applyKern:(NSNumber *)kern;
- (void)applyStrikethroughStyle:(NSNumber *)strikethroughStyle;
- (void)applyUnderlineStyle:(NSNumber *)underlineStyle;
- (void)applyStrokeWidth:(NSNumber *)strokeWidth;
- (void)applyShadow:(NSShadow *)shadow;

@end
