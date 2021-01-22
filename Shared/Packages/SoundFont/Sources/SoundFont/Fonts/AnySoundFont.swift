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
      self = SoundFont.spyro
    }
  }
}

// MARK: Hashable

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension AnySoundFont: Hashable
{
  public func hash(into hasher: inout Hasher) { url.hash(into: &hasher) }
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

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension AnySoundFont: Mock
{

  static public var mock: AnySoundFont { SoundFont.bundledFonts.randomElement()! }

  static public func mocks(_ count: Int) -> [AnySoundFont] {
    var result: [AnySoundFont] = []
    for _ in 0 ..< count
    {
      result.append(SoundFont.bundledFonts.randomElement()!)
    }
    return result
  }
}
