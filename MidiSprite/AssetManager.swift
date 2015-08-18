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

  static let sliderThumbImage = UIImage(named: "marker1")?.imageWithColor(Chameleon.kelleyPearlBush)
  static let sliderMinTrackImage = UIImage(named: "line6")?.imageWithColor(rgb(146, 135, 120))
  static let sliderMaxTrackImage = UIImage(named: "line6")?.imageWithColor(rgb(246, 243, 240))
  static let sliderThumbOffset = UIOffset(horizontal: 0, vertical: -16)

}
