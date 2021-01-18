//
//  AnySoundFont.swift
//  SoundFont
//
//  Created by Jason Cardwell on 1/15/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev
import struct SwiftUI.Image

// MARK: - AnySoundFont

/// A wrapper for types that implement the `SoundFont2` protocol.
@available(OSX 10.15, *)
@available(iOS 14.0, *)
public enum AnySoundFont: SoundFont2
{
  /// A case for wrapping instances of `EmaxSoundFont`.
  case emax(EmaxSoundFont)

  /// A case for wrapping instances of `CustomSoundFont`.
  case custom(CustomSoundFont)

  /// The `SoundFont2` type being wrapped by this enumeration.
  @available(iOS 14.0, *)
  private var underlyingFont: SoundFont2
  {
    switch self
    {
      case let .emax(underlyingFont):
        return underlyingFont
      case let .custom(underlyingFont):
        return underlyingFont
    }
  }

  /// The URL of the file that defines the sound font.
  public var url: URL { underlyingFont.url }

  /// Whether the sound font contains general midi percussion presets.
  public var isPercussion: Bool { underlyingFont.isPercussion }

  /// The name to display in the user interface for the sound font.
  public var displayName: String { underlyingFont.displayName }

  /// The sound font file's base name without the extension.
  public var fileName: String { underlyingFont.fileName }

  /// The image to display in the user interface for the sound font.
  public var image: Image { underlyingFont.image }

  /// Initialize a sound font using it's file location.
  public init(url: URL) throws
  {
    do
    {
      self = .emax(try EmaxSoundFont(url: url))
    }
    catch
    {
      self = .custom(try CustomSoundFont(url: url))
    }
  }
}

@available(iOS 14.0, *)
@available(OSX 10.15, *)
public extension AnySoundFont
{
  /// Derived array holding all the fonts stored as static properties below.
  static var bundledFonts: [AnySoundFont]
  {
    [
      .brassAndWoodwinds,
      .keyboardsAndSynths,
      .guitarsAndBasses,
      .worldInstruments,
      .drumsAndPercussions,
      .orchestral,
      .spyro
    ]
  }

  /// Emax Volume 1
  static let brassAndWoodwinds: AnySoundFont = .emax(EmaxSoundFont(.brassAndWoodwinds))

  /// Emax Volume 2
  static let keyboardsAndSynths: AnySoundFont = .emax(EmaxSoundFont(.keyboardsAndSynths))

  /// Emax Volume 3
  static let guitarsAndBasses: AnySoundFont = .emax(EmaxSoundFont(.guitarsAndBasses))

  /// Emax Volume 4
  static let worldInstruments: AnySoundFont = .emax(EmaxSoundFont(.worldInstruments))

  /// Emax Volume 5
  static let drumsAndPercussions: AnySoundFont = .emax(EmaxSoundFont(.drumsAndPercussion))

  /// Emax Volume 6
  static let orchestral: AnySoundFont = .emax(EmaxSoundFont(.orchestral))

  /// SPYRO's Pure Oscillators
  static let spyro: AnySoundFont = tryOrDie
  {
    .custom(
      try CustomSoundFont(
        url: unwrapOrDie(
          Bundle.module
            .url(forResource: "SPYRO's Pure Oscillators", withExtension: "sf2")
        )
      )
    )
  }
}

// MARK: Equatable

@available(iOS 14.0, *)
@available(OSX 10.15, *)
extension AnySoundFont: Equatable
{
  public static func == (lhs: AnySoundFont, rhs: AnySoundFont) -> Bool
  {
    switch (lhs, rhs)
    {
      case let (.emax(first), .emax(second)):
        return first.volume == second.volume
      case let (.custom(first), .custom(second)):
        return first.fileName == second.fileName
      default:
        return false
    }
  }
}
