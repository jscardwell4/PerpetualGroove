//
//  Fonts.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/12/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import Foundation
import class UIKit.UIFont

/// Extend `UIFont` with class derived properties for fonts used within the application.
public extension UIFont
{
  static let labelFont = UIFont(name: "EvelethLight", size: 14)
    ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.light)

  static let largeDisplayFont = UIFont(name: "EvelethLight", size: 36)
    ?? UIFont.systemFont(ofSize: 36, weight: UIFont.Weight.light)

  static let controlFont = UIFont(name: "EvelethThin", size: 14)
    ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.thin)

  static let largeControlFont = UIFont(name: "EvelethThin", size: 20)
    ?? UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.thin)

  static let compressedControlFont = UIFont(name: "EvelethThin", size: 12)
    ?? UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.thin)

  static let compressedControlFontEditing = UIFont(name: "Triump-Rg-Rock-02", size: 17)
    ?? UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)

  static let controlSelectedFont = UIFont(name: "EvelethRegular", size: 14)
    ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)

  static let largeControlSelectedFont = UIFont(name: "EvelethRegular", size: 22)
    ?? UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.regular)
}
