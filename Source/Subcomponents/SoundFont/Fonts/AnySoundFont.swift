//
//  AnySoundFont.swift
//  SoundFont
//
//  Created by Jason Cardwell on 1/7/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import class UIKit.UIImage
import MoonKit

/// A structure for creating a sound font with only a URL.
public struct AnySoundFont: SoundFont2 {

  /// The URL for the file containing the sound font's data.
  public let url: URL

  /// The image to display in the user interface for the sound font.
  public var image: UIImage { #imageLiteral(resourceName: "oscillator") }

  /// Whether the sound font contains general midi percussion presets.
  public let isPercussion: Bool

  /// The base name of the file located at `url`.
  public var fileName: String { url.path.baseNameExt.baseName }

  /// The user-facing name of the sound font.
  public var displayName: String { fileName }

  /// Initializing with a URL.
  /// - Parameters:
  ///   - url: The url for the sound font file.
  ///   - isPercussion: Whether the file contains percussion.
  /// - Requires: `url` is reachable.
  /// - Throws: `ErrorMessage` when `url` is not reachable.
  public init(url: URL, isPercussion: Bool = false) throws {

    // Check that the url is reachable.
    guard try url.checkResourceIsReachable() else { throw Error.InvalidURL }

    // Initialize `url` with the specified URL.
    self.url = url

    // Initialize the percussion flag.
    self.isPercussion = isPercussion

  }

  /// Initializing with a URL. The `isPercussion` flag will be set to `false`.
  /// - Parameter url: The url for the sound font file.
  /// - Requires: `url` is reachable.
  /// - Throws: `ErrorMessage` when `url` is not reachable.
  public init(url: URL) throws { try self.init(url: url, isPercussion: false) }

}

extension AnySoundFont
{
  /// Enumeration of the possible errors thrown by `SoundFont` types.
  enum Error: String, Swift.Error, CustomStringConvertible
  {
    case InvalidURL = "Invalid URL"
  }
}
