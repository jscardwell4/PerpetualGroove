//
//  UIColor+MSKitAdditions.m
//  Remote
//
//  Created by Jason Cardwell on 4/24/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "UIColor+MSKitAdditions.h"
#import "NSString+MSKitAdditions.h"
#import "MSKitMacros.h"
#import <MoonKit/MoonKit-Swift.h>

static const NSDictionary * kColorIndex;

NSString *NSStringFromCGColorRenderingIntent(CGColorRenderingIntent intent) {
  NSString * renderingIntentString = nil;

  switch (intent) {
    case kCGRenderingIntentDefault:
      renderingIntentString = @"kCGRenderingIntentDefault";
      break;

    case kCGRenderingIntentAbsoluteColorimetric:
      renderingIntentString = @"kCGRenderingIntentAbsoluteColorimetric";
      break;

    case kCGRenderingIntentRelativeColorimetric:
      renderingIntentString = @"kCGRenderingIntentRelativeColorimetric";
      break;

    case kCGRenderingIntentPerceptual:
      renderingIntentString = @"kCGRenderingIntentPerceptual";
      break;

    case kCGRenderingIntentSaturation:
      renderingIntentString = @"kCGRenderingIntentSaturation";
      break;
  }

  return renderingIntentString;
}

NSString *NSStringFromCGColorSpaceModel(CGColorSpaceModel model) {
  NSString * modelString = nil;

  switch (model) {
    case kCGColorSpaceModelUnknown:
      modelString = @"Unknown";
      break;

    case kCGColorSpaceModelMonochrome:
      modelString = @"Monochrome";
      break;

    case kCGColorSpaceModelRGB:
      modelString = @"RGB";
      break;

    case kCGColorSpaceModelCMYK:
      modelString = @"CMYK";
      break;

    case kCGColorSpaceModelLab:
      modelString = @"Lab";
      break;

    case kCGColorSpaceModelDeviceN:
      modelString = @"DeviceN";
      break;

    case kCGColorSpaceModelIndexed:
      modelString = @"Indexed";
      break;

    case kCGColorSpaceModelPattern:
      modelString = @"Pattern";
      break;
  }

  return modelString;
}

@implementation UIColor (MSKitAdditions)


//- (NSString *)rgbHexString { return [NSString stringWithFormat:@"#%.6X", self.rgbHex]; }

//- (NSString *)rgbaHexString { return [NSString stringWithFormat:@"#%.8X", self.rgbaHex]; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark Class methods
////////////////////////////////////////////////////////////////////////////////

+ (UIColor *)colorWithJSONValue:(NSString *)string {
  return [self colorWithString:string];
}
+ (UIColor *)colorWithString:(NSString *)string {
  UIColor * color = nil;

  if (string) {
    color = [self colorWithName:string];
    if (!color && [string hasSubstring:@"@.*%"]) {
      NSArray * baseAndAlpha = [string componentsSeparatedByString:@"@"];
      if ([baseAndAlpha count] == 2) {
        NSString * base    = baseAndAlpha[0];
        NSString * percent = [baseAndAlpha[1] substringToIndex:[baseAndAlpha[1] length] - 1];
        color = [[UIColor colorWithName:base] colorWithAlphaComponent:[percent floatValue] / 100.0f];
      }
    } else if (!color && [string hasPrefix:@"#"]) {
      color = ([string length] < 8 ? [UIColor colorWithRGBHexString:string] : [UIColor colorWithRGBAHexString:string]);
    } else if (!color) {
      NSArray * components = [string componentsSeparatedByString:@" "];
      if ([components count] == 3) {
      color = [UIColor colorWithRed:[(NSString *)components[0] floatValue]
                              green:[(NSString *)components[1] floatValue]
                               blue:[(NSString *)components[2] floatValue]
                              alpha:1.0];
      } else if ([components count] == 4) {
        color = [UIColor colorWithRed:[(NSString *)components[0] floatValue]
                                green:[(NSString *)components[1] floatValue]
                                 blue:[(NSString *)components[2] floatValue]
                                alpha:[(NSString *)components[3] floatValue]];
      }
    }
  }

  return color;
}

