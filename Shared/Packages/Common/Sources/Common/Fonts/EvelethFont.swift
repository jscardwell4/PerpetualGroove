//
//  EvelethFont.swift
//  Common
//
//  Created by Jason Cardwell on 1/13/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
//import CoreText
import Foundation
import MoonDev

// MARK: - EvelethFont

/// A structure describing fonts available from the Eveleth font family.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct EvelethFont
{
  /// The family designation the font carries in its postscript name.
  public let family: Family

  /// The weight designation the font carries in its postscript name.
  public let weight: Weight

  /// An enumeration of possible family designations.
  public enum Family: String
  {
    case normal = ""
    case clean = "Clean"
    case cleanShadow = "CleanShadow"
    case dot = "Dot"
    case icons = "Icons"
    case shadow = "Shadow"
    case shapes = "Shapes"
    case slant = "Slant"
  }

  /// An enumeration of possible weight designations.
  public enum Weight: String
  {
    case unspecified = ""
    case regular = "Regular"
    case thin = "Thin"
    case light = "Light"
    case regularBold = "Regular-Bold"
    case bold = "Bold"
  }

  /// The set of postscript names registered with the font manager.
  private static var registered: Set<String> = []

  /// Declare a private initializer to prevent the creation of invalid
  /// family/weight combinations.
  /// - Parameters:
  ///   - family: The family designation.
  ///   - weight: The weight designation.
  public init(_ family: Family, _ weight: Weight)
  {
    self.family = family
    self.weight = weight

//    guard EvelethFont.registered ∌ postscriptName else { return }
//
//    guard let url = Bundle.module.url(forResource: postscriptName, withExtension: "otf")
//    else
//    {
//      logw("\(#fileID) \(#function) Unable to locate font '\(postscriptName)'.")
//      return
//    }
//
//    guard CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
//    else
//    {
//      loge("\(#fileID) \(#function) Failed to register font '\(postscriptName)'.")
//      return
//    }
//
//    EvelethFont.registered.insert(postscriptName)
  }

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Clean Regular.otf"
  public static let cleanRegular = EvelethFont(.clean, .regular)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Clean Shadow.otf"
  public static let cleanShadow = EvelethFont(.cleanShadow, .unspecified)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Clean Thin.otf"
  public static let cleanThin = EvelethFont(.clean, .thin)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Dot Light.otf"
  public static let dotLight = EvelethFont(.dot, .light)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Dot Regular Bold.otf"
  public static let dotRegularBold = EvelethFont(.dot, .regularBold)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Dot Regular.otf"
  public static let dotRegular = EvelethFont(.dot, .regular)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Icons.otf"
  public static let icons = EvelethFont(.icons, .unspecified)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Light.otf"
  public static let light = EvelethFont(.normal, .light)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Regular Bold.otf"
  public static let regularBold = EvelethFont(.normal, .regularBold)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Regular.otf"
  public static let regular = EvelethFont(.normal, .regular)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Shadow.otf"
  public static let shadow = EvelethFont(.shadow, .unspecified)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Shapes.otf"
  public static let shapes = EvelethFont(.shapes, .regular)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Slant Light.otf"
  public static let slantLight = EvelethFont(.slant, .light)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Slant Regular Bold.otf"
  public static let slantRegularBold = EvelethFont(.slant, .regularBold)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Slant Regular.otf"
  public static let slantRegular = EvelethFont(.slant, .regular)

  /// `EvelethFont` instance for "Yellow Design Studio - Eveleth Thin.otf"
  public static let thin = EvelethFont(.normal, .thin)
}

// MARK: PostscriptFont

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension EvelethFont: PostscriptFont
{
  public var postscriptName: String { "Eveleth\(family.rawValue)\(weight.rawValue)" }
}
