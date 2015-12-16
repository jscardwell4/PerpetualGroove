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
  case MuddyWaters        = 0xad6140
  case SteelBlue          = 0x386096
  case Celery             = 0x8ea83d
  case Chestnut           = 0xa93a43
  case CrayonPurple       = 0x6b3096
  case Verdigris          = 0x3b9396
  case Twine              = 0xae7c40
  case Tapestry           = 0x99327a
  case VegasGold          = 0xafae40
  case RichBlue           = 0x3d3296
  case FruitSalad         = 0x459c38
  case Husk               = 0xae9440
  case Mahogany           = 0xb22d04
  case MediumElectricBlue = 0x043489
  case AppleGreen         = 0x7ca604
  case VenetianRed        = 0xab000b
  case Indigo             = 0x470089
  case EasternBlue        = 0x108389
  case Indochine          = 0xb35a04
  case Flirt              = 0x8e005c
  case Ultramarine        = 0x090089
  case LaRioja            = 0xb5b106
  case ForestGreen        = 0x189002
  case Pizza              = 0xb48405
  case White              = 0xffffff
  case Portica            = 0xf7ea64
  case MonteCarlo         = 0x7ac2a5
  case FlamePea           = 0xda5d3a
  case Crimson            = 0xd6223e
  case HanPurple          = 0x361aee
  case MangoTango         = 0xf88242
  case Viking             = 0x6bcbe1
  case Yellow             = 0xfde97e
  case Conifer            = 0x9edc58
  case Apache             = 0xce9f58


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
      case .LaRioja:            return "LaRioja"
      case .ForestGreen:        return "ForestGreen"
      case .Pizza:              return "Pizza"
      case .White:              return "White"
      case .Portica:            return "Portica"
      case .MonteCarlo:         return "MonteCarlo"
      case .FlamePea:           return "FlamePea"
      case .Crimson:            return "Crimson"
      case .HanPurple:          return "HanPurple"
      case .MangoTango:         return "MangoTango"
      case .Viking:             return "Viking"
      case .Yellow:             return "Yellow"
      case .Conifer:            return "Conifer"
      case .Apache:             return "Apache"
    }
  }

  /// `White` case is left out so that it is harder to assign the color used by `MasterTrack`
  static let allCases: [TrackColor] = [
    .MuddyWaters, .SteelBlue, .Celery, .Chestnut, .CrayonPurple, .Verdigris, .Twine, .Tapestry, .VegasGold, 
    .RichBlue, .FruitSalad, .Husk, .Mahogany, .MediumElectricBlue, .AppleGreen, .VenetianRed, .Indigo, 
    .EasternBlue, .Indochine, .Flirt, .Ultramarine, .LaRioja, .ForestGreen, .Pizza, .White, .Portica, 
    .MonteCarlo, .FlamePea, .Crimson, .HanPurple, .MangoTango, .Viking, .Yellow, .Conifer, .Apache
  ]

  static var currentColor: TrackColor? {
    return MIDIDocumentManager.currentDocument?.sequence?.currentTrack?.color
  }

  static var nextColor: TrackColor {
    return allCases[((MIDIDocumentManager.currentDocument?.sequence?.instrumentTracks.count ?? -1) + 1) % allCases.count]
  }
}
