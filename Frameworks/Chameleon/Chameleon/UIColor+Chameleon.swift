//
//  UIColor+Chameleon.swift
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
import ObjectiveC
import CoreGraphics
import QuartzCore

private(set) var gradientImageKey = "gradientImage"

public func rgba(r: Int, _ g: Int, _ b: Int, _ a: Int) -> UIColor {
  return UIColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: CGFloat(a)/255)
}

public func rgb(r: Int, _ g: Int, _ b: Int) -> UIColor {
  return UIColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
}

public func hsba(h: Int, _ s: Int, _ b: Int, _ a: Int) -> UIColor {
  return UIColor(hue: CGFloat(h)/360, saturation: CGFloat(s)/100, brightness: CGFloat(b)/100, alpha: CGFloat(a)/100)
}

public func hsb(h: Int, _ s: Int, _ b: Int) -> UIColor {
  return UIColor(hue: CGFloat(h)/360, saturation: CGFloat(s)/100, brightness: CGFloat(b)/100, alpha: 1)
}

public func hsbToRGB(h: Int, _ s: Int, _ b: Int) -> (r: Int, g: Int, b: Int) {

  let s = CGFloat(s) / 100
  let b = CGFloat(b) / 100
  let c = s * b
  let hPrime = CGFloat(h) / 60
  let x = c * (1 - abs(fmod(hPrime, 2) - 1))

  let (r1, g1, b1): (CGFloat, CGFloat, CGFloat)
  switch hPrime {
  case 0 ..< 1: (r1, g1, b1) = (c, x, 0)
  case 1 ..< 2: (r1, g1, b1) = (x, c, 0)
  case 2 ..< 3: (r1, g1, b1) = (0, c, x)
  case 3 ..< 4: (r1, g1, b1) = (0, x, c)
  case 4 ..< 5: (r1, g1, b1) = (x, 0, c)
  case 5 ..< 6: (r1, g1, b1) = (c, 0, x)
  default:      (r1, g1, b1) = (0, 0, 0)
  }

  let m = b - c
  return (r: Int((r1 + m) * 255), g: Int((g1 + m) * 255), b: Int((b1 + m) * 255))
}

public func rgbToHSB(r: Int, _ g: Int, _ b: Int) -> (h: Int, s: Int, b: Int) {
  let r = CGFloat(r) / 255, g = CGFloat(g) / 255, b = CGFloat(b) / 255
  let M = max(r, g, b)
  let m = min(r, g, b)
  let c = M - m
  let hPrime: CGFloat
  switch (c, M) {
  case (0, _): hPrime = 0
  case (_, r): hPrime = fmod((g - b) / c, 6)
  case (_, g): hPrime = (b - r) / c + 2
  case (_, b): hPrime = (r - g) / c + 4
  default:     hPrime = 0
  }
  let h = Int(60 * hPrime)
  let v = Int(M * 100)
  let s = Int(v == 0 ? 0 : c / M * 100)
  return (h: h, s: s, b: v)
}

public func rgbTosRGB(r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
  func convert(c: CGFloat) -> CGFloat { return c > 0.04045 ? pow((c + 0.055) / 1.055, 2.4) : c / 12.92 }
  return (r: convert(r), g: convert(g), b: convert(b))
}

