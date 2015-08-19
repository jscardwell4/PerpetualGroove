//
//  Eveleth.swift
//  Eveleth
//
//  Created by Jason Cardwell on 8/6/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//


import class Foundation.NSBundle
import class Foundation.NSURL
import class UIKit.UIFont
import CoreText

public final class Eveleth: NSObject {

  private static var fontsRegistered = false

  /** initialize */
  public override class func initialize() { if self === Eveleth.self && !fontsRegistered { registerFonts() } }

  /** registerFonts */
  public class func registerFonts() {
    if !fontsRegistered {
      fontsRegistered = true
      let styles = [
        "Clean Regular", "Clean Shadow", "Clean Thin", "Dot Light", "Dot Regular Bold", "Dot Regular", "Icons",
        "Light", "Regular Bold", "Regular", "Shadow", "Shapes", "Slant Light", "Slant Regular Bold", "Slant Regular", "Thin"
      ]
      let fontNames = styles.map { "Yellow Design Studio - Eveleth \($0)" }
      let bundle = NSBundle(forClass: self)
      let fontURLs = fontNames.flatMap { bundle.URLForResource($0, withExtension: "otf") }
      var errors: Unmanaged<CFArray>?
      CTFontManagerRegisterFontsForURLs(fontURLs, CTFontManagerScope.None, &errors)
      if let errorsArray = errors?.takeRetainedValue() as? NSArray, errors = errorsArray as? [NSError] {
        let error = NSError(domain: "CTFontManagerErrorDomain",
                            code: 1,
                        userInfo: [NSUnderlyingErrorKey: errors,
                                   NSLocalizedDescriptionKey:"Errors encountered registering 'Eveleth' fonts"])
        NSLog("\(error)")
      }
    }
  }

  /**
  cleanRegularFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func cleanRegularFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethCleanRegular", size: size)
    assert(font != nil)
    return font!
  }

  /**
  cleanShadowFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func cleanShadowFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethCleanShadow", size: size)
    assert(font != nil)
    return font!
  }

  /**
  cleanThinFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func cleanThinFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethCleanThin", size: size)
    assert(font != nil)
    return font!
  }

  /**
  dotLightFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func dotLightFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethDotLight", size: size)
    assert(font != nil)
    return font!
  }

  /**
  dotRegularBoldFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func dotRegularBoldFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethDotRegular-Bold", size: size)
    assert(font != nil)
    return font!
  }

  /**
  dotRegularFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func dotRegularFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethDotRegular", size: size)
    assert(font != nil)
    return font!
  }

  /**
  iconsFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func iconsFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethIcons", size: size)
    assert(font != nil)
    return font!
  }

  /**
  lightFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func lightFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethLight", size: size)
    assert(font != nil)
    return font!
  }

  /**
  regularBoldFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func regularBoldFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethRegular-Bold", size: size)
    assert(font != nil)
    return font!
  }

  /**
  regularFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func regularFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethRegular", size: size)
    assert(font != nil)
    return font!
  }

  /**
  shadowFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func shadowFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethShadow", size: size)
    assert(font != nil)
    return font!
  }

  /**
  shapesFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func shapesFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethShapes", size: size)
    assert(font != nil)
    return font!
  }

  /**
  slantLightFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func slantLightFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethSlantLight", size: size)
    assert(font != nil)
    return font!
  }

  /**
  slantRegularBoldFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func slantRegularBoldFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethSlantRegular-Bold", size: size)
    assert(font != nil)
    return font!
  }

  /**
  slantRegularFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func slantRegularFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethSlantRegular", size: size)
    assert(font != nil)
    return font!
  }

  /**
  thinFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func thinFontWithSize(size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let font = UIFont(name: "EvelethThin", size: size)
    assert(font != nil)
    return font!
  }

}