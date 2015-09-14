//
//  SoundSet.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/13/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import AudioUnit.AudioUnitProperties

/** Wrapper for a sound font file */
struct SoundSet: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
  let url: NSURL
  var description: String {
    var result =  "SoundSet {\n"
    result += "  name: \((url.lastPathComponent! as NSString).stringByDeletingPathExtension)\n"
    result += "  number of presets: \(presets.count)\n"
    result += "}"
    return result
  }
  var debugDescription: String {
    var result =  "SoundSet {\n"
    result += "  name: \((url.lastPathComponent! as NSString).stringByDeletingPathExtension)\n"
    result += "  sf2File: \(sf2File.description.indentedBy(4, true))\n"
    result += "}"
    return result
  }
  let sf2File: SF2File
  var hashValue: Int { return url.hashValue }
  var displayName: String { return (url.lastPathComponent! as NSString).stringByDeletingPathExtension }
  var index: Int {
    guard let idx = Sequencer.soundSets.indexOf(self) else { fatalError("failed to get index for \(self)") }
    return idx
  }

  typealias Preset = SF2File.Preset
  let presets: [Preset]

  subscript(idx: Int) -> Preset { return presets[idx] }

  subscript(program: Byte) -> Preset {
    if presets.count > Int(program) {
      var idx = Int(program)
      switch (presets[idx].program, program) {
      case let (p1, p2) where p1 == p2: return presets[idx]
      case let (p1, p2) where p1 < p2:
        while idx + 1 < presets.count {
          if presets[++idx].program == program { return presets[idx] }
        }
        fatalError("invalid program: '\(program)'")
      case let (p1, p2) where p1 > p2:
        while idx > 0 {
          if presets[--idx].program == program { return presets[idx] }
        }
        fatalError("invalid program: '\(program)'")
      default:
        fatalError("invalid program: '\(program)'")
      }
    } else if let idx = presets.indexOf({$0.program == program}) {
      return presets[idx]
    } else {
      fatalError("invalid program: '\(program)'")
    }
  }

  /**
  Initialize a sound set using the file located by the specified url.

  - parameter u: NSURL
  */
  init(url u: NSURL) throws {
    var error: NSError?
    guard u.checkResourceIsReachableAndReturnError(&error) else { throw error! }
    sf2File = try SF2File(file: u)
    url = u
    presets = sf2File.presets.sort()
  }

}

/**
Equatable compliance

- parameter lhs: Instrument.SoundSet
- parameter rhs: Instrument.SoundSet

- returns: Bool
*/
func ==(lhs: SoundSet, rhs: SoundSet) -> Bool { return lhs.url == rhs.url }
