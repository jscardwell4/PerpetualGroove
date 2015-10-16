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
    result += "  presets: {\n" + ",\n".join(presets.map({$0.description})).indentedBy(8) + "\n\t}"
    result += "\n}"
    return result
  }
  var hashValue: Int { return url.hashValue }
  var displayName: String { return (url.lastPathComponent! as NSString).stringByDeletingPathExtension }
  var index: Int {
    guard let idx = Sequencer.soundSets.indexOf(self) else { fatalError("failed to get index for \(self)") }
    return idx
  }

  typealias Preset  = SF2File.Preset
  typealias Bank    = Byte
  typealias Program = Byte

  let presets: [Preset]

  subscript(idx: Int) -> Preset { return presets[idx] }

  subscript(program: Program, bank: Bank) -> Preset {
    guard let idx = presets.indexOf({$0.program == program && $0.bank == bank}) else {
      fatalError("invalid program-bank combination: \(program)-\(bank)")
    }
    return self[idx]
  }

  /**
  Initialize a sound set using the file located by the specified url.

  - parameter u: NSURL
  */
  init(url u: NSURL) throws {
    var error: NSError?
    guard u.checkResourceIsReachableAndReturnError(&error) else { throw error! }
    presets = try SF2File(file: u).presets.sort()
    url = u
    logDebug(debugDescription)
  }

}

/**
Equatable compliance

- parameter lhs: Instrument.SoundSet
- parameter rhs: Instrument.SoundSet

- returns: Bool
*/
func ==(lhs: SoundSet, rhs: SoundSet) -> Bool { return lhs.url == rhs.url }