+ (UIColor *)colorWithR:(uint8_t)r G:(uint8_t)g B:(uint8_t)b A:(uint8_t)a {
  return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a / 255.0f];
}

+ (UIColor *)colorWithRGBHex:(uint32_t)hex {
  return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0f
                         green:((hex >>  8) & 0xFF) / 255.0f
                          blue:((hex >>  0) & 0xFF) / 255.0f
                         alpha:1.0f];
}

+ (UIColor *)colorWithRGBAHex:(uint32_t)hex {
  return [UIColor colorWithRed:((hex >> 24) & 0xFF) / 255.0f
                         green:((hex >> 16) & 0xFF) / 255.0f
                          blue:((hex >>  8) & 0xFF) / 255.0f
                         alpha:((hex >>  0) & 0xFF) / 255.0f];
}

+ (UIColor *)colorWithRGBHexString:(NSString *)string {
  if (!string)
    return nil;

  else if ([string characterAtIndex:0] == '#')
    string = [string substringFromIndex:1];

  NSScanner * scanner = [NSScanner scannerWithString:string];
  uint32_t hexValue = 0;
  if ([scanner scanHexInt:&hexValue])
    return [UIColor colorWithRGBHex:hexValue];
  else
    return nil;
}

+ (UIColor *)colorWithRGBAHexString:(NSString *)string {
  if (!string)
    return nil;

  else if ([string characterAtIndex:0] == '#')
    string = [string substringFromIndex:1];

  NSScanner * scanner = [NSScanner scannerWithString:string];
  uint32_t    hexValue;
  if ([scanner scanHexInt:&hexValue])
    return [UIColor colorWithRGBAHex:hexValue];
  else
    return nil;
}

+ (UIColor *)colorWithName:(NSString *)name {
  NSNumber * hex = kColorIndex[name];
  return (hex ? [self colorWithRGBAHex:[hex unsignedIntValue]] : nil);
}

+ (NSString *)nameForColor:(UIColor *)color ignoreAlpha:(BOOL)ignoreAlpha {
  uint32_t hex = (ignoreAlpha
                  ? [[color colorWithAlphaComponent:1.0f] rgbaHexValue].unsignedIntValue
                  : [color rgbaHexValue].unsignedIntValue);

  if (!hex && ![color isEqual:ClearColor])
    return nil;

  else {
    NSNumber * hexValue = @(hex);
    NSSet    * keys     = [kColorIndex keysOfEntriesPassingTest:
                           ^BOOL (id key, NSNumber * obj, BOOL * stop) {
                             return [obj isEqualToNumber:hexValue];
                           }];

    return ([keys containsObject:@"black"] ? @"black" : [keys anyObject]);
  }
}

- (NSString *)colorName { return [UIColor nameForColor:self ignoreAlpha:YES]; }

+ (NSArray *)colorNames { return [kColorIndex allKeys]; }

