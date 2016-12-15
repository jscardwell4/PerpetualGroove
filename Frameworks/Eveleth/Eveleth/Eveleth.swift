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

  private enum Family {
    case regular, slant, dot

    var familyName: String {
      switch self {
      case .regular:
        return "Eveleth"
      case .slant:
        return "Eveleth Slant"
      case .dot:
        return "Eveleth Dot"
      }
    }

    var fontNames: Set<String> {
      switch self {
      case .regular:
        return Set([
          "CleanRegular", "CleanShadow", "CleanThin",
          "Shapes",
          "Icons",
          "Shadow",
          "Regular-Bold", "Light", "Regular", "Thin"
          ].map { "Eveleth\($0)" }
        )
      case .slant:
        return Set(["Regular", "Regular-Bold", "Light"].map { "EvelethSlant\($0)" })
      case .dot:
        return Set(["Regular", "Regular-Bold", "Light"].map { "EvelethDot\($0)" })
      }
    }

    var fileNames: Set<String> {
      switch self {
      case .regular:
        return Set([
          "Clean Regular", "Clean Shadow", "Clean Thin",
          "Shapes",
          "Icons",
          "Shadow",
          "Regular Bold", "Light", "Regular", "Thin"
          ].map { "Yellow Design Studio - Eveleth \($0)" }
        )
      case .slant:
        return Set(["Regular", "Regular Bold", "Light"].map { "Yellow Design Studio - Eveleth Slant \($0)" })
      case .dot:
        return Set(["Regular", "Regular Bold", "Light"].map { "Yellow Design Studio - Eveleth Dot \($0)" })
      }
    }

    func fileName(for fontName: String) -> String {
      let styleName: String
      switch self {
        case .regular where fontName.hasPrefix("Eveleth"):
          styleName = fontName.substring(from: fontName.index(fontName.startIndex, offsetBy: 7))
        case .slant where fontName.hasPrefix("EvelethSlant"):
          styleName = fontName.substring(from: fontName.index(fontName.startIndex, offsetBy: 12))
        case .dot where fontName.hasPrefix("EvelethDot"):
          styleName = fontName.substring(from: fontName.index(fontName.startIndex, offsetBy: 10))
        default: return fontName
      }

      let fileNameSuffix: String
      switch styleName {
        case "CleanRegular", "CleanShadow", "CleanThin":
          fileNameSuffix = "Clean \(styleName.substring(from: styleName.index(styleName.startIndex, offsetBy: 5)))"
        case "Regular-Bold":
          fileNameSuffix = "Regular Bold"
        default:
          fileNameSuffix = styleName
      }

      return "Yellow Design Studio - \(familyName) \(fileNameSuffix)"

    }

  }

  fileprivate static var fontsRegistered = false

  public override class func initialize() { if self === Eveleth.self && !fontsRegistered { registerFonts() } }

  public class func registerFonts() {
    if !fontsRegistered {

      let unregisteredRegularFonts = Family.regular.fontNames.subtracting(UIFont.fontNames(forFamilyName: "Eveleth"))
      let unregisteredSlantFonts = Family.slant.fontNames.subtracting(UIFont.fontNames(forFamilyName: "Eveleth Slant"))
      let unregisteredDotFonts = Family.dot.fontNames.subtracting(UIFont.fontNames(forFamilyName: "Eveleth Dot"))

      var unregisteredFontFileNames: [String] = []
      unregisteredFontFileNames.append(contentsOf: unregisteredRegularFonts.map { Family.regular.fileName(for: $0) })
      unregisteredFontFileNames.append(contentsOf: unregisteredSlantFonts.map { Family.slant.fileName(for: $0) })
      unregisteredFontFileNames.append(contentsOf: unregisteredDotFonts.map { Family.dot.fileName(for: $0) })


      guard unregisteredFontFileNames.count > 0 else {
        fontsRegistered = true
        return
      }

      let bundle = Bundle(for: self)
      let fontURLs = unregisteredFontFileNames.flatMap { bundle.url(forResource: $0, withExtension: "otf") }

      var errors: Unmanaged<CFArray>?
      CTFontManagerRegisterFontsForURLs(fontURLs as CFArray, CTFontManagerScope.none, &errors)
      if let errorsArray = errors?.takeRetainedValue() as? NSArray, let errors = errorsArray as? [NSError] {
//        let error = NSError(domain: "CTFontManagerErrorDomain",
//                            code: 1,
//                        userInfo: [NSUnderlyingErrorKey: errors,
//                                   NSLocalizedDescriptionKey:"Errors encountered registering 'Eveleth' fonts"])
        print("\(errors)")
      } else {
        fontsRegistered = true
      }
    }
  }

  public class func cleanRegularFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethCleanRegular", size: size)
    //assert(font != nil)
    return font!
  }

  public class func cleanShadowFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethCleanShadow", size: size)
    //assert(font != nil)
    return font!
  }

  public class func cleanThinFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethCleanThin", size: size)
    //assert(font != nil)
    return font!
  }

  public class func dotLightFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethDotLight", size: size)
    //assert(font != nil)
    return font!
  }

  public class func dotRegularBoldFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethDotRegular-Bold", size: size)
    //assert(font != nil)
    return font!
  }

  public class func dotRegularFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethDotRegular", size: size)
    //assert(font != nil)
    return font!
  }

  public class func iconsFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethIcons", size: size)
    //assert(font != nil)
    return font!
  }

  public class func lightFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethLight", size: size)
    //assert(font != nil)
    return font!
  }

  public class func regularBoldFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethRegular-Bold", size: size)
    //assert(font != nil)
    return font!
  }

  public class func regularFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethRegular", size: size)
    //assert(font != nil)
    return font!
  }

  public class func shadowFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethShadow", size: size)
    //assert(font != nil)
    return font!
  }

  public class func shapesFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethShapes", size: size)
    //assert(font != nil)
    return font!
  }

  public class func slantLightFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethSlantLight", size: size)
    //assert(font != nil)
    return font!
  }

  public class func slantRegularBoldFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethSlantRegular-Bold", size: size)
    //assert(font != nil)
    return font!
  }

  public class func slantRegularFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethSlantRegular", size: size)
    //assert(font != nil)
    return font!
  }

  public class func thinFontWithSize(_ size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    //assert(fontsRegistered)
    let font = UIFont(name: "EvelethThin", size: size)
    //assert(font != nil)
    return font!
  }

}
