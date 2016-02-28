//
//  Chameleon.swift
//  Chameleon
//
//  Created by Jason Cardwell on 5/11/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

/*

The MIT License (MIT)

Copyright (c) 2014-2015 Vicc Alexander.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

import Foundation
import UIKit
import CoreGraphics

protocol ColorBaseType {
  var name: String { get }
  static var all: [Self] { get }
}

protocol ColorType {
  associatedtype BaseType: ColorBaseType
  var shade: Chameleon.Shade { get }
  var base: BaseType { get }
  var name: String { get }
  static var all: [Self] { get }
  static var allLight: [Self] { get }
  static var allDark: [Self] { get }
  static var lightColors: [String:UIColor] { get }
  static var darkColors: [String:UIColor] { get }
  var color: UIColor { get }
  init(base: BaseType, shade: Chameleon.Shade)
  init?(name: String, shade: Chameleon.Shade)
}


public final class Chameleon {

  // MARK: - ColorScheme type

  /** Color schemes with which to select colors using a specified color. */
  public enum ColorScheme: Int, CustomStringConvertible {
    /**
    Analogous color schemes use colors that are next to each other on the color wheel. They usually match well and create serene
    and comfortable designs. Analogous color schemes are often found in nature and are harmonious and pleasing to the eye. Make
    sure you have enough contrast when choosing an analogous color scheme. Choose one color to dominate, a second to support.
    The third color is used (along with black, white or gray) as an accent.
     */
    case Analogous
    /**
    Colors that are opposite each other on the color wheel are considered to be complementary colors (example: red and green).
    The high contrast of complementary colors creates a vibrant look especially when used at full saturation. This color scheme
    must be managed well so it is not jarring. Complementary colors are tricky to use in large doses, but work well when you
    want something to stand out. Complementary colors are really bad for text.
     */
    case Triadic
    /**
    A triadic color scheme uses colors that are evenly spaced around the color wheel. Triadic color harmonies tend to be quite
    vibrant, even if you use pale or unsaturated versions of your hues. To use a triadic harmony successfully, the colors should
    be carefully balanced - let one color dominate and use the two others for accent.
     */
    case Complementary

    public var description: String {
      switch self {
        case .Analogous: return "Analogous"
        case .Triadic: return "Triadic"
        case .Complementary: return "Complementary"
      }
    }

    public static var all: [ColorScheme] { return [.Analogous, .Triadic, .Complementary] }
  }

  // MARK: - Shade type

  /** Defines the shade of a any flat color. */
  public enum Shade: Int {
    case Light /** Returns the light shade version of a flat color. */
    case Dark  /** Returns the dark shade version of a flat color. */
    case Any  /** Returns either a light or dark version of a flat color */

    public var colors: AnySequence<UIColor> {
      switch self {
        case .Light: return AnySequence(Chameleon.lightColors)
        case .Dark:  return AnySequence(Chameleon.darkColors)
        case .Any:   return Chameleon.flatColors
      }
    }
  }

  // MARK: - GradientStyle type

  /** Defines the gradient style and direction of the gradient color. */
  public enum GradientStyle: Int, CustomStringConvertible {
    /**
    Returns a gradual blend between colors originating at the leftmost point of an object's frame, and ending at the rightmost
    point of the object's frame.
    */
    case LeftToRight

    /**
    Returns a gradual blend between colors originating at the center of an object's frame, and ending at all edges of the
    object's frame. NOTE: Supports a Maximum of 2 Colors.
    */
    case Radial

    /**
    Returns a gradual blend between colors originating at the topmost point of an object's frame, and ending at the bottommost
    point of the object's frame.
    */
    case TopToBottom

    public var description: String {
      switch self {
          case .LeftToRight: return "LeftToRight"
          case .Radial:      return "Radial"
          case .TopToBottom: return "TopToBottom"
      }
    }

    public static var all: [GradientStyle] { return [.LeftToRight, .Radial, .TopToBottom] }
  }

  // MARK: - ColorPalette type

  /** Represents the collection of colors to use when inputting colors */
  public enum ColorPalette: Int, CustomStringConvertible {
    case Flat, CSS, Darcula, QuietLight, Kelley
    public var description: String {
      switch self {
        case .Flat:       return "Flat"
        case .CSS:        return  "CSS"
        case .Darcula:    return "Darcula"
        case .QuietLight: return "QuietLight"
        case .Kelley:     return "Kelley"
      }
    }
    public static var all: [ColorPalette] { return [.Flat, .CSS, .Darcula, .QuietLight, Kelley] }
  }

  // MARK: - UIStatusBar Methods
  /**
  statusBarStyleForColor:

  - parameter backgroundColor: UIColor

  - returns: UIStatusBarStyle
  */
  public static func statusBarStyleForColor(backgroundColor: UIColor) -> UIStatusBarStyle {
    var luminance = CGFloat(), red = CGFloat(), green = CGFloat(), blue = CGFloat()
    if backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: nil) {

      //Relative luminance in colorimetric spaces - http://en.wikipedia.org/wiki/Luminance_(relative)
      red *= 0.2126; green *= 0.7152; blue *= 0.0722
      luminance = red + green + blue

      return luminance > 0.5 ? .Default : .LightContent
    } else {
      return .Default
    }
  }

  // MARK: - Color Scheme Methods

  /**
  colorsForScheme:with:flat:

  - parameter scheme: ColorScheme
  - parameter color: UIColor
  - parameter flat: Bool

  - returns: [UIColor]
  */
  public static func colorsForScheme(scheme: ColorScheme, with color: UIColor, flat: Bool, unique: Bool = false) -> [UIColor] {

    // Helper for modifying hue value
    func add(newValue: CGFloat, currentValue: CGFloat) -> CGFloat {
      switch currentValue + newValue {
        case let v where v > 360: return v - 360
        case let v where v < 0:   return -v
        case let v:                 return v
      }
    }

    //Extract HSB values from input color
    var h = CGFloat(), s = CGFloat(), b = CGFloat(), a = CGFloat()
    color.getHue(&h, saturation: &s, brightness:&b, alpha:&a)

    //Multiply our values by the max value to convert
    h *= 360; s *= 100; b *= 100

    var colors: [UIColor]

    //Choose Between Schemes
    switch scheme {
      case .Analogous:
        colors = [
          UIColor(hue: add(-32, currentValue: h)/360, saturation: (s + 5)/100, brightness: (b + 5)/100, alpha: 1),
          UIColor(hue: add(-16, currentValue: h)/360, saturation: (s + 5)/100, brightness: (b + 9)/100, alpha: 1),
          UIColor(hue: h/360, saturation: s/100, brightness: b/100, alpha: 1),
          UIColor(hue: add(16, currentValue: h)/360, saturation: (s + 5)/100, brightness: (b + 9)/100, alpha: 1),
          UIColor(hue: add(32, currentValue: h)/360, saturation: (s + 5)/100, brightness: (b + 5)/100, alpha: 1)
        ]
      case .Complementary:
        colors = [
          UIColor(hue: h/360, saturation: (s + 5)/100, brightness: (b - 30)/100, alpha: 1),
          UIColor(hue: h/360, saturation: (s - 10)/100, brightness: (b + 9)/100, alpha: 1),
          UIColor(hue: h/360, saturation: s/100, brightness: b/100, alpha: 1),
          UIColor(hue: add(180, currentValue: h)/360, saturation: s/100, brightness: b/100, alpha: 1),
          UIColor(hue: add(180, currentValue: h)/360, saturation: (s + 20)/100, brightness: (b - 30)/100, alpha: 1)
        ]
      case .Triadic:
        colors = [
          UIColor(hue: add(120, currentValue: h)/360, saturation: (7 * s/6)/100, brightness: (b - 5)/100, alpha: 1),
          UIColor(hue: add(120, currentValue: h)/360, saturation: s/100, brightness: (b + 9)/100, alpha: 1),
          UIColor(hue: h/360, saturation: s/100, brightness: b/100, alpha: 1),
          UIColor(hue: add(240, currentValue: h)/360, saturation: (7 * s/6)/100, brightness: (b - 5)/100, alpha: 1),
          UIColor(hue: add(240, currentValue: h)/360, saturation: s/100, brightness: (b - 30)/100, alpha: 1)
        ]
    }

    if flat { colors = colors.map {$0.flatColor} }

    if unique { colors = Array(Set(colors)) }

    return colors
  }


  /**
  gradientWithStyle:withFrame:andColors:

  - parameter style: GradientStyle
  - parameter frame: CGRect
  - parameter colors: [UIColor]

  - returns: UIColor
  */
  public static func gradientWithStyle(style: GradientStyle, withFrame frame:CGRect, andColors colors: [UIColor]) -> UIColor {

    if colors.count == 1 { return colors[0] }
    else if colors.count == 0 { return UIColor.clearColor() }

    //Create our background gradient layer
    let backgroundGradientLayer = CAGradientLayer()

    //Set the frame to our object's bounds
    backgroundGradientLayer.frame = frame

    let cgColors = colors.map {$0.CGColor}
    let backgroundColorImage: UIImage

    switch style {
      case .LeftToRight:
        //Specify the direction our gradient will take
        backgroundGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        backgroundGradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        fallthrough
      case .TopToBottom:
        //Set out gradient's colors
        backgroundGradientLayer.colors = cgColors

        //Convert our CALayer to a UIImage object
        UIGraphicsBeginImageContextWithOptions(backgroundGradientLayer.bounds.size, false, UIScreen.mainScreen().scale)
        backgroundGradientLayer.renderInContext(UIGraphicsGetCurrentContext()!)
        backgroundColorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
      case .Radial:
        UIGraphicsBeginImageContextWithOptions(frame.size, false, UIScreen.mainScreen().scale)
        //Specific the spread of the gradient (For now this gradient only takes 2 locations)
        var locations: [CGFloat] = [0.0, 1.0]
        //Create our Fradient
        let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), Array(cgColors[0...1]), &locations)
        // Normalise the 0-1 ranged inputs to the width of the image
        let point = CGPoint(x: 0.5 * frame.width, y: 0.5 * frame.height)
        let radius = min(frame.width, frame.height)
        let context = UIGraphicsGetCurrentContext()
        // Draw our Gradient
        CGContextDrawRadialGradient(context, gradient, point, 0, point, radius, .DrawsAfterEndLocation)
        // Grab it as an Image
         backgroundColorImage = UIGraphicsGetImageFromCurrentImageContext()
        // Clean up
        UIGraphicsEndImageContext()
    }

    let color = UIColor(patternImage: backgroundColorImage)
    color.gradientImage = backgroundColorImage
    return color

  }


}

