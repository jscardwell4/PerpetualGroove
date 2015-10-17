//
//  FestivoLC.swift
//  FestivoLC
//
//  Created by Jason Cardwell on 8/6/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//


import class Foundation.NSBundle
import class Foundation.NSURL
import class UIKit.UIFont
import CoreText

public final class FestivoLC: NSObject {

  private static var fontsRegistered = false

  /** initialize */
  public override class func initialize() { if self === FestivoLC.self && !fontsRegistered { registerFonts() } }

  /** registerFonts */
  public class func registerFonts() {
    if !fontsRegistered {
      fontsRegistered = true
      let styles = [
        "3D", "Basic", "BasicDots", "BasicLLine", "BasicLShadow", "BasicRLine", "BasicRShadow", "Dots", "Inline", "LLines",
        "LShadows", "Mini", "Outline", "OutlineDots", "Rlines", "RShadows", "Sketch1", "Sketch2", "Sketch3", "Wood", "Extras"
      ]
      let fontNames = styles.map { "Ahmet Altun - FestivoLC-\($0)" }
      let bundle = NSBundle(forClass: self)
      let fontURLs = fontNames.flatMap { bundle.URLForResource($0, withExtension: "otf") }
      var errors: Unmanaged<CFArray>?
      CTFontManagerRegisterFontsForURLs(fontURLs, CTFontManagerScope.None, &errors)
      if let errorsArray = errors?.takeRetainedValue() as? NSArray, errors = errorsArray as? [NSError] {
        let error = NSError(domain: "CTFontManagerErrorDomain",
                            code: 1,
                        userInfo: [NSUnderlyingErrorKey: errors,
                                   NSLocalizedDescriptionKey:"Errors encountered registering 'FestivoLC' fonts"])
        NSLog("\(error)")
      }
    }
  }

  public enum Face: String {
    case ThreeD = "3D", Basic, BasicDots = "Basic Dots", BasicLLine = "Basic L Line", BasicLShadow = "Basic L Shadow", 
         BasicRLine = "Basic R Line", BasicRShadow = "Basic R Shadow", Dots, Inline, LLines = "L Lines", LShadows = "L Shadows", 
         Mini, Outline, OutlineDots = "Outline Dots", Rlines = "R Lines", RShadows = "R Shadows", Sketch1, Sketch2, Sketch3, 
         Wood, Extras
  }

  /**
  fontFor:

  - parameter face: Face

  - returns: UIFont
  */
  private class func fontFor(face: Face, withSize size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)

    let descriptor = UIFontDescriptor(fontAttributes: [
      UIFontDescriptorFamilyAttribute: "Festivo LC",
      UIFontDescriptorFaceAttribute: face.rawValue
    ])
    return UIFont(descriptor: descriptor, size: size)
  }

  public class func threeDFontWithSize(size: CGFloat)       -> UIFont { return fontFor(.ThreeD, withSize: size)       }
  public class func basicFontWithSize(size: CGFloat)        -> UIFont { return fontFor(.Basic, withSize: size)        }
  public class func basicDotsFontWithSize(size: CGFloat)    -> UIFont { return fontFor(.BasicDots, withSize: size)    }
  public class func basicLLineFontWithSize(size: CGFloat)   -> UIFont { return fontFor(.BasicLLine, withSize: size)   }
  public class func basicLShadowFontWithSize(size: CGFloat) -> UIFont { return fontFor(.BasicLShadow, withSize: size) }
  public class func basicRLineFontWithSize(size: CGFloat)   -> UIFont { return fontFor(.BasicRLine, withSize: size)   }
  public class func basicRShadowFontWithSize(size: CGFloat) -> UIFont { return fontFor(.BasicRShadow, withSize: size) }
  public class func dotsFontWithSize(size: CGFloat)         -> UIFont { return fontFor(.Dots, withSize: size)         }
  public class func inlineFontWithSize(size: CGFloat)       -> UIFont { return fontFor(.Inline, withSize: size)       }
  public class func lLinesFontWithSize(size: CGFloat)       -> UIFont { return fontFor(.LLines, withSize: size)       }
  public class func lShadowsFontWithSize(size: CGFloat)     -> UIFont { return fontFor(.LShadows, withSize: size)     }
  public class func miniFontWithSize(size: CGFloat)         -> UIFont { return fontFor(.Mini, withSize: size)         }
  public class func outlineFontWithSize(size: CGFloat)      -> UIFont { return fontFor(.Outline, withSize: size)      }
  public class func outlineDotsFontWithSize(size: CGFloat)  -> UIFont { return fontFor(.OutlineDots, withSize: size)  }
  public class func rlinesFontWithSize(size: CGFloat)       -> UIFont { return fontFor(.Rlines, withSize: size)       }
  public class func rShadowsFontWithSize(size: CGFloat)     -> UIFont { return fontFor(.RShadows, withSize: size)     }
  public class func sketch1FontWithSize(size: CGFloat)      -> UIFont { return fontFor(.Sketch1, withSize: size)      }
  public class func sketch2FontWithSize(size: CGFloat)      -> UIFont { return fontFor(.Sketch2, withSize: size)      }
  public class func sketch3FontWithSize(size: CGFloat)      -> UIFont { return fontFor(.Sketch3, withSize: size)      }
  public class func woodFontWithSize(size: CGFloat)         -> UIFont { return fontFor(.Wood, withSize: size)         }
  public class func extrasFontWithSize(size: CGFloat)       -> UIFont { return fontFor(.Extras, withSize: size)       }

}