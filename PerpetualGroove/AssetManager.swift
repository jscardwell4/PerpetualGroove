//
//  AssetManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/17/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import Chameleon
import Eveleth
import FestivoLC
import Triump

extension UIColor {
  static var backgroundColor:        UIColor { return mineShaft    }
  static var popoverBackgroundColor: UIColor { return rangoonGreen }
  static var primaryColor:           UIColor { return silk         }
  static var primaryColor2:          UIColor { return cottonSeed   }
  static var secondaryColor:         UIColor { return grayNickel   }
  static var secondaryColor2:        UIColor { return bronco       }
  static var tertiaryColor:          UIColor { return fuscousGray  }
  static var tertiaryColor2:         UIColor { return stormDust    }
  static var quaternaryColor:        UIColor { return pearlBush    }
  static var highlightColor:         UIColor { return mahogany     }

  static var silk:         UIColor { return UIColor(rgbHex: 0xBAB3A9) }
  static var cottonSeed:   UIColor { return UIColor(rgbHex: 0xC4BfB9) }
  static var paleSlate:    UIColor { return UIColor(rgbHex: 0xC6C0B7) }
  static var grayNickel:   UIColor { return UIColor(rgbHex: 0x928778) }
  static var rangoonGreen: UIColor { return UIColor(rgbHex: 0x191918) }
  static var montana:      UIColor { return UIColor(rgbHex: 0x3B3B3B) }
  static var fuscousGray:  UIColor { return UIColor(rgbHex: 0x4D4B49) }
  static var mineShaft:    UIColor { return UIColor(rgbHex: 0x333231) }
  static var nero:         UIColor { return UIColor(rgbHex: 0x262625) }
  static var ironsideGray: UIColor { return UIColor(rgbHex: 0x555350) }
  static var gravel:       UIColor { return UIColor(rgbHex: 0x4D4B49) }
  static var judgeGray:    UIColor { return UIColor(rgbHex: 0x5C5346) }
  static var bronco:       UIColor { return UIColor(rgbHex: 0xA9A094) }
  static var stormDust:    UIColor { return UIColor(rgbHex: 0x666461) }
  static var donkeyBrown:  UIColor { return UIColor(rgbHex: 0xA4947C) }
  static var pearlBush:    UIColor { return UIColor(rgbHex: 0xDFD3C2) }
  static var pearlBush2:   UIColor { return UIColor(rgbHex: 0xE8DFD3) }
  static var mahogany:     UIColor { return UIColor(rgbHex: 0xC24100) }
}

extension UIFont {
  static var labelFont: UIFont                    { return Eveleth.lightFontWithSize(14)   }
  static var largeDisplayFont: UIFont             { return Eveleth.lightFontWithSize(36)   }
  static var controlFont: UIFont                  { return Eveleth.thinFontWithSize(14)    }
  static var compressedControlFont: UIFont        { return Eveleth.thinFontWithSize(12)    }
  static var compressedControlFontEditing: UIFont { return Triump.rock2FontWithSize(17)    }
  static var controlSelectedFont: UIFont          { return Eveleth.regularFontWithSize(14) }
}


extension CGFloat {
  static var popoverArrowWidth:  CGFloat { return 20 }
  static var popoverArrowHeight: CGFloat { return 20 }
}
