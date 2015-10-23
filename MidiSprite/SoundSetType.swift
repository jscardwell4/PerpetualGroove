//
//  SoundSetType.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

protocol SoundSetType: CustomStringConvertible, CustomDebugStringConvertible {
  var url: NSURL { get }
  var presets: [SF2File.Preset] { get }
  var displayName: String { get }
  var fileName: String { get }
  var image: UIImage { get }
  subscript(idx: Int) -> SF2File.Preset { get }
  subscript(program: Byte, bank: Byte) -> SF2File.Preset { get }
  init(url u: NSURL) throws
}

extension SoundSetType {
  var hashValue: Int { return url.hashValue }
  var index: Int? { return Sequencer.soundSets.indexOf({$0.url == url}) }

  subscript(idx: Int) -> SF2File.Preset { return presets[idx] }

  subscript(program: Byte, bank: Byte) -> SF2File.Preset {
    guard let idx = presets.indexOf({$0.program == program && $0.bank == bank}) else {
      fatalError("invalid program-bank combination: \(program)-\(bank)")
    }
    return self[idx]
  }
  
  var displayName: String { return (url.lastPathComponent! as NSString).stringByDeletingPathExtension }

  var description: String { return "\(displayName) - \(fileName)" }

  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

/**
Equatable compliance

- parameter lhs: Instrument.SoundSet
- parameter rhs: Instrument.SoundSet

- returns: Bool
*/
func ==<S:SoundSetType>(lhs: S, rhs: S) -> Bool { return lhs.url == rhs.url }