+ (void)load {
  kColorIndex = @{
    @"clear"                   : @0x00000000,
    @"black"                   : @0x000000FF,
    @"system-green"            : @0x00FF00FF,
    @"system-orange"           : @0xFF8000FF,
    @"light-gray"              : @0xAAAAAAFF,
    @"dark-text"               : @0x000000FF,
    @"light-text"              : @0xFFFFFF9A,
    @"brown"                   : @0x9A6633FF,
    @"flipside"                : @0x1F2124FF,
    @"group-table"             : @0xEFEFF4FF,
    @"alice-blue"              : @0xF0F8FFFF,
    @"antique-white"           : @0xFAEBD7FF,
    @"aqua"                    : @0x00FFFFFF,
    @"aquamarine"              : @0x7FFFD4FF,
    @"azure"                   : @0xF0FFFFFF,
    @"beige"                   : @0xF5F5DCFF,
    @"bisque"                  : @0xFFE4C4FF,
    @"blanched-almond"         : @0xFFEBCDFF,
    @"blue"                    : @0x0000FFFF,
    @"blue-violet"             : @0x8A2BE2FF,
    @"brown"                   : @0xA52A2AFF,
    @"burly-wood"              : @0xDEB887FF,
    @"cadet-blue"              : @0x5F9EA0FF,
    @"chartreuse"              : @0x7FFF00FF,
    @"chocolate"               : @0xD2691EFF,
    @"coral"                   : @0xFF7F50FF,
    @"cornflower-blue"         : @0x6495EDFF,
    @"cornsilk"                : @0xFFF8DCFF,
    @"crimson"                 : @0xDC143CFF,
    @"cyan"                    : @0x00FFFFFF,
    @"dark-blue"               : @0x00008BFF,
    @"dark-cyan"               : @0x008B8BFF,
    @"dark-golden-rod"         : @0xB8860BFF,
    @"dark-gray"               : @0xA9A9A9FF,
    @"dark-green"              : @0x006400FF,
    @"dark-grey"               : @0xA9A9A9FF,
    @"dark-khaki"              : @0xBDB76BFF,
    @"dark-magenta"            : @0x8B008BFF,
    @"dark-olivegreen"         : @0x556B2FFF,
    @"dark-orange"             : @0xFF8C00FF,
    @"dark-orchid"             : @0x9932CCFF,
    @"dark-red"                : @0x8B0000FF,
    @"dark-salmon"             : @0xE9967AFF,
    @"dark-sea-green"          : @0x8FBC8FFF,
    @"dark-slate-blue"         : @0x483D8BFF,
    @"dark-slate-gray"         : @0x2F4F4FFF,
    @"dark-slate-grey"         : @0x2F4F4FFF,
    @"dark-turquoise"          : @0x00CED1FF,
    @"dark-violet"             : @0x9400D3FF,
    @"deep-pink"               : @0xFF1493FF,
    @"deep-sky-blue"           : @0x00BFFFFF,
    @"dim-gray"                : @0x696969FF,
    @"dodger-blue"             : @0x1E90FFFF,
    @"fire-brick"              : @0xB22222FF,
    @"floral-white"            : @0xFFFAF0FF,
    @"forest-green"            : @0x228B22FF,
    @"fuchsia"                 : @0xFF00FFFF,
    @"gainsboro"               : @0xDCDCDCFF,
    @"ghost-white"             : @0xF8F8FFFF,
    @"gold"                    : @0xFFD700FF,
    @"golden-rod"              : @0xDAA520FF,
    @"gray"                    : @0x808080FF,
    @"green"                   : @0x008000FF,
    @"green-yellow"            : @0xADFF2FFF,
    @"honey-dew"               : @0xF0FFF0FF,
    @"hot-pink"                : @0xFF69B4FF,
    @"indian-red"              : @0xCD5C5CFF,
    @"indigo"                  : @0x4B0082FF,
    @"ivory"                   : @0xFFFFF0FF,
    @"khaki"                   : @0xF0E68CFF,
    @"lavender"                : @0xE6E6FAFF,
    @"lavender-blush"          : @0xFFF0F5FF,
    @"lawn-green"              : @0x7CFC00FF,
    @"lemon-chiffon"           : @0xFFFACDFF,
    @"light-blue"              : @0xADD8E6FF,
    @"light-coral"             : @0xF08080FF,
    @"light-cyan"              : @0xE0FFFFFF,
    @"light-golden-rod-yellow" : @0xFAFAD2FF,
    @"light-gray"              : @0xD3D3D3FF,
    @"light-green"             : @0x90EE90FF,
    @"light-grey"              : @0xD3D3D3FF,
    @"light-pink"              : @0xFFB6C1FF,
    @"light-salmon"            : @0xFFA07AFF,
    @"light-sea-green"         : @0x20B2AAFF,
    @"light-sky-blue"          : @0x87CEFAFF,
    @"light-slate-gray"        : @0x778899FF,
    @"light-steel-blue"        : @0xB0C4DEFF,
    @"light-yellow"            : @0xFFFFE0FF,
    @"lime"                    : @0x00FF00FF,                  // same as system-green
    @"lime-green"              : @0x32CD32FF,
    @"linen"                   : @0xFAF0E6FF,
    @"magenta"                 : @0xFF00FFFF,
    @"maroon"                  : @0x800000FF,
    @"medium-aquamarine"       : @0x66CDAAFF,
    @"medium-blue"             : @0x0000CDFF,
    @"medium-orchid"           : @0xBA55D3FF,
    @"medium-purple"           : @0x9370DBFF,
    @"medium-sea-green"        : @0x3CB371FF,
    @"medium-slate-blue"       : @0x7B68EEFF,
    @"medium-spring-green"     : @0x00FA9AFF,
    @"medium-turquoise"        : @0x48D1CCFF,
    @"medium-violet-red"       : @0xC71585FF,
    @"midnight-blue"           : @0x191970FF,
    @"mint-cream"              : @0xF5FFFAFF,
    @"misty-rose"              : @0xFFE4E1FF,
    @"moccasin"                : @0xFFE4B5FF,
    @"navajo-white"            : @0xFFDEADFF,
    @"navy"                    : @0x000080FF,
    @"old-lace"                : @0xFDF5E6FF,
    @"olive"                   : @0x808000FF,
    @"olive-drab"              : @0x6B8E23FF,
    @"orange"                  : @0xFFA500FF,
    @"orange-red"              : @0xFF4500FF,
    @"orchid"                  : @0xDA70D6FF,
    @"pale-golden-rod"         : @0xEEE8AAFF,
    @"pale-green"              : @0x98FB98FF,
    @"pale-turquoise"          : @0xAFEEEEFF,
    @"pale-violet-red"         : @0xDB7093FF,
    @"papaya-whip"             : @0xFFEFD5FF,
    @"peach-puff"              : @0xFFDAB9FF,
    @"peru"                    : @0xCD853FFF,
    @"pink"                    : @0xFFC0CBFF,
    @"plum"                    : @0xDDA0DDFF,
    @"powder-blue"             : @0xB0E0E6FF,
    @"purple"                  : @0x800080FF,
    @"red"                     : @0xFF0000FF,
    @"rosy-brown"              : @0xBC8F8FFF,
    @"royal-blue"              : @0x4169E1FF,
    @"saddle-brown"            : @0x8B4513FF,
    @"salmon"                  : @0xFA8072FF,
    @"sandy-brown"             : @0xF4A460FF,
    @"sea-green"               : @0x2E8B57FF,
    @"sea-shell"               : @0xFFF5EEFF,
    @"sienna"                  : @0xA0522DFF,
    @"silver"                  : @0xC0C0C0FF,
    @"sky-blue"                : @0x87CEEBFF,
    @"slate-blue"              : @0x6A5ACDFF,
    @"slate-gray"              : @0x708090FF,
    @"snow"                    : @0xFFFAFAFF,
    @"spring-green"            : @0x00FF7FFF,
    @"steel-blue"              : @0x4682B4FF,
    @"tan"                     : @0xD2B48CFF,
    @"teal"                    : @0x008080FF,
    @"thistle"                 : @0xD8BFD8FF,
    @"tomato"                  : @0xFF6347FF,
    @"turquoise"               : @0x40E0D0FF,
    @"violet"                  : @0xEE82EEFF,
    @"wheat"                   : @0xF5DEB3FF,
    @"white"                   : @0xFFFFFFFF,
    @"white-smoke"             : @0xF5F5F5FF,
    @"yellow"                  : @0xFFFF00FF,
    @"yellow-green"            : @0x9ACD32FF
  };
}

@end
