//
//  AssetManager.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/17/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import Chameleon
import Eveleth

extension UIColor {
  static var backgroundColor: UIColor        { return rgb(51, 50, 49) }
  static var popoverBackgroundColor: UIColor { return rgb(25, 25, 24) }
  static var primaryColor: UIColor           { return rgb(186, 179, 169) }
  static var primaryColor2: UIColor          { return rgb(196, 191, 185) }
  static var secondaryColor: UIColor         { return rgb(146, 135, 120) }
  static var secondaryColor2: UIColor        { return rgb(169, 160, 148) }
  static var tertiaryColor: UIColor          { return rgb(77, 75, 73) }
  static var tertiaryColor2: UIColor         { return rgb(102, 100, 97) }
  static var quaternaryColor: UIColor        { return rgb(223, 211, 194) }
  static var highlightColor: UIColor         { return rgb(194, 65, 0) }
}

extension UIFont {
  static var labelFont: UIFont              { return Eveleth.lightFontWithSize(14) }
  static var largeDisplayFont: UIFont       { return Eveleth.lightFontWithSize(36) }
  static var controlFont: UIFont            { return Eveleth.thinFontWithSize(14) }
  static var controlSelectedFont: UIFont    { return Eveleth.regularFontWithSize(14) }
}


extension CGFloat {
  static var popoverArrowWidth: CGFloat { return 20 }
  static var popoverArrowHeight: CGFloat { return 20 }
}