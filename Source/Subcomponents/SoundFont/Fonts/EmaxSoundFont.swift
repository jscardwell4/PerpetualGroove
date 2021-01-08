//
//  EmaxSoundFont.swift
//  SoundFont
//
//  Created by Jason Cardwell on 1/7/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit
import class UIKit.UIImage

// MARK: - EmaxSoundFont

/// A structure for sound fonts that are part of the 'Emax' collection located within the
/// application's bundle.
public struct EmaxSoundFont: SoundFont2
{
  // MARK: Stored Properties

  /// The volume of the sound font.
  public let volume: Volume

  // MARK: Computed Properties

  /// The URL for the sound font within the application's main bundle.
  public var url: URL
  {
    unwrapOrDie
    {
      Bundle(identifier: "com.moondeerstudios.SoundFont")?
        .url(forResource: fileName, withExtension: "sf2")
    }
  }

  /// Whether the sound font contains general midi percussion presets. This is `false`
  /// unless the sound font represents the 'drums and percussion' volume.
  public var isPercussion: Bool { volume.isPercussion }

  /// The title-cased name of the sound font's volume.
  public var displayName: String { volume.displayName }

  /// The name of the sound font file within the application's main bundle.
  public var fileName: String { "Emax Volume \(volume.index)" }

  /// The image to display in the user interface for the sound font. Unique to `volume`.
  public var image: UIImage { volume.image }

  // MARK: Initializing

  /// Initializing with a volume.
  public init(_ volume: Volume) { self.volume = volume }

  /// Initializing with a URL. The sound font is initialized by matching `url.path`
  /// against 'Emax Volume #` where '#' is a number between 1 and 6.
  ///
  /// - Parameter url: The url of the Emax Volume.
  /// - Throws: `ErrorMessage` when a `url` cannot be matched to a volume.
  public init(url: URL) throws
  {
    // Retrieve the volume via regular expression matching.
    guard let match = (~/"Emax Volume ([1-6])").firstMatch(in: url.path),
          let string = match.captures[1]?.substring,
          let volume = Int(String(string))
    else
    {
      throw ErrorMessage(errorDescription: "EmaxSoundFont.Error",
                         failureReason: "Invalid URL")
    }

    // Initialize with the parsed volume number.
    self.init(try Volume(index: volume))
  }
}

public extension EmaxSoundFont
{
  /// A structure for specifying volume data within the 'Emax' collection.
  struct Volume
  {
    public let index: Int
    public let displayName: String
    public let image: UIImage
    public let isPercussion: Bool

    public static let brassAndWoodwinds = Volume(1, "Brass & Woodwinds", #imageLiteral(resourceName: "brass"))
    public static let keyboardsAndSynths = Volume(2, "Keyboards & Synths", #imageLiteral(resourceName: "piano_keyboard"))
    public static let guitarsAndBasses = Volume(3, "Guitars & Basses", #imageLiteral(resourceName: "guitar_bass"))
    public static let worldInstruments = Volume(4, "World Instruments", #imageLiteral(resourceName: "world"))
    public static let drumsAndPercussion = Volume(5, "Drums & Percussion", #imageLiteral(resourceName: "percussion"), true)
    public static let orchestral = Volume(6, "Orchestral", #imageLiteral(resourceName: "orchestral"))

    private init(_ index: Int,
                 _ displayName: String,
                 _ image: UIImage,
                 _ isPercussion: Bool = false)
    {
      self.index = index
      self.displayName = displayName
      self.image = image
      self.isPercussion = isPercussion
    }

    init(index: Int) throws
    {
      switch index
      {
        case 1: self = Volume.brassAndWoodwinds
        case 2: self = Volume.keyboardsAndSynths
        case 3: self = Volume.guitarsAndBasses
        case 4: self = Volume.worldInstruments
        case 5: self = Volume.drumsAndPercussion
        case 6: self = Volume.orchestral
        default: throw Error.InvalidVolumeNumber
      }
    }
  }
}

extension EmaxSoundFont
{
  /// Enumeration of the possible errors thrown by `SoundFont` types.
  enum Error: String, Swift.Error, CustomStringConvertible
  {
    case InvalidVolumeNumber = "Invalid volumne number"
  }
}
