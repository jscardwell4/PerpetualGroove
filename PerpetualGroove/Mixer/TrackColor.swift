//
//  TrackColor.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/13/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import class UIKit.UIColor
import MoonKit

// MARK: - Enumeration for specifying the color attached to a `MIDITrackType`
enum TrackColor: UInt32 {
  case muddyWaters        = 0xBD7651
  case steelBlue          = 0x4875A8
  case celery             = 0x9FB44D
  case chestnut           = 0xBA5055
  case crayonPurple       = 0x8048A8
  case verdigris          = 0x48A4A8
  case twine              = 0xBD8F51
  case tapestry           = 0xAB4A8D
  case vegasGold          = 0xBDBA51
  case richBlue           = 0x5048A8
  case fruitSalad         = 0x53A949
  case husk               = 0xBDA451
  case mahogany           = 0xC24100
  case mediumElectricBlue = 0x00499B
  case appleGreen         = 0x8EB200
  case venetianRed        = 0xBC000A
  case indigo             = 0x5B009B
  case easternBlue        = 0x00959B
  case indochine          = 0xC26E00
  case flirt              = 0xA2006F
  case ultramarine        = 0x0C009B
  case laRioja            = 0xC2BC00
  case forestGreen        = 0x119E00
  case pizza              = 0xC29500

  var value: UIColor { return UIColor(rgbHex: rawValue) }

  static var nextColor: TrackColor {
    let existingColors = Sequencer.sequence?.instrumentTracks.map({$0.color}) ?? []
    guard existingColors.count > 0 else { return allCases[0] }
    return allCases.filter({!existingColors.contains($0)}).first ?? allCases[0]
  }

}

extension TrackColor: EnumerableType {

  /// `White` case is left out so that it is harder to assign the color used by `MasterTrack`
  static let allCases: [TrackColor] = [
    .muddyWaters, .steelBlue, .celery, .chestnut, .crayonPurple, .verdigris, .twine, 
    .tapestry, .vegasGold, .richBlue, .fruitSalad, .husk, .mahogany, .mediumElectricBlue, 
    .appleGreen, .venetianRed, .indigo, .easternBlue, .indochine, .flirt, .ultramarine, 
    .laRioja, .forestGreen, .pizza
  ]

}

extension TrackColor: CustomStringConvertible {

  var description: String {
    switch self {
      case .muddyWaters:        return "MuddyWaters"
      case .steelBlue:          return "SteelBlue"
      case .celery:             return "Celery"
      case .chestnut:           return "Chestnut"
      case .crayonPurple:       return "CrayonPurple"
      case .verdigris:          return "Verdigris"
      case .twine:              return "Twine"
      case .tapestry:           return "Tapestry"
      case .vegasGold:          return "VegasGold"
      case .richBlue:           return "RichBlue"
      case .fruitSalad:         return "FruitSalad"
      case .husk:               return "Husk"
      case .mahogany:           return "Mahogany"
      case .mediumElectricBlue: return "MediumElectricBlue"
      case .appleGreen:         return "AppleGreen"
      case .venetianRed:        return "VenetianRed"
      case .indigo:             return "Indigo"
      case .easternBlue:        return "EasternBlue"
      case .indochine:          return "Indochine"
      case .flirt:              return "Flirt"
      case .ultramarine:        return "Ultramarine"
      case .laRioja:            return "Larioja"
      case .forestGreen:        return "ForestGreen"
      case .pizza:              return "Pizza"
    }
  }

}

extension TrackColor: LosslessJSONValueConvertible {

  var jsonValue: JSONValue { return "#\(String(rawValue, radix: 16, uppercase: true))".jsonValue }

  init?(_ jsonValue: JSONValue?) {
    guard
      let string = String(jsonValue),
      string.hasPrefix("#"),
      let hex = UInt32(string.substring(from: string.index(after: string.startIndex)), radix: 16)
      else
    {
      return nil
    }
    
    self.init(rawValue: hex)
  }

}
