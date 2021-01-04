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

/// Enumeration for specifying the color of a MIDI node dispatching instance whose raw
/// value is an unsigned 32-bit integer representing a hexadecimal RGB value.
public enum TrackColor: UInt32 {

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

  /// The `UIColor` derived from `rawValue`.
  public var value: UIColor { UIColor(rgbHex: rawValue) }

  public static func nextColor(after color: TrackColor) -> TrackColor {
    colors[(colors.firstIndex(of: color)! + 1) % colors.count]
  }

  public static func nextColor(currentColors: Set<TrackColor>) -> TrackColor {
    colors.first { currentColors ∌ $0 } ?? colors[0]
  }

  /// All possible `TrackColor` values.
  public static let colors: [TrackColor] = [
    .muddyWaters, .steelBlue, .celery, .chestnut, .crayonPurple, .verdigris, .twine, 
    .tapestry, .vegasGold, .richBlue, .fruitSalad, .husk, .mahogany, .mediumElectricBlue, 
    .appleGreen, .venetianRed, .indigo, .easternBlue, .indochine, .flirt, .ultramarine, 
    .laRioja, .forestGreen, .pizza
  ]

}

extension TrackColor: CustomStringConvertible {

  /// The color's name.
  public var description: String {
    switch self {
      case .muddyWaters:        return "muddyWaters"
      case .steelBlue:          return "steelBlue"
      case .celery:             return "celery"
      case .chestnut:           return "chestnut"
      case .crayonPurple:       return "crayonPurple"
      case .verdigris:          return "verdigris"
      case .twine:              return "twine"
      case .tapestry:           return "tapestry"
      case .vegasGold:          return "vegasGold"
      case .richBlue:           return "richBlue"
      case .fruitSalad:         return "fruitSalad"
      case .husk:               return "husk"
      case .mahogany:           return "mahogany"
      case .mediumElectricBlue: return "mediumElectricBlue"
      case .appleGreen:         return "appleGreen"
      case .venetianRed:        return "venetianRed"
      case .indigo:             return "indigo"
      case .easternBlue:        return "easternBlue"
      case .indochine:          return "indochine"
      case .flirt:              return "flirt"
      case .ultramarine:        return "ultramarine"
      case .laRioja:            return "larioja"
      case .forestGreen:        return "forestGreen"
      case .pizza:              return "pizza"
    }
  }

}

extension TrackColor: LosslessJSONValueConvertible {

  /// A string with the pound-prefixed hexadecimal representation of `rawValue`.
  public var jsonValue: JSONValue { "#\(String(rawValue, radix: 16))".jsonValue }

  /// Initializing with a JSON value.
  /// - Parameter jsonValue: To be successful, `jsonValue` must be a string that
  ///                        begins with '#' and whose remaining characters form
  ///                        a string convertible to `UInt32`.
  public init?(_ jsonValue: JSONValue?) {

    // Check that the JSON value is a string and get convert it to a hexadecimal value.
    guard let string = String(jsonValue),
          string.hasPrefix("#"),
          let hex = UInt32(String(string.dropFirst()), radix: 16)
      else
    {
      return nil
    }

    // Initialize with the hexadecimal value.
    self.init(rawValue: hex)

  }

}
