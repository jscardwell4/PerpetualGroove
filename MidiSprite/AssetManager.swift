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

final class AssetManager {

  static let sliderThumbImage    = UIImage(named: "marker2")?.imageWithColor(sliderThumbColor)
  static let sliderMinTrackImage = UIImage(named: "line6")?.imageWithColor(sliderMinTrackColor)
  static let sliderMaxTrackImage = UIImage(named: "line6")?.imageWithColor(sliderMaxTrackColor)
  static let sliderThumbOffset   = UIOffset(horizontal: 0, vertical: -16)
  static let sliderThumbColor    = Chameleon.kelleyPearlBush
  static let sliderMinTrackColor = rgb(146, 135, 120)
  static let sliderMaxTrackColor = rgb(51, 50, 49)

  static let labelFont              = Eveleth.lightFontWithSize(14)
  static let labelTextColor         = Chameleon.kelleyPearlBush
  static let controlFont            = Eveleth.thinFontWithSize(14)
  static let controlColor           = Chameleon.quietLightLobLollyDark
  static let controlSelectedFont    = Eveleth.regularFontWithSize(14)
  static let controlSelectedColor   = Chameleon.quietLightLobLolly
  static let tintColor              = Chameleon.quietLightLilyWhiteDark
  static let sliderLabelValueFont   = Eveleth.lightFontWithSize(6)
  static let sliderLabelValueColor  = Chameleon.flatWhiteDark
  static let sliderLabelValueOffset = UIOffset(horizontal: -2, vertical: -20)

}
