//
//  FontStyle.swift
//  Common
//
//  Created by Jason Cardwell on 1/13/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import SwiftUI

// MARK: - FontStyle

/// A structuring for specifying font styles used by the application's UI.
public struct FontStyle
{
  /// The postscript name for the font specified by this style.
  public let postscriptName: String

  /// The point size specified by this style.
  public let size: CGFloat

  /// The text style with which the font will scale.
  public let style: Font.TextStyle

  /// Initializing with a postscript font, size, and style.
  ///
  /// - Parameters:
  ///   - font: The postscript font to use in the style.
  ///   - size: The size of the font to use in the style.
  ///   - style: The text style with which the font will scale.
  public init<Postscript>(font: Postscript, size: CGFloat, style: Font.TextStyle)
  where Postscript: PostscriptFont
  {
    postscriptName = font.postscriptName
    self.size = size
    self.style = style
  }

  /// A style with font `EvelethFont.light`, size `14`, and style `.title`.
  public static let label = FontStyle(
    font: EvelethFont.light,
    size: 14,
    style: .title
  )

  /// A style with font `EvelethFont.light`, size `36`, and style `.largeTitle`.
  public static let largeLabel = FontStyle(
    font: EvelethFont.light,
    size: 36,
    style: .largeTitle
  )

  /// A style with font `EvelethFont.light`, size `14`, and style `.title`.
  public static let control = FontStyle(
    font: EvelethFont.light,
    size: 14,
    style: .title
  )

  /// A style with font `EvelethFont.thin`, size `20`, and style `.largeTitle`.
  public static let largeControl = FontStyle(
    font: EvelethFont.thin,
    size: 20,
    style: .largeTitle
  )
  /// A style with font `EvelethFont.regular`, size `14`, and style `.title`.
  public static let controlSelected = FontStyle(
    font: EvelethFont.regular,
    size: 14,
    style: .title
  )

  /// A style with font `EvelethFont.regular`, size `22`, and style `.title`.
  public static let largeControlSelected = FontStyle(
    font: EvelethFont.regular,
    size: 22,
    style: .title
  )

  /// A style with font `EvelethFont.thin`, size `12`, and style `.title2`.
  public static let compressedControl = FontStyle(
    font: EvelethFont.thin,
    size: 12,
    style: .title2
  )

  /// A style with font `TriumpFont.rock02`, size `17`, and style `.title2`.
  public static let compressedControlEditing = FontStyle(
    font: TriumpFont.rock02,
    size: 17,
    style: .title2
  )

  /// A style with font `TriumpFont.rock02`, size `24`, and style `.largeTitle`.
  public static let largeControlEditing = FontStyle(
    font: TriumpFont.rock02,
    size: 24,
    style: .largeTitle
  )

  /// A style with font `EvelethFont.dotRegularBold`, size `64`, and style `.largeTitle`.
  public static let clock = FontStyle(
    font: EvelethFont.dotRegularBold,
    size: 64,
    style: .largeTitle
  )
}

// MARK: - PostscriptFont

/// A protocol for types representing a font with a known postscript name.
public protocol PostscriptFont
{
  /// The postscript name for the represented font.
  var postscriptName: String { get }
}
