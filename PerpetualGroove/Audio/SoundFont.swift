//
//  SoundFont.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import class UIKit.UIImage
import class UIKit.NSDataAsset

protocol SoundFont: CustomStringConvertible, JSONValueConvertible, JSONValueInitializable {

  /// The sound font file's location.
  var url: URL { get }

  /// The sound font file's data.
  var data: Data { get }

  /// The presets present in the sound font file.
  var presetHeaders: [SF2File.PresetHeader] { get }

  /// The name to display in the user interface for the sound font.
  var displayName: String { get }

  /// The sound font file's base name without the extension.
  var fileName: String { get }

  /// The image to display in the user interface for the sound font.
  var image: UIImage { get }

  /// Accessor for retrieving a preset via the totally ordered array of presets.
  subscript(idx: Int) -> SF2File.PresetHeader { get }

  /// Accessor for retrieving a preset by its program and bank numbers.
  subscript(program program: UInt8, bank bank: UInt8) -> SF2File.PresetHeader? { get }

  /// Initialize a sound font using it's file location.
  init(url u: URL) throws

  /// Compare this sound font to another for equality. Two sound font's are equal if they point to
  /// the same resource.
  func isEqualTo(_ soundSet: SoundFont) -> Bool
}

extension SoundFont {

  var jsonValue: JSONValue { return ["url": url.absoluteString] }

  init?(_ jsonValue: JSONValue?) {
    guard let url = URL(string: String(ObjectJSONValue(jsonValue)?["url"]) ?? "") else { return nil }
    do { try self.init(url: url) } catch { return nil }
  }

}

extension SoundFont {

  static func ==(lhs: Self, rhs: Self) -> Bool { return lhs.url == rhs.url }

  var hashValue: Int { return url.hashValue }

}

extension SoundFont {

  /// Property of convenience for looking up a sound font's index in the `Sequencer`'s `soundSets` collection.
  var index: Int? { return Sequencer.soundSets.index(where: {isEqualTo($0)}) }

}

extension SoundFont {

  subscript(idx: Int) -> SF2File.PresetHeader { return presetHeaders[idx] }

  subscript(program program: UInt8, bank bank: UInt8) -> SF2File.PresetHeader? {
    return presetHeaders.first(where: {$0.program == program && $0.bank == bank})
  }

  func isEqualTo(_ soundSet: SoundFont) -> Bool {
    let refURL1 = (url as NSURL).fileReferenceURL()
    let refURL2 = (soundSet.url as NSURL).fileReferenceURL()

    switch (refURL1, refURL2) {
      case let (url1?, url2?) where url1.isEqualToFileURL(url2): return true
      case (nil, nil): return true
      default: return false
    }
  }

  var data: Data { return (try? Data(contentsOf: url)) ?? fatal("Failed to retrieve data from disk.") }

  var presetHeaders: [SF2File.PresetHeader] { return (try? SF2File.presetHeaders(from: data)) ?? [] }

  var image: UIImage { return #imageLiteral(resourceName: "oscillator") }

  var fileName: String { return url.path.baseNameExt.baseName }

  var displayName: String { return fileName }

  var description: String { return "\(displayName) - \(fileName)" }

}

/// Holds the location, name, and preset info for a `SF2File`
struct SoundSet: SoundFont {
  
  let url: URL

  /// Initialize a sound set using the file located by the specified url.
  init(url: URL) throws {
    guard try url.checkResourceIsReachable() else {
      throw ErrorMessage(errorDescription: "SoundSet Error", failureReason: "Invalid URL")
    }

    self.url = url
  }

  static let spyro = try! SoundSet(url: Bundle.main.url(forResource: "SPYRO's Pure Oscillators",
                                                        withExtension: "sf2")!)
  
}

struct EmaxSoundSet: SoundFont {

  enum Volume: Int {
    case brassAndWoodwinds  = 1
    case keyboardsAndSynths = 2
    case guitarsAndBasses   = 3
    case worldInstruments   = 4
    case drumsAndPercussion = 5
    case orchestral         = 6
  }

  var url: URL {
    return Bundle.main.url(forResource: fileName, withExtension: "sf2") ?? fatal("Failed to locate sf2 file")
  }

  let volume: Volume

  var displayName: String {
    switch volume {
      case .brassAndWoodwinds:  return "Brass & Woodwinds"
      case .keyboardsAndSynths: return "Keyboards & Synths"
      case .guitarsAndBasses:   return "Guitars & Basses"
      case .worldInstruments:   return "World Instruments"
      case .drumsAndPercussion: return "Drums & Percussion"
      case .orchestral:         return "Orchestral"
    }
  }

  var fileName: String { return "Emax Volume \(volume.rawValue)" }

  var image: UIImage {
    switch volume {
      case .brassAndWoodwinds:  return #imageLiteral(resourceName: "brass")
      case .keyboardsAndSynths: return #imageLiteral(resourceName: "piano_keyboard")
      case .guitarsAndBasses:   return #imageLiteral(resourceName: "guitar_bass")
      case .worldInstruments:   return #imageLiteral(resourceName: "world")
      case .drumsAndPercussion: return #imageLiteral(resourceName: "percussion")
      case .orchestral:         return #imageLiteral(resourceName: "orchestral")
    }
  }

  init(_ volume: Volume) { self.volume = volume }

  init(url: URL) throws {
    guard let volume = (url.path ~=> ~/"Emax Volume ([1-6])")?.1 else {
      throw ErrorMessage(errorDescription: "EmaxSoundSet Error", failureReason: "Invalid URL")
    }

    self.init(Volume(rawValue: Int(volume)!)!)
  }

}
