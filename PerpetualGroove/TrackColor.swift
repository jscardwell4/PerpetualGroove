//
//  TrackColor.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/13/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import class SpriteKit.SKTexture
import MoonKit

// MARK: - Enumeration for specifying the color attached to a `MIDITrackType`
enum TrackColor: UInt32, Equatable, Hashable, EnumerableType, CustomStringConvertible {
  case MuddyWaters        = 0xBD7651
  case SteelBlue          = 0x4875A8
  case Celery             = 0x9FB44D
  case Chestnut           = 0xBA5055
  case CrayonPurple       = 0x8048A8
  case Verdigris          = 0x48A4A8
  case Twine              = 0xBD8F51
  case Tapestry           = 0xAB4A8D
  case VegasGold          = 0xBDBA51
  case RichBlue           = 0x5048A8
  case FruitSalad         = 0x53A949
  case Husk               = 0xBDA451
  case Mahogany           = 0xC24100
  case MediumElectricBlue = 0x00499B
  case AppleGreen         = 0x8EB200
  case VenetianRed        = 0xBC000A
  case Indigo             = 0x5B009B
  case EasternBlue        = 0x00959B
  case Indochine          = 0xC26E00
  case Flirt              = 0xA2006F
  case Ultramarine        = 0x0C009B
  case LaRioja            = 0xC2BC00
  case ForestGreen        = 0x119E00
  case Pizza              = 0xC29500

  var value: UIColor { return UIColor(RGBHex: rawValue) }

  var description: String {
    switch self {
      case .MuddyWaters:        return "MuddyWaters"
      case .SteelBlue:          return "SteelBlue"
      case .Celery:             return "Celery"
      case .Chestnut:           return "Chestnut"
      case .CrayonPurple:       return "CrayonPurple"
      case .Verdigris:          return "Verdigris"
      case .Twine:              return "Twine"
      case .Tapestry:           return "Tapestry"
      case .VegasGold:          return "VegasGold"
      case .RichBlue:           return "RichBlue"
      case .FruitSalad:         return "FruitSalad"
      case .Husk:               return "Husk"
      case .Mahogany:           return "Mahogany"
      case .MediumElectricBlue: return "MediumElectricBlue"
      case .AppleGreen:         return "AppleGreen"
      case .VenetianRed:        return "VenetianRed"
      case .Indigo:             return "Indigo"
      case .EasternBlue:        return "EasternBlue"
      case .Indochine:          return "Indochine"
      case .Flirt:              return "Flirt"
      case .Ultramarine:        return "Ultramarine"
      case .LaRioja:            return "Larioja"
      case .ForestGreen:        return "ForestGreen"
      case .Pizza:              return "Pizza"
    }
  }

  /// `White` case is left out so that it is harder to assign the color used by `MasterTrack`
  static let allCases: [TrackColor] = [
    .MuddyWaters, .SteelBlue, .Celery, .Chestnut, .CrayonPurple, .Verdigris, .Twine, 
    .Tapestry, .VegasGold, .RichBlue, .FruitSalad, .Husk, .Mahogany, .MediumElectricBlue, 
    .AppleGreen, .VenetianRed, .Indigo, .EasternBlue, .Indochine, .Flirt, .Ultramarine, 
    .LaRioja, .ForestGreen, .Pizza
  ]

//  static var currentColor: TrackColor? {
//    return Sequencer.sequence?.currentTrack?.color
//  }

  static var nextColor: TrackColor {
    let existingColors = Sequencer.sequence?.instrumentTracks.map({$0.color}) ?? []
    guard existingColors.count > 0 else { return allCases[0] }
    return allCases.filter({!existingColors.contains($0)}).first ?? allCases[0]
  }
}

extension TrackColor: JSONValueConvertible {
  var jsonValue: JSONValue { return "#\(String(rawValue, radix: 16, uppercase: true))".jsonValue }
}

extension TrackColor: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let string = String(jsonValue) where string.hasPrefix("#"),
          let hex = UInt32(string[string.startIndex.successor()..<], radix: 16) else { return nil }
    self.init(rawValue: hex)
  }
}