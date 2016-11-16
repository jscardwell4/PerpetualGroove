//
//  Fonts.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/12/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import class UIKit.UIFont
import Eveleth
import Triump

extension UIFont {
  static var labelFont: UIFont                    { return Eveleth.lightFontWithSize(14)   }
  static var largeDisplayFont: UIFont             { return Eveleth.lightFontWithSize(36)   }
  static var controlFont: UIFont                  { return Eveleth.thinFontWithSize(14)    }
  static var largeControlFont: UIFont                  { return Eveleth.thinFontWithSize(20)    }
  static var compressedControlFont: UIFont        { return Eveleth.thinFontWithSize(12)    }
  static var compressedControlFontEditing: UIFont { return Triump.rock2FontWithSize(17)    }
  static var controlSelectedFont: UIFont          { return Eveleth.regularFontWithSize(14) }
  static var largeControlSelectedFont: UIFont          { return Eveleth.regularFontWithSize(22) }
}


