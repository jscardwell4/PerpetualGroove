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
struct SoundSet: Hashable, CustomStringConvertible {
  let url: NSURL
  var description: String {
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
  var presets: [Preset] { return sf2File.presets.sort() }

  /**
  Initialize a sound set using the file located by the specified url.

  - parameter u: NSURL
  */
  init(url u: NSURL) throws {
    var error: NSError?
    guard u.checkResourceIsReachableAndReturnError(&error) else { throw error! }
    sf2File = try SF2File(file: u)
    url = u
  }

}

/**
Equatable compliance

- parameter lhs: Instrument.SoundSet
- parameter rhs: Instrument.SoundSet

- returns: Bool
*/
func ==(lhs: SoundSet, rhs: SoundSet) -> Bool { return lhs.url == rhs.url }
