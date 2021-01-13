//
//  Fonts.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/12/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import Foundation
import class UIKit.UIFont
import MoonKit
import SwiftUI

/// Extend `UIFont` with class derived properties for fonts used within the application.
public extension UIFont
{
  static let labelFont = UIFont(name: "EvelethLight", size: 14)!
//    ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.light)

  static let largeDisplayFont = UIFont(name: "EvelethLight", size: 36)!
//    ?? UIFont.systemFont(ofSize: 36, weight: UIFont.Weight.light)

  static let controlFont = UIFont(name: "EvelethThin", size: 14)!
//    ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.thin)

  static let largeControlFont = UIFont(name: "EvelethThin", size: 20)!
//    ?? UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.thin)

  static let compressedControlFont = UIFont(name: "EvelethThin", size: 12)!
//    ?? UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.thin)

  static let compressedControlFontEditing = UIFont(name: "Triump-Rg-Rock-02", size: 17)!
//    ?? UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)

  static let controlSelectedFont = UIFont(name: "EvelethRegular", size: 14)!
//    ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)

  static let largeControlSelectedFont = UIFont(name: "EvelethRegular", size: 22)!
//    ?? UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.regular)
}

//private let bundle = unwrapOrDie(Bundle(identifier: "com.moondeerstudios.Common"))
//
//private func url(forFont name: String) -> URL {
//  unwrapOrDie(bundle.url(forResource: name, withExtension: "otf"))
//}
//
//private func loadFonts() {
//
//}

//extension CTFont {
//
//  static let evelethCleanRegular = CTFontCreateWithName("EvelethCleanRegular" as CFString, 24, nil)
//
//}

// "Yellow Design Studio - Eveleth Clean Regular"
// "Yellow Design Studio - Eveleth Clean Shadow"
// "Yellow Design Studio - Eveleth Clean Thin"
// "Yellow Design Studio - Eveleth Dot Light"
// "Yellow Design Studio - Eveleth Dot Regular Bold"
// "Yellow Design Studio - Eveleth Dot Regular"
// "Yellow Design Studio - Eveleth Icons"
// "Yellow Design Studio - Eveleth Light"
// "Yellow Design Studio - Eveleth Regular Bold"
// "Yellow Design Studio - Eveleth Regular"
// "Yellow Design Studio - Eveleth Shadow"
// "Yellow Design Studio - Eveleth Shapes"
// "Yellow Design Studio - Eveleth Slant Light"
// "Yellow Design Studio - Eveleth Slant Regular Bold"
// "Yellow Design Studio - Eveleth Slant Regular"
// "Yellow Design Studio - Eveleth Thin"
// "Latinotype - Triump-Rg-Blur-01"
// "Latinotype - Triump-Rg-Blur-02"
// "Latinotype - Triump-Rg-Blur-03"
// "Latinotype - Triump-Rg-Blur-04"
// "Latinotype - Triump-Rg-Blur-05"
// "Latinotype - Triump-Rg-Blur-06"
// "Latinotype - Triump-Rg-Blur-07"
// "Latinotype - Triump-Rg-Blur-08"
// "Latinotype - Triump-Rg-Blur-09"
// "Latinotype - Triump-Rg-Blur-10"
// "Latinotype - Triump-Rg-Blur-11"
// "Latinotype - Triump-Rg-Blur-12"
// "Latinotype - Triump-Rg-Extras"
// "Latinotype - Triump-Rg-Ornaments"
// "Latinotype - Triump-Rg-Rock-01"
// "Latinotype - Triump-Rg-Rock-02"
// "Latinotype - Triump-Rg-Rock-03"
// "Latinotype - Triump-Rg-Rock-04"
// "Latinotype - Triump-Rg-Rock-05"
// "Latinotype - Triump-Rg-Rock-06"
// "Latinotype - Triump-Rg-Rock-07"
// "Latinotype - Triump-Rg-Rock-08"
// "Latinotype - Triump-Rg-Rock-09"
// "Latinotype - Triump-Rg-Rock-10"
// "Latinotype - Triump-Rg-Rock-11"
// "Latinotype - Triump-Rg-Rock-12"
