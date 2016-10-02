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

protocol SoundFont: CustomStringConvertible, JSONValueConvertible, JSONValueInitializable {
  /// The sound font file's location.
  var url: URL { get }

  /// The presets present in the sound font file.
  var presets: [SF2File.Preset] { get }

  /// The name to display in the user interface for the sound font.
  var displayName: String { get }

  /// The sound font file's base name without the extension.
  var fileName: String { get }

  /// The image to display in the user interface for the sound font.
  var image: UIImage { get }

  /// Accessor for retrieving a preset via the totally ordered array of presets.
  subscript(idx: Int) -> SF2File.Preset { get }

  /// Accessor for retrieving a preset by its program and bank numbers.
  subscript(program program: Byte, bank bank: Byte) -> SF2File.Preset { get }

  /// Initialize a sound font using it's file location.
  init(url u: URL) throws

  /// Compare this sound font to another for equality. Two sound font's are equal if they point to
  /// the same resource.
  func isEqualTo(_ soundSet: SoundFont) -> Bool
}

extension SoundFont {

  var jsonValue: JSONValue { return ["url": url.absoluteString, "fileName": fileName] }

  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
              let urlString = String(dict["url"]),
              let url = URL(string: urlString) else { return nil }
    do { try self.init(url: url) } catch { return nil }
  }

}

extension SoundFont {

  static func ==(lhs: Self, rhs: Self) -> Bool { return lhs.url == rhs.url }

  var hashValue: Int { return url.hashValue }

}

extension SoundFont {

  /// Property of convenience for looking up a sound font's index in the `Sequencer`'s `soundSets` collection.
  var index: Int? { return Sequencer.soundSets.index(where: {$0.url == url}) }

}

extension SoundFont {

  subscript(idx: Int) -> SF2File.Preset { return presets[idx] }

  subscript(program program: Byte, bank bank: Byte) -> SF2File.Preset {
    guard let idx = presets.index(where: {$0.program == program && $0.bank == bank}) else {
      fatalError("invalid program-bank combination: \(program)-\(bank)")
    }
    return self[idx]
  }

  func isEqualTo(_ soundSet: SoundFont) -> Bool {
    switch ((soundSet.url as NSURL).fileReferenceURL(), (url as NSURL).fileReferenceURL()) {
      case let (url1?, url2?) where url1 == url2: return true
      case (nil, nil): return true
      default: return false
    }
  }

  var fileName: String { return url.path.baseNameExt.baseName }

  var displayName: String { return fileName }

  var description: String { return "\(displayName) - \(fileName)" }
}

