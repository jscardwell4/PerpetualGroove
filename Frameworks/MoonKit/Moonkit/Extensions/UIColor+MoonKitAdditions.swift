//
//  UIColor+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 11/21/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import Chameleon

extension UIColor: JSONValueConvertible {
  public var jsonValue: JSONValue { return JSONValue.String(string!) }
}
extension UIColor /*: JSONValueInitializable */ {
  public convenience init?(_ jsonValue: JSONValue?) {
    if let string = String(jsonValue) {
      self.init(string: string)
    } else {
      self.init()
      return nil
    }
  }
}

extension UIColor: StringValueConvertible { public var stringValue: String { return string ?? "" } }

extension UIColor {

  /**
  initWithString:

  - parameter string: String
  */
  public convenience init?(string: String) {
    if let color = UIColor(name: string), let (r, g, b, a) = color.rgba {
      self.init(red: r, green: g, blue: b, alpha: a)
    } else if string ~= "@.*%" {
      let (base, alpha) = disperse2("@".split(string))
      if let color = UIColor(name: base), let (r, g, b, _) = color.rgba {
        self.init(red: r, green: g, blue: b, alpha: CGFloat((String(alpha.characters.dropLast()) as NSString).floatValue / 100.0))
      } else {
        self.init()
        return nil
      }
    } else if string[0] == "#" {
      if let color = (string.characters.count < 8 ? UIColor(RGBHexString: string) : UIColor(RGBAHexString: string)),
        let (r, g, b, a) = color.rgba {
          self.init(red: r, green: g, blue: b, alpha: a)
      } else {
        self.init()
        return nil
      }
    }
    else {
      let components = " ".split(string)
      let mappedComponents = components.map{CGFloat(($0 as NSString).floatValue)}
      if mappedComponents.count == 3 {
        self.init(red: mappedComponents[0], green: mappedComponents[1], blue: mappedComponents[2], alpha: 1.0)
      } else if mappedComponents.count == 4 {
        self.init(red: mappedComponents[0], green: mappedComponents[1], blue: mappedComponents[2], alpha: mappedComponents[3])
      } else {
        self.init()
        return nil
      }
    }
  }