public func sRGBToXYZ(r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> (x: CGFloat, y: CGFloat, z: CGFloat) {
  let x = (r * 0.4124 + g * 0.3576 + b * 0.1805) * 100.0
  let y = (r * 0.2126 + g * 0.7152 + b * 0.0722) * 100.0
  let z = (r * 0.0193 + g * 0.1192 + b * 0.9505) * 100.0
  return (x: x, y: y, z: z)
}

public func rgbToXYZ(var r: CGFloat, var _ g: CGFloat, var _ b: CGFloat) -> (x: CGFloat, y: CGFloat, z: CGFloat) {
  (r, g, b) = rgbTosRGB(r, g, b)
  return sRGBToXYZ(r, g, b)
}

public func rgbToLAB(r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> (l: CGFloat, a: CGFloat, b: CGFloat) {
  let (x, y, z) = rgbToXYZ(r, g, b)
  return xyzToLAB(x, y, z)
}

public func xyzToLAB(var x: CGFloat, var _ y: CGFloat, var _ z: CGFloat) -> (l: CGFloat, a: CGFloat, b: CGFloat) {
  // The corresponding original XYZ values are such that white is D65 with unit luminance (X,Y,Z = 0.9505, 1.0000, 1.0890).
  // Calculations are also to assume the 2° standard colorimetric observer.
  // D65: http://en.wikipedia.org/wiki/CIE_Standard_Illuminant_D65
  // Standard Colorimetric Observer: http://en.wikipedia.org/wiki/Standard_colorimetric_observer#CIE_standard_observer
  // Since we mutiplied our XYZ values by 100 to produce a percentage we should also multiply our unit luminance values
  // by 100.
  x /= 95.05; y /= 100.0; z /= 108.9

  // Use the forward transformation function for CIELAB-CIEXYZ conversions
  // Function: http://upload.wikimedia.org/math/e/5/1/e513d25d50d406bfffb6ed3c854bd8a4.png
  // 0.0088564517 = pow(6.0 / 29.0, 3.0)
  // 7.787037037 = 1.0 / 3.0 * pow(29.0 / 6.0, 2.0)
  // 0.1379310345 = 4.0 / 29.0
  func convert(f: CGFloat) -> CGFloat { return f > 0.0088564517 ? pow(f, 1.0 / 3.0) : 7.787037037 * f + 0.1379310345 }
  (x, y, z) = (convert(x), convert(y), convert(z))
  return (l: 116.0 * y - 16.0, a: 500.0 * (x - y), b: 200.0 * (y - z))
}

public func labToXYZ(l: CGFloat, _ a: CGFloat, _ b: CGFloat) -> (x: CGFloat, y: CGFloat, z: CGFloat) {
  var y1 = (l + 16)/116
  var x1 = a/500 + y1
  var z1 = -b/200 + y1
  func convert(f: CGFloat) -> CGFloat { return f > 0.206893 ? pow(f, 3) : (f - 16/116)/7.787 }
  x1 = convert(x1); y1 = convert(y1); z1 = convert(z1)
  return (x: x1 * 95.05, y: y1 * 100, z: z1 * 108.9)
}

public func xyzTosRGB(x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
  let r = (3.2406 * x - 1.5372 * y - 0.4986 * z)/100
  let g = (-0.9689 * x + 1.8758 * y + 0.0415 * z)/100
  let b = (0.0557 * x - 0.204 * y + 1.057 * z) / 100
  return (r: r, g: g, b: b)
}

public func sRGBToRGB(r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
  func convert(f: CGFloat) -> CGFloat { return f > 0.0031308 ? 1.055 * pow(f, 1/2.4) - 0.055 : 12.92 * f }
  return (r: convert(r), g: convert(g), b: convert(b))
}

public func xyzToRGB(x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
  let (r, g, b) = xyzTosRGB(x, y, z)
  return sRGBToRGB(r, g, b)
}

public func labToRGB(l: CGFloat, _ a: CGFloat, _ b: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
  let (x, y, z) = labToXYZ(l, a, b)
  return xyzToRGB(x, y, z)
}

public func hexStringFromRGB(r: Int, _ g: Int, _ b: Int) -> String {
  assert((0...255).contains(r) && (0...255).contains(g) && (0...255).contains(b), "rgb values expected to be in the range 0...255")
  let hex = (r << 16) | (g << 8) | b
  var string = String(hex, radix: 16, uppercase: false)
  while string.characters.count < 6 { string.insert(Character("0"), atIndex: string.startIndex) }
  string.insert(Character("#"), atIndex: string.startIndex)
  return string
}

public func hexStringFromHSB(h: Int, _ s: Int, _ b: Int) -> String {
  let (r, g, b) = hsbToRGB(h, s, b)
  return hexStringFromRGB(r, g, b)
}

extension UIColor {

  public var gradientImage: UIImage! {
    get { return objc_getAssociatedObject(self, &gradientImageKey) as? UIImage }
    set { objc_setAssociatedObject(self, &gradientImageKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  public var RGB: (r: CGFloat, g: CGFloat, b: CGFloat) {
    let (r, g, b, _) = RGBA
    return (r: r, g: g, b: b)
  }

  public var RGBA: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
    var r = CGFloat(), g = CGFloat(), b = CGFloat(), a = CGFloat()
    getRed(&r, green: &g, blue: &b, alpha: &a)
    return (r: r, g: g, b: b, a: a)
  }

  public var HSB: (h: CGFloat, s: CGFloat, b: CGFloat) {
    let (h, s, b, _) = HSBA
    return (h: h, s: s, b: b)
  }

  public var HSBA: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
    var h = CGFloat(), s = CGFloat(), b = CGFloat(), a = CGFloat()
    getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    return (h: h, s: s, b: b, a: a)
  }

  public var sRGB: (r: CGFloat, g: CGFloat, b: CGFloat) {
    let (r, g, b, _) = sRGBA
    return (r: r, g: g, b: b)
  }

  public var sRGBA: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
    var (r, g, b, a) = RGBA
    (r, g, b) = rgbTosRGB(r, g, b)
    return (r: r, g: g, b: b, a: a)
  }

  public var XYZ: (x: CGFloat, y: CGFloat, z: CGFloat) {
    let (x, y, z, _) = XYZA
    return (x: x, y: y, z: z)
  }

  public var XYZA: (x: CGFloat, y: CGFloat, z: CGFloat, a: CGFloat) {
    let (r, g, b, a) = sRGBA
    let (x, y, z) = sRGBToXYZ(r, g, b)
    return (x: x, y: y, z: z, a: a)
  }

  public var LAB: (l: CGFloat, a: CGFloat, b: CGFloat) {
    let (l, a, b, _) = LABA
    return (l: l, a: a, b: b)
  }

  public var LABA: (l: CGFloat, a: CGFloat, b: CGFloat, alpha: CGFloat) {
    let (x, y, z, alpha) = XYZA
    let (l, a, b) = xyzToLAB(x, y, z)
    return (l: l, a: a, b: b, alpha)
  }

  /**
  Calculate the total sum of differences - Euclidian distance
  Chameleon is now using the CIEDE2000 formula to calculate distances between 2 colors.
  More info: http://en.wikipedia.org/wiki/Color_difference

  - parameter l1: CGFloat
  - parameter l2: CGFloat
  - parameter a1: CGFloat
  - parameter a2: CGFloat
  - parameter b1: CGFloat
  - parameter b2: CGFloat

  - returns: CGFloat
  */
  public static func totalSumOfDifferencesFromL1(l1: CGFloat,
                                              L2 l2: CGFloat,
                                              A1 a1: CGFloat,
                                              A2 a2: CGFloat,
                                              B1 b1: CGFloat,
                                              B2 b2: CGFloat) -> CGFloat
  {

    //Get C Values in LCH from LAB Values
    let c1 = CGFloat(sqrt(pow(a1, 2) + pow(b1, 2)))
    let c2 = CGFloat(sqrt(pow(a2, 2) + pow(b2, 2)))

    //CIE Weights
    let kL = CGFloat(1)
    let kC = CGFloat(1)
    let kH = CGFloat(1)

    //Variables specifically set for CIE:2000
    let deltaPrimeL = CGFloat(l2 - l1)
    let meanL       = CGFloat(((l1 + l2)/2))
    let meanC       = CGFloat(((c1 + c2)/2))
    let a1Prime     = CGFloat(a1 + a1/2 * CGFloat(1 - sqrt(pow(meanC, 7) / (pow(meanC, 7) + pow(25, 7)))))
    let a2Prime     = CGFloat(a2 + a2/2 * CGFloat(1 - sqrt(pow(meanC, 7) / (pow(meanC, 7) + pow(25, 7)))))
    let c1Prime     = sqrt(pow(a1Prime, 2) + pow(b1, 2))
    let c2Prime     = sqrt(pow(a2Prime, 2) + pow(b2, 2))
    let deltaPrimeC = c1Prime - c2Prime
    let deltaC      = c1 - c2
    let meanCPrime  = CGFloat((c1Prime + c2Prime)/2)
    let h1Prime     = CGFloat(fmodf(Float(atan2(b1, a1Prime)), Float(360) * Float(M_PI) / Float(180)))
    let h2Prime     = CGFloat(fmodf(Float(atan2(b2, a2Prime)), Float(360) * Float(M_PI) / Float(180)))

    //Run everything through our △H' Function
    let hDeltaPrime: CGFloat
    if fabs(h1Prime - h2Prime) <= CGFloat(180 * M_PI/180) { hDeltaPrime = h2Prime - h1Prime }
    else if h2Prime <= h1Prime                       { hDeltaPrime = (h2Prime - h1Prime) + CGFloat((360 * M_PI/180)) }
    else                                             { hDeltaPrime = (h2Prime - h1Prime) - CGFloat((360 * M_PI/180)) }

    let deltaHPrime = CGFloat(2 * (sqrt(c1Prime*c2Prime)) * sin(hDeltaPrime/2))

    //Get Mean H' Value
    let meanHPrime: CGFloat
    if fabs(h1Prime-h2Prime) > CGFloat(180 * M_PI/180) { meanHPrime = (h1Prime + h2Prime + CGFloat(360 * M_PI / 180))/2 }
    else { meanHPrime = (h1Prime + h2Prime)/2 }

    var t = CGFloat(1)
    t -= CGFloat(0.17 * cos(meanHPrime - CGFloat(30 * M_PI/180)))
    t += CGFloat(0.24 * cos(2 * meanHPrime))
    t += CGFloat(0.32 * cos(3 * meanHPrime + CGFloat(6 * M_PI/180)))
    t -= CGFloat(0.20 * cos(4 * meanHPrime - CGFloat(63 * M_PI/180)))


    let sL = CGFloat(1 + (0.015 * pow((meanL - 50), 2))/sqrt(20.0 + pow((meanL - 50.0), 2)))
    let sC = CGFloat(1 + 0.045 * meanCPrime)
    let sH = CGFloat(1 + 0.015 * meanCPrime * t)

    let rT = CGFloat(
      -2 * CGFloat(sqrt(pow(meanCPrime, 7) / CGFloat(pow(meanCPrime, 7))
      + pow(25, 7))) * sin(CGFloat(60 * M_PI/180) * exp(-1 * pow((meanCPrime - CGFloat(275 * M_PI/180))/CGFloat(25 * M_PI/180), 2)))
    )


    //Get total difference
    let totalDifference = CGFloat(
      sqrt(pow(CGFloat(deltaPrimeL / (kL * sL)), 2)
      + pow(CGFloat(deltaPrimeC / (kC * sC)), 2)
      + pow(CGFloat(deltaHPrime / (kH * sH)), 2)
      + rT * CGFloat(deltaC / CGFloat(kC * sC)) * CGFloat(deltaHPrime / CGFloat(kH * sH)))
    )

    return totalDifference
  }

  /** The color's relative luminance */
  public var luminance: CGFloat {
    var (red, green, blue, _) = rgbColor.RGBA

    // Relative luminance in colorimetric spaces - http://en.wikipedia.org/wiki/Luminance_(relative)
    red *= 0.2126; green *= 0.7152; blue *= 0.0722
    return red + green + blue
  }

  /// The color if it is not a pattern-based color, otherwise a derived rgb color from the pattern-based color
  public var rgbColor: UIColor {
    if CGColorGetPattern(self.CGColor) == nil { return self }

    //Let's find the average color of the image and contrast against that.
    let size = CGSize(width: 1, height: 1)

    //Create a 1x1 bitmap context
    UIGraphicsBeginImageContext(size)
    let ctx = UIGraphicsGetCurrentContext()

    //Set the interpolation quality to medium
    CGContextSetInterpolationQuality(ctx, .Medium)

    //Draw image scaled down to this 1x1 pixel
    gradientImage.drawInRect(CGRect(origin: CGPoint.zero, size: size), blendMode: .Copy, alpha:1)

    //Read the RGB values from the context's buffer
    let data = UnsafePointer<UInt8>(CGBitmapContextGetData(ctx))
    let result = UIColor(red: CGFloat(data[2]) / 255, green: CGFloat(data[1]) / 255, blue: CGFloat(data[0]) / 255, alpha: 1)

    UIGraphicsEndImageContext()
    return result
  }

  /// The nearest flat color for the color
  public var flatColor: UIColor {
    let (l1, a1, b1) = rgbColor.LAB
    let flatColors = Chameleon.flatColors.lazy
    let totalDifferences = flatColors.map { color -> CGFloat in
      let (l2, a2, b2) = color.LAB
      return UIColor.totalSumOfDifferencesFromL1(l1, L2: l2, A1: a1, A2: a2, B1: b1, B2: b2)
    }
    let color = zip(flatColors, totalDifferences).reduce((UIColor.clearColor(), CGFloat.max), combine: {$0.1 < $1.1 ? $0 : $1}).0
    return color
  }

  /// A complementary color object 180 degrees away in the HSB colorspace
  public var complementaryColor: UIColor {

    var (hue, saturation, brightness, alpha) = rgbColor.HSBA

    //Multiply our value by their max values to convert
    hue *= 360; saturation *= 100; brightness *= 100

    //Select a color with a hue 180 degrees away on the colorwheel (i.e. for 50 it would be 230).
    hue += 180
    if hue > 360 { hue -= 360 }

    //Round to the nearest whole number after multiplying
    hue = round(hue)
    saturation = round(saturation)
    brightness = round(brightness)

    //Retrieve LAB values from our complimentary nonflat color & return nearest flat color
    return hsba(Int(hue), Int(saturation), Int(brightness), Int(alpha * 100))
  }

  /// A complementary flat color object 180 degrees away in the HSB colorspace
  public var complementaryFlatColor: UIColor { return complementaryColor.flatColor }

  /// White or black based on the color's luminance
  public var contrastingColor: UIColor {
    return luminance > 0.5
             ? UIColor(white: 0, alpha: CGColorGetAlpha(CGColor))
             : UIColor(white: 1, alpha: CGColorGetAlpha(CGColor))
  }

  /// White or black flat color based on the color's luminance
  public var contrastingFlatColor: UIColor { return contrastingColor.flatColor }

  // MARK: - Random Color Methods

  public typealias Shade = Chameleon.FlatColor.Shade

  /**
  Returns a randomly generated flat color object with an alpha value of 1.0 in either a light or dark shade.

  - parameter shadeStyle: Shade = .Any

  - returns: UIColor
  */
  public static func randomFlatColor(shadeStyle: Shade = .Any) -> UIColor {

    // Get color array based on shade style
    let colors = Array(shadeStyle.colors)

    // Helper function to generate an appropriate random number
    func randomColorIndex() -> Int { return Int(arc4random_uniform(UInt32(colors.count))) }

    let defaults = NSUserDefaults.standardUserDefaults()
    let key = "Chameleon.RandomColorIndex"

    //Chose one of those colors at random
    var index: Int

    //Check if a previous random number exists
    let previous = defaults.integerForKey(key)

    //Keep generating a random number until it is different than the one generated last time
    repeat { index = randomColorIndex() } while previous == index

    defaults.setInteger(randomColorIndex(), forKey: key)
    defaults.synchronize()

    return colors[index]

  }

}
