//
//  SoundSetType.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import class UIKit.UIImage

protocol SoundSetType: CustomStringConvertible, CustomDebugStringConvertible, JSONValueConvertible, JSONValueInitializable {
  var url: URL { get }
  var presets: [SF2File.Preset] { get }
  var displayName: String { get }
  var fileName: String { get }
  var image: UIImage { get }
  subscript(idx: Int) -> SF2File.Preset { get }
  subscript(program: Byte, bank: Byte) -> SF2File.Preset { get }
  init(url u: URL) throws
  func isEqualTo(_ soundSet: SoundSetType) -> Bool
}

extension SoundSetType {

  var jsonValue: JSONValue { return ["url": url.absoluteString, "fileName": fileName] }

  init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
              let urlString = String(dict["url"]),
              let url = NSURL(string: urlString) else { return nil }
    do { try self.init(url: url as URL) } catch { return nil }
  }

  var hashValue: Int { return url.hashValue }
  var index: Int? { return Sequencer.soundSets.index(where: {$0.url == url}) }

  subscript(idx: Int) -> SF2File.Preset { return presets[idx] }

  subscript(program: Byte, bank: Byte) -> SF2File.Preset {
    guard let idx = presets.index(where: {$0.program == program && $0.bank == bank}) else {
      fatalError("invalid program-bank combination: \(program)-\(bank)")
    }
    return self[idx]
  }

  func isEqualTo(_ soundSet: SoundSetType) -> Bool {
    switch ((soundSet.url as NSURL).fileReferenceURL(), (url as NSURL).fileReferenceURL()) {
      case let (url1?, url2?) where url1 == url2: return true
      case (nil, nil): return true
      default: return false
    }
  }
  
  var displayName: String { return (url.lastPathComponent as NSString).deletingPathExtension }

  var description: String { return "\(displayName) - \(fileName)" }

  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}

/**
Equatable compliance

- parameter lhs: Instrument.SoundSet
- parameter rhs: Instrument.SoundSet

- returns: Bool
*/
func ==<S:SoundSetType>(lhs: S, rhs: S) -> Bool { return lhs.url == rhs.url }