  public var rgba: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    return getRed(&r, green: &g, blue: &b, alpha: &a) ? (r: r, g: g, b: b, a: a) : nil
  }

  public var hsba: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat)? {
    var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    return getHue(&h, saturation: &s, brightness: &b, alpha: &a) ? (h: h, s: s, b: b, a: a) : nil
  }
  public var red: CGFloat? { return rgba?.r }
  public var green: CGFloat? { return rgba?.g }
  public var blue: CGFloat? { return rgba?.b }

  public var hue: CGFloat? { return hsba?.h }
  public var saturation: CGFloat? { return hsba?.s }
  public var brightness: CGFloat? { return hsba?.b }

  public var perceivedBrightness: CGFloat? {
    var value: CGFloat?
    if let rgba = self.rgba {
      let r = pow(rgba.r * rgba.a, 2)
      let g = pow(rgba.g * rgba.a, 2)
      let b = pow(rgba.b * rgba.a, 2)
      value = sqrt(0.241 * r + 0.691 * g + 0.068 * b)
    }
    return value
  }

  public var white: CGFloat? { var w: CGFloat = 0, a: CGFloat = 0; return getWhite(&w, alpha: &a) ? w : nil }

  public var alpha: CGFloat? { return rgba?.a }

  public var inverted: UIColor? {
    if let rgba = self.rgba {
      return UIColor(red: 1 - rgba.r, green: 1 - rgba.g, blue: 1 - rgba.b, alpha: 1 - rgba.a)
    } else {
      return nil
    }
  }

  public var luminanceMapped: UIColor? {
    if let rgba = self.rgba {
      return UIColor(white: rgba.r * 0.2126 + rgba.g * 0.7152 + rgba.b * 0.0722, alpha: rgba.a)
    } else {
      return nil
    }
  }

  public var rgbaHexString: String? {
    if let hex = rgbaHex {
      var hexString = String(hex, radix: 16, uppercase: true)
      while hexString.characters.count < 8 { hexString = "0" + hexString }
      return "#\(hexString)"
    } else {
      return nil
    }
  }

  public var rgbHexString: String? {
    if let hex = rgbHex {
      var hexString = String(hex, radix: 16, uppercase: true)
      while hexString.characters.count < 6 { hexString = "0" + hexString }
      return "#\(hexString)"
    } else {
      return nil
    }
  }

  public var string: String? {
    if let name = colorName {
      let a = alpha ?? 1.0
      return a == 1.0 ? name : "\(name)@\(Int(a * 100.0))%"
    } else if rgba != nil {
      return rgbaHexString
    } else {
      return nil
    }
  }

  public var rgbHexValue: NSNumber? { if let hex = rgbHex { return NSNumber(unsignedInt: hex) } else { return nil } }
  public var rgbaHexValue: NSNumber? { if let hex = rgbaHex { return NSNumber(unsignedInt: hex) } else { return nil } }
  public var rgbHex: UInt32? { if let hex = rgbaHex { return hex >> 8 } else { return nil } }
  public var rgbaHex: UInt32? {
    if let rgba = self.rgba {
      let rHex: UInt32 = UInt32(rgba.r * 255.0) << 24
      let gHex: UInt32 = UInt32(rgba.g * 255.0) << 16
      let bHex: UInt32 = UInt32(rgba.b * 255.0) << 8
      let aHex: UInt32 = UInt32(rgba.a * 255.0) << 0
      return rHex | gHex | bHex | aHex
    } else {
      return nil
    }
  }

  /**
  randomColor

  - returns: UIColor
  */
  public class func randomColor() -> UIColor {
    let max = Int(RAND_MAX)
    let red   = CGFloat(max / random())
    let green = CGFloat(max / random())
    let blue  = CGFloat(max / random())
    let alpha = CGFloat(max / random())
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  public var colorSpaceModel: CGColorSpaceModel { return CGColorSpaceGetModel(CGColorGetColorSpace(CGColor)) }
  public var isPatternBased: Bool { return colorSpaceModel.rawValue == CGColorSpaceModel.Pattern.rawValue }

  public var isRGBCompatible: Bool {
    switch colorSpaceModel.rawValue {
      case CGColorSpaceModel.RGB.rawValue, CGColorSpaceModel.Monochrome.rawValue: return true
      default: return false
    }
  }

  public var rgbColor: UIColor? {

    switch colorSpaceModel.rawValue {
      case CGColorSpaceModel.RGB.rawValue:
        return self
      default:
        if let rgba = self.rgba {
          return UIColor(red: rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a)
        } else {
          return nil
        }
    }
  }

  /**
  lightenedToRed:green:blue:alpha:

  - parameter r: CGFloat
  - parameter g: CGFloat
  - parameter b: CGFloat
  - parameter a: CGFloat

  - returns: UIColor?
  */
  public func lightenedToRed(r: CGFloat, green g: CGFloat, blue b: CGFloat, alpha a: CGFloat) -> UIColor? {
    if let rgba = self.rgba {
      return UIColor(red: max(rgba.r, r), green: max(rgba.g, g), blue: max(rgba.b, b), alpha: max(rgba.a, a))
    } else {
      return nil
    }
  }

  /**
  lightenedTo:

  - parameter value: CGFloat

  - returns: UIColor?
  */
  public func lightenedTo(value: CGFloat) -> UIColor? { return lightenedToRed(value, green: value, blue: value, alpha: value) }

  /**
  lightenedToColor:

  - parameter color: UIColor

  - returns: UIColor?
  */
  public func lightenedToColor(color: UIColor) -> UIColor? {
    if let rgba = color.rgba {
      return lightenedToRed(rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a)
    } else {
      return nil
    }
  }

  /**
  darkenedToRed:green:blue:alpha:

  - parameter r: CGFloat
  - parameter g: CGFloat
  - parameter b: CGFloat
  - parameter a: CGFloat

  - returns: UIColor?
  */
  public func darkenedToRed(r: CGFloat, green g: CGFloat, blue b: CGFloat, alpha a: CGFloat) -> UIColor? {
    if let rgba = self.rgba {
      return UIColor(red: min(rgba.r, r), green: min(rgba.g, g), blue: min(rgba.b, b), alpha: min(rgba.a, a))
    } else {
      return nil
    }
  }

  /**
  darkenedTo:

  - parameter value: CGFloat

  - returns: UIColor?
  */
  public func darkenedTo(value: CGFloat) -> UIColor? { return darkenedToRed(value, green: value, blue: value, alpha: value) }

  /**
  brightnessAdjustedBy:

  - parameter value: CGFloat

  - returns: UIColor
  */
  public func brightnessAdjustedBy(value: CGFloat) -> UIColor {
    let laba = LABA
    let rgb = labToRGB(laba.l + value, laba.a, laba.b)
    return UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: laba.alpha)
  }

  /**
  darkenedToColor:

  - parameter color: UIColor

  - returns: UIColor?
  */
  public func darkenedToColor(color: UIColor) -> UIColor? {
    if let rgba = color.rgba {
      return darkenedToRed(rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a)
    } else {
      return nil
    }
  }

  /**
  addedWithRed:green:blue:alpha:

  - parameter r: CGFloat
  - parameter g: CGFloat
  - parameter b: CGFloat
  - parameter a: CGFloat

  - returns: UIColor?
  */
  public func addedWithRed(r: CGFloat, green g: CGFloat, blue b: CGFloat, alpha a: CGFloat) -> UIColor? {
    if let rgba = self.rgba {
      let red = max(0.0, min(1.0, rgba.r + r))
      let green = max(0.0, min(1.0, rgba.g + g))
      let blue = max(0.0, min(1.0, rgba.b + b))
      let alpha = max(0.0, min(1.0, rgba.a + a))
      return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    } else {
      return nil
    }
  }

  /**
  addedWith:

  - parameter value: CGFloat

  - returns: UIColor?
  */
  public func addedWith(value: CGFloat) -> UIColor? { return addedWithRed(value, green: value, blue: value, alpha: value) }

  /**
  addedWithColor:

  - parameter color: UIColor

  - returns: UIColor?
  */
  public func addedWithColor(color: UIColor) -> UIColor? {
    if let rgba = color.rgba {
      return addedWithRed(rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a)
    } else {
      return nil
    }
  }

  /**
  multipliedBy:

  - parameter value: CGFloat

  - returns: UIColor
  */
  public func multipliedBy(value: CGFloat) -> UIColor? {
    return multipliedByRed(value, green: value, blue: value, alpha: value)
  }

  /**
  multipliedByRed:green:blue:alpha:

  - parameter r: CGFloat
  - parameter g: CGFloat
  - parameter b: CGFloat
  - parameter a: CGFloat

  - returns: UIColor?
  */
  public func multipliedByRed(r: CGFloat, green g: CGFloat, blue b: CGFloat, alpha a: CGFloat) -> UIColor? {
    if let rgba = self.rgba {
      let red = max(0.0, min(1.0, rgba.r * r))
      let green = max(0.0, min(1.0, rgba.g * g))
      let blue = max(0.0, min(1.0, rgba.b * b))
      let alpha = max(0.0, min(1.0, rgba.a * a))
      return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    } else {
      return nil
    }
  }

  /**
  multipliedByColor:

  - parameter color: UIColor

  - returns: UIColor?
  */
  public func multipliedByColor(color: UIColor) -> UIColor? {
    if let rgba = color.rgba {
      return multipliedByRed(rgba.r, green: rgba.g, blue: rgba.b, alpha: rgba.a)
    } else {
      return nil
    }
  }

  /**
  colorWithRed:

  - parameter red: CGFloat

  - returns: UIColor
  */
  public func colorWithRed(red: CGFloat) -> UIColor {
    if let rgba = self.rgba { return UIColor(red: red, green: rgba.g, blue: rgba.b, alpha: rgba.a) }
    else { return UIColor(red: red, green: 1, blue: 1, alpha: 1) }
  }

  /**
  colorWithGreen:

  - parameter green: CGFloat

  - returns: UIColor
  */
  public func colorWithGreen(green: CGFloat) -> UIColor {
    if let rgba = self.rgba { return UIColor(red: rgba.r, green: green, blue: rgba.b, alpha: rgba.a) }
    else { return UIColor(red: 1, green: green, blue: 1, alpha: 1) }
  }

  /**
  colorWithBlue:

  - parameter blue: CGFloat

  - returns: UIColor
  */
  public func colorWithBlue(blue: CGFloat) -> UIColor {
    if let rgba = self.rgba { return UIColor(red: rgba.r, green: rgba.g, blue: blue, alpha: rgba.a) }
    else { return UIColor(red: 1, green: 1, blue: blue, alpha: 1) }
  }

  /**
  colorWithHue:

  - parameter hue: CGFloat

  - returns: UIColor
  */
   public func colorWithHue(hue: CGFloat) -> UIColor {
     if let hsba = self.hsba { return UIColor(hue: hue, saturation: hsba.s, brightness: hsba.b, alpha: hsba.a) }
     else { return UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1) }
   }

  /**
  colorWithSaturation:

  - parameter saturation: CGFloat

  - returns: UIColor
  */
   public func colorWithSaturation(saturation: CGFloat) -> UIColor {
     if let hsba = self.hsba { return UIColor(hue: hsba.h, saturation: saturation, brightness: hsba.b, alpha: hsba.a) }
     else { return UIColor(hue: 1, saturation: saturation, brightness: 1, alpha: 1) }
   }

  /**
  colorWithBrightness:

  - parameter brightness: CGFloat

  - returns: UIColor
  */
   public func colorWithBrightness(brightness: CGFloat) -> UIColor {
     if let hsba = self.hsba { return UIColor(hue: hsba.h, saturation: hsba.s, brightness: brightness, alpha: hsba.a) }
     else { return UIColor(hue: 1, saturation: 1, brightness: brightness, alpha: 1) }
   }

  /**
  colorWithAlpha:

  - parameter alpha: CGFloat

  - returns: UIColor
  */
  public func colorWithAlpha(alpha: CGFloat) -> UIColor { return colorWithAlphaComponent(alpha) }

  /**
  colorWithHighlight:

  - parameter highlight: CGFloat

  - returns: UIColor
  */
  public func colorWithHighlight(highlight: CGFloat) -> UIColor {
    if let rgba = self.rgba {
      return UIColor(red:   rgba.r * (1 - highlight) + highlight,
                     green: rgba.g * (1 - highlight) + highlight,
                     blue:  rgba.b * (1 - highlight) + highlight,
                     alpha: rgba.a * (1 - highlight) + highlight)
    } else {
      return self
    }
  }

  /**
  colorWithShadow:

  - parameter shadow: CGFloat

  - returns: UIColor
  */
  public func colorWithShadow(shadow: CGFloat) -> UIColor {
    if let rgba = self.rgba {
      return UIColor(red:   rgba.r * (1 - shadow),
                     green: rgba.g * (1 - shadow),
                     blue:  rgba.b * (1 - shadow),
                     alpha: rgba.a * (1 - shadow) + shadow)
    } else {
      return self
    }
  }

  /**
  blendedColorWithFraction:ofColor:

  - parameter fraction: CGFloat
  - parameter color: UIColor

  - returns: UIColor
  */
  public func blendedColorWithFraction(fraction: CGFloat, ofColor color: UIColor) -> UIColor {
    var r1: CGFloat = 1.0, g1: CGFloat = 1.0, b1: CGFloat = 1.0, a1: CGFloat = 1.0
    var r2: CGFloat = 1.0, g2: CGFloat = 1.0, b2: CGFloat = 1.0, a2: CGFloat = 1.0

    self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
    color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

    return UIColor(red: r1 * (1 - fraction) + r2 * fraction,
                   green: g1 * (1 - fraction) + g2 * fraction,
                   blue: b1 * (1 - fraction) + b2 * fraction,
                   alpha: a1 * (1 - fraction) + a2 * fraction)
  }
}
