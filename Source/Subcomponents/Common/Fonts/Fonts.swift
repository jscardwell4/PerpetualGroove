//
//  Fonts.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/12/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev
import SwiftUI
import class UIKit.UIFont

/// Extend `UIFont` with `FontStyle` convenience initializer and static properties.
public extension UIFont
{
  /// Initializing with a font style configuration.
  ///
  /// - Parameter fontStyle: The style with which to configure the font.
  convenience init(fontStyle: FontStyle)
  {
    // Ensure `fontStyle` is valid by using it to create a font.
    guard let font = UIFont(name: fontStyle.postscriptName, size: fontStyle.size)
    else
    {
      fatalError("""
      \(#fileID) \(#function) \
      Failed to create font using postscript name '\(fontStyle.postscriptName)'
      """)
    }
    // Initialize using the font descriptor.
    self.init(descriptor: font.fontDescriptor, size: fontStyle.size)
  }

  /// The font created using `FontStyle.label`.
  static let label = UIFont(fontStyle: .label)

  /// The font created using `FontStyle.largeLabel`.
  static let largeLabel = UIFont(fontStyle: .largeLabel)

  /// The font created using `FontStyle.control`.
  static let control = UIFont(fontStyle: .control)

  /// The font created using `FontStyle.largeControl`.
  static let largeControl = UIFont(fontStyle: .largeControl)

  /// The font created using `FontStyle.controlSelected`.
  static let controlSelected = UIFont(fontStyle: .controlSelected)

  /// The font created using `FontStyle.largeControlSelected`.
  static let largeControlSelected = UIFont(fontStyle: .largeControlSelected)

  /// The font created using `FontStyle.compressedControl`.
  static let compressedControl = UIFont(fontStyle: .compressedControl)

  /// The font created using `FontStyle.compressedControlEditing`.
  static let compressedControlEditing = UIFont(fontStyle: .compressedControlEditing)

  /// The font created using `FontStyle.largeControlEditing`.
  static let largeControlEditing = UIFont(fontStyle: .largeControlEditing)

  /// The font created using `FontStyle.clock`.
  static let clock = UIFont(fontStyle: .clock)

  /// The font created using `FontStyle.listItem`.
  static let listItem = UIFont(fontStyle: .listItem)
}

/// Extend `Font` with `FontStyle` convenience initializer and static properties.
public extension Font
{
  /// Generates a new `Font` instance using the specified configuration. This
  /// method invokes `Font.custom(_:size:relativeTo:)` using the values held
  /// by `style`.
  ///
  /// - Parameter style: The style with which to configure the font.
  /// - Returns: The font configured using `style`.
  static func style(_ style: FontStyle) -> Font
  {
    Font.custom(style.postscriptName, size: style.size, relativeTo: style.style)
  }

  /// The font created using `FontStyle.label`.
  static let label = Font.style(.label)

  /// The font created using `FontStyle.largeLabel`.
  static let largeLabel = Font.style(.largeLabel)

  /// The font created using `FontStyle.control`.
  static let control = Font.style(.control)

  /// The font created using `FontStyle.largeControl`.
  static let largeControl = Font.style(.largeControl)

  /// The font created using `FontStyle.controlSelected`.
  static let controlSelected = Font.style(.controlSelected)

  /// The font created using `FontStyle.largeControlSelected`.
  static let largeControlSelected = Font.style(.largeControlSelected)

  /// The font created using `FontStyle.compressedControl`.
  static let compressedControl = Font.style(.compressedControl)

  /// The font created using `FontStyle.compressedControlEditing`.
  static let compressedControlEditing = Font.style(.compressedControlEditing)

  /// The font created using `FontStyle.largeControlEditing`.
  static let largeControlEditing = Font.style(.largeControlEditing)

  /// The font created using `FontStyle.clock`.
  static let clock = Font.style(.clock)

  /// The font created using `FontStyle.listItem`.
  static let listItem = Font.style(.listItem)

}
