//
//  Triump.swift
//  Triump
//
//  Created by Jason Cardwell on 8/6/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//


import class Foundation.NSBundle
import class Foundation.NSURL
import class UIKit.UIFont
import class UIKit.UIFontDescriptor
import CoreText

public final class Triump: NSObject {

  private static var fontsRegistered = false

  /** initialize */
  public override class func initialize() { if self === Triump.self && !fontsRegistered { registerFonts() } }

  /** registerFonts */
  public class func registerFonts() {
    if !fontsRegistered {
      fontsRegistered = true
      let styles = [
        "Blur-01", "Blur-02", "Blur-03", "Blur-04", "Blur-05", "Blur-06",
        "Blur-07", "Blur-08", "Blur-09", "Blur-10", "Blur-11", "Blur-12",
        "Extras", "Ornaments",
        "Rock-01", "Rock-02", "Rock-03", "Rock-04", "Rock-05", "Rock-06",
        "Rock-07", "Rock-08", "Rock-09", "Rock-10", "Rock-11", "Rock-12"
      ]
      let fontNames = styles.map { "Latinotype - Triump-Rg-\($0)" }
      let bundle = NSBundle(forClass: self)
      let fontURLs = fontNames.flatMap { bundle.URLForResource($0, withExtension: "otf") }
      var errors: Unmanaged<CFArray>?
      CTFontManagerRegisterFontsForURLs(fontURLs, CTFontManagerScope.None, &errors)
      if let errorsArray = errors?.takeRetainedValue() as? NSArray, errors = errorsArray as? [NSError] {
        let error = NSError(domain: "CTFontManagerErrorDomain",
                            code: 1,
                        userInfo: [NSUnderlyingErrorKey: errors,
                                   NSLocalizedDescriptionKey:"Errors encountered registering 'Triump' fonts"])
        NSLog("\(error)")
      }
    }
  }

  public enum Font {

    case Blur (BlurFace)
    case Rock (RockFace)
    case Ornaments
    case Extras

    public enum BlurFace: String {
      case One    = "01"
      case Two    = "02"
      case Three  = "03"
      case Four   = "04"
      case Five   = "05"
      case Six    = "06"
      case Seven  = "07"
      case Eight  = "08"
      case Nine   = "09"
      case Ten    = "10"
      case Eleven = "11"
      case Twelve = "12"
    }

    public enum RockFace: String {
      case One    = "01"
      case Two    = "02"
      case Three  = "03"
      case Four   = "04"
      case Five   = "05"
      case Six    = "06"
      case Seven  = "07"
      case Eight  = "08"
      case Nine   = "09"
      case Ten    = "10"
      case Eleven = "11"
      case Twelve = "12"
    }

    var name: (family: String, face: String) {
      switch self {
        case .Blur(let face): return ("Triump Rg Blur", face.rawValue)
        case .Rock(let face): return ("Triump Rg Rock", face.rawValue)
        case .Ornaments:      return ("Triump Rg Ornaments", "Ornaments")
        case .Extras:         return ("Triump Rg Extras", "Extras")
      }
    }
  }

  /**
  fontFor:withSize:

  - parameter font: Font
  - parameter size: CGFloat

  - returns: UIFont
  */
  private class func fontFor(font: Font, withSize size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)
    let (family, face) = font.name
    let descriptor = UIFontDescriptor(fontAttributes: [
      UIFontDescriptorFamilyAttribute: family,
      UIFontDescriptorFaceAttribute: face
    ])
    return UIFont(descriptor: descriptor, size: size)
  }

  /**
  blur1FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func blur1FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Blur(.One), withSize: size) }

  /**
  blur2FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func blur2FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Blur(.Two), withSize: size) }

  /**
  blur3FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func blur3FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Blur(.Three), withSize: size) }

  /**
  blur4FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func blur4FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Blur(.Four), withSize: size) }

  /**
  blur5FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func blur5FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Blur(.Five), withSize: size) }

  /**
  blur6FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func blur6FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Blur(.Six), withSize: size) }

  /**
  blur7FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func blur7FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Blur(.Seven), withSize: size) }

  /**
  blur8FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func blur8FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Blur(.Eight), withSize: size) }

  /**
  blur9FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func blur9FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Blur(.Nine), withSize: size) }

  /**
  blur10FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func blur10FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Blur(.Ten), withSize: size) }

  /**
  blur11FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func blur11FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Blur(.Eleven), withSize: size) }

  /**
  blur12FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func blur12FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Blur(.Twelve), withSize: size) }

  /**
  rock1FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func rock1FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Rock(.One), withSize: size) }

  /**
  rock2FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func rock2FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Rock(.Two), withSize: size) }

  /**
  rock3FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func rock3FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Rock(.Three), withSize: size) }

  /**
  rock4FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func rock4FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Rock(.Four), withSize: size) }

  /**
  rock5FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func rock5FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Rock(.Five), withSize: size) }

  /**
  rock6FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func rock6FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Rock(.Six), withSize: size) }

  /**
  rock7FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func rock7FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Rock(.Seven), withSize: size) }

  /**
  rock8FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func rock8FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Rock(.Eight), withSize: size) }

  /**
  rock9FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func rock9FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Rock(.Nine), withSize: size) }

  /**
  rock10FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func rock10FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Rock(.Ten), withSize: size) }

  /**
  rock11FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func rock11FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Rock(.Eleven), withSize: size) }

  /**
  rock12FontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func rock12FontWithSize(size: CGFloat) -> UIFont { return fontFor(.Rock(.Twelve), withSize: size) }

  /**
  ornamentsFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func ornamentsFontWithSize(size: CGFloat) -> UIFont { return fontFor(.Ornaments, withSize: size) }

  /**
  extrasFontWithSize:

  - parameter size: CGFloat

  - returns: UIFont
  */
  public class func extrasFontWithSize(size: CGFloat) -> UIFont { return fontFor(.Extras, withSize: size) }

}