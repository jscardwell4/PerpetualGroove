//
//  NSAttributedString+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 3/24/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "NSAttributedString+MSKitAdditions.h"

@implementation NSAttributedString (MSKitAdditions)

+ (instancetype)attributedStringWithString:(NSString *)string
                                        attributes:(NSDictionary *)attributes
{
    return [[self alloc] initWithString:string attributes:attributes];
}

+ (instancetype)attributedStringWithString:(NSString *)string
{
    return [[self alloc] initWithString:string];
}

- (NSAttributedString *)attributedStringWithAttribute:(NSString *)attribute value:(id)value
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyAttribute:attribute value:value];
    return attributedString;
}

- (NSAttributedString *)attributedStringWithAttributes:(NSDictionary *)attributes
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyAttributes:attributes];
    return attributedString;
}

#if TARGET_OS_IPHONE
- (NSAttributedString *)attributedStringWithForegroundColor:(UIColor *)color
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyForegroundColor:color];
    return attributedString;
}

- (NSAttributedString *)attributedStringWithBackgroundColor:(UIColor *)color
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyBackgroundColor:color];
    return attributedString;
}

- (NSAttributedString *)attributedStringWithFont:(UIFont *)font
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyFont:font];
    return attributedString;
}
#endif
- (NSAttributedString *)attributedStringWithParagraphStyle:(NSParagraphStyle *)paragraphStyle
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyParagraphStyle:paragraphStyle];
    return attributedString;
}

- (NSAttributedString *)attributedStringWithLigature:(NSNumber *)ligature
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyLigature:ligature];
    return attributedString;
}

- (NSAttributedString *)attributedStringWithKern:(NSNumber *)kern
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyKern:kern];
    return attributedString;
}

- (NSAttributedString *)attributedStringWithStrikethroughStyle:(NSNumber *)strikethroughStyle
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyStrikethroughStyle:strikethroughStyle];
    return attributedString;
}

- (NSAttributedString *)attributedStringWithUnderlineStyle:(NSNumber *)underlineStyle
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyUnderlineStyle:underlineStyle];
    return attributedString;
}

#if TARGET_OS_IPHONE
- (NSAttributedString *)attributedStringWithStrokeColor:(UIColor *)color
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyStrokeColor:color];
    return attributedString;
}
#endif
- (NSAttributedString *)attributedStringWithStrokeWidth:(NSNumber *)strokeWidth
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyStrokeWidth:strokeWidth];
    return attributedString;
}

- (NSAttributedString *)attributedStringWithShadow:(NSShadow *)shadow
{
    NSMutableAttributedString * attributedString = [self mutableCopy];
    [attributedString applyShadow:shadow];
    return attributedString;
}

@end

@implementation NSMutableAttributedString (MSKitAdditions)

- (void)applyAttribute:(NSString *)attribute value:(id)value
{
    NSRange range = NSMakeRange(0, self.length);
    [self removeAttribute:attribute range:range];
    if (value)
        [self addAttribute:attribute value:value range:range];
}

- (void)applyAttributes:(NSDictionary *)attributes
{
    NSRange range = NSMakeRange(0, self.length);
    for (NSString * key in attributes)
        [self removeAttribute:key range:range];
    [self addAttributes:attributes range:range];
}

#if TARGET_OS_IPHONE
- (void)applyForegroundColor:(UIColor *)color
{
    [self applyAttribute:NSForegroundColorAttributeName value:color];
}

- (void)applyBackgroundColor:(UIColor *)color
{
    [self applyAttribute:NSBackgroundColorAttributeName value:color];
}

- (void)applyFont:(UIFont *)font
{
    [self applyAttribute:NSFontAttributeName value:font];
}
#endif
- (void)applyParagraphStyle:(NSParagraphStyle *)paragraphStyle
{
    [self applyAttribute:NSParagraphStyleAttributeName value:paragraphStyle];
}

- (void)applyLigature:(NSNumber *)ligature
{
    [self applyAttribute:NSLigatureAttributeName value:ligature];
}

- (void)applyKern:(NSNumber *)kern
{
    [self applyAttribute:NSKernAttributeName value:kern];
}

- (void)applyStrikethroughStyle:(NSNumber *)strikethroughStyle
{
    [self applyAttribute:NSStrikethroughStyleAttributeName value:strikethroughStyle];
}

- (void)applyUnderlineStyle:(NSNumber *)underlineStyle
{
    [self applyAttribute:NSUnderlineStyleAttributeName value:underlineStyle];
}

#if TARGET_OS_IPHONE
- (void)applyStrokeColor:(UIColor *)color
{
    [self applyAttribute:NSStrokeColorAttributeName value:color];
}
#endif
- (void)applyStrokeWidth:(NSNumber *)strokeWidth
{
    [self applyAttribute:NSStrokeWidthAttributeName value:strokeWidth];
}

- (void)applyShadow:(NSShadow *)shadow
{
    [self applyAttribute:NSShadowAttributeName value:shadow];
}

@end
