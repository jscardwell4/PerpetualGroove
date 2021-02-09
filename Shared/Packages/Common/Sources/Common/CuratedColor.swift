//
//  CuratedColor.swift
//  Common
//
//  Created by Jason Cardwell on 2/6/21.
//
import Foundation
import SwiftUI

/// Enumeration of curated colors.
public enum CuratedColor: String, CaseIterable, Codable, CustomStringConvertible
{
  case muddyWaters
  case steelBlue
  case celery
  case chestnut
  case crayonPurple
  case verdigris
  case twine
  case tapestry
  case vegasGold
  case richBlue
  case fruitSalad
  case husk
  case mahogany
  case mediumElectricBlue
  case appleGreen
  case venetianRed
  case indigo
  case easternBlue
  case indochine
  case flirt
  case ultramarine
  case laRioja
  case forestGreen
  case pizza

  public var color: Color { .init(rawValue, bundle: .module) }

  public static subscript(index: Int) -> CuratedColor { allCases[index % allCases.count] }

  /// All possible `TrackColor` values.
  public static let allCases: [CuratedColor] = [
    .muddyWaters, .steelBlue, .celery, .chestnut, .crayonPurple, .verdigris, .twine,
    .tapestry, .vegasGold, .richBlue, .fruitSalad, .husk, .mahogany, .mediumElectricBlue,
    .appleGreen, .venetianRed, .indigo, .easternBlue, .indochine, .flirt, .ultramarine,
    .laRioja, .forestGreen, .pizza
  ]

  /// The color's name.
  public var description: String { rawValue }
}

#if canImport(UIKit)
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension UIColor
{
  public convenience init(_ curatedColor: CuratedColor)
  {
    self.init(named: curatedColor.rawValue, in: .module, compatibleWith: nil)!
  }
}
#endif

public protocol ColorCurated
{
  var color: CuratedColor { get }
}
