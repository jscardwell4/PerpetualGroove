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

  fileprivate static var fontsRegistered = false

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
      let bundle = Bundle(for: self)
      let fontURLs = fontNames.flatMap { bundle.url(forResource: $0, withExtension: "otf") }
      var errors: Unmanaged<CFArray>?
      CTFontManagerRegisterFontsForURLs(fontURLs as CFArray, CTFontManagerScope.none, &errors)
      if let errorsArray = errors?.takeRetainedValue() as? NSArray, let errors = errorsArray as? [NSError] {
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
  fileprivate class func fontFor(_ face: Face, withSize size: CGFloat) -> UIFont {
    if !fontsRegistered { registerFonts() }
    assert(fontsRegistered)

    let descriptor = UIFontDescriptor(fontAttributes: [
      UIFontDescriptorFamilyAttribute: "Festivo LC",
      UIFontDescriptorFaceAttribute: face.rawValue
    ])
    return UIFont(descriptor: descriptor, size: size)
  }

  public class func threeDFontWithSize(_ size: CGFloat)       -> UIFont { return fontFor(.ThreeD, withSize: size)       }
  public class func basicFontWithSize(_ size: CGFloat)        -> UIFont { return fontFor(.Basic, withSize: size)        }
  public class func basicDotsFontWithSize(_ size: CGFloat)    -> UIFont { return fontFor(.BasicDots, withSize: size)    }
  public class func basicLLineFontWithSize(_ size: CGFloat)   -> UIFont { return fontFor(.BasicLLine, withSize: size)   }
  public class func basicLShadowFontWithSize(_ size: CGFloat) -> UIFont { return fontFor(.BasicLShadow, withSize: size) }
  public class func basicRLineFontWithSize(_ size: CGFloat)   -> UIFont { return fontFor(.BasicRLine, withSize: size)   }
  public class func basicRShadowFontWithSize(_ size: CGFloat) -> UIFont { return fontFor(.BasicRShadow, withSize: size) }
  public class func dotsFontWithSize(_ size: CGFloat)         -> UIFont { return fontFor(.Dots, withSize: size)         }
  public class func inlineFontWithSize(_ size: CGFloat)       -> UIFont { return fontFor(.Inline, withSize: size)       }
  public class func lLinesFontWithSize(_ size: CGFloat)       -> UIFont { return fontFor(.LLines, withSize: size)       }
  public class func lShadowsFontWithSize(_ size: CGFloat)     -> UIFont { return fontFor(.LShadows, withSize: size)     }
  public class func miniFontWithSize(_ size: CGFloat)         -> UIFont { return fontFor(.Mini, withSize: size)         }
  public class func outlineFontWithSize(_ size: CGFloat)      -> UIFont { return fontFor(.Outline, withSize: size)      }
  public class func outlineDotsFontWithSize(_ size: CGFloat)  -> UIFont { return fontFor(.OutlineDots, withSize: size)  }
  public class func rlinesFontWithSize(_ size: CGFloat)       -> UIFont { return fontFor(.Rlines, withSize: size)       }
  public class func rShadowsFontWithSize(_ size: CGFloat)     -> UIFont { return fontFor(.RShadows, withSize: size)     }
  public class func sketch1FontWithSize(_ size: CGFloat)      -> UIFont { return fontFor(.Sketch1, withSize: size)      }
  public class func sketch2FontWithSize(_ size: CGFloat)      -> UIFont { return fontFor(.Sketch2, withSize: size)      }
  public class func sketch3FontWithSize(_ size: CGFloat)      -> UIFont { return fontFor(.Sketch3, withSize: size)      }
  public class func woodFontWithSize(_ size: CGFloat)         -> UIFont { return fontFor(.Wood, withSize: size)         }
  public class func extrasFontWithSize(_ size: CGFloat)       -> UIFont { return fontFor(.Extras, withSize: size)       }

}
