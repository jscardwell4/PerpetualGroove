//
//  UIFont+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 2/16/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;

@interface UIFont (MSKitAdditions)

+ (UIFont*)fontAwesomeFontWithSize:(CGFloat)size;

+ (NSSet *)fontAwesomeIconNames;

+ (NSSet *)fontAwesomeIconCharacters;

+ (NSString *)fontAwesomeIconForName:(NSString *)name;

+ (NSAttributedString *)attributedFontAwesomeIconForName:(NSString *)name;

+ (NSString *)fontAwesomeNameForIcon:(NSString *)icon;

@end
