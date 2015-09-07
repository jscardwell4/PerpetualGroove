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

struct SoundSet: Hashable, EnumerableType, CustomStringConvertible {
  let baseName: String
  let ext: String
  let url: NSURL
  let instrumentType: InstrumentType
  var fileName: String { return "\(baseName).\(ext)" }
  var description: String {
    return "SoundSet { name: \(baseName), instrumentType: \(instrumentType) }"
  }
  var hashValue: Int { return url.hashValue }

  enum InstrumentType: Byte {
    case SF2 = 1          /// `kInstrumentType_DLSPreset` and `kInstrumentType_SF2Preset`
    case AU = 2           /// `kInstrumentType_AUPreset`
    case AudioFile = 3    /// `kInstrumentType_Audiofile`
    case EXS24 = 4        /// `kInstrumentType_EXS24`

    init(ext: String) {
      switch ext.lowercaseString {
        case "dls", "sf2": self = .SF2
        case "aupreset": self = .AU
        case "exs": self = .EXS24
        default: self = .AudioFile
      }
    }
  }

  static let HipHopKit = SoundSet(baseName: "Hip Hop Kit", ext: "exs")!
  static let GrandPiano = SoundSet(baseName: "Grand Piano", ext: "exs")!
  static let PureOscillators = SoundSet(baseName: "SPYRO's Pure Oscillators", ext: "sf2")!
  static let FluidR3 = SoundSet(baseName: "FluidR3", ext: "sf2")!

  init?(fileName: String) {
    self.init(baseName: (fileName as NSString).stringByDeletingPathExtension, ext: (fileName as NSString).pathExtension)
  }
  
  init?(baseName b: String, ext e: String) {
    baseName = b
    ext = e
    instrumentType = InstrumentType(ext: ext)
    guard let u = NSBundle.mainBundle().URLForResource(baseName, withExtension: ext) else { return nil }
    url = u
    var error: NSError?
    guard url.checkResourceIsReachableAndReturnError(&error) else { MSHandleError(error); return nil }
  }

  init?(baseName: String) {
    switch baseName {
      case SoundSet.HipHopKit.baseName:       self = SoundSet.HipHopKit
      case SoundSet.GrandPiano.baseName:      self = SoundSet.GrandPiano
      case SoundSet.PureOscillators.baseName: self = SoundSet.PureOscillators
      case SoundSet.FluidR3.baseName:         self = SoundSet.FluidR3
      default:                                return nil
    }
  }

  static var allCases: [SoundSet] { return [PureOscillators, GrandPiano, FluidR3, HipHopKit] }

  var programs: [String] {
    switch self {
    case SoundSet.PureOscillators:
      return (try! NSString(contentsOfURL: NSBundle.mainBundle().URLForResource("PureOscillators", withExtension: "programlist")!, encoding: NSUTF8StringEncoding)).componentsSeparatedByString("\n")
    default:
      return []
    }
  }

}

/**
Equatable compliance

- parameter lhs: Instrument.SoundSet
- parameter rhs: Instrument.SoundSet

- returns: Bool
*/
func ==(lhs: SoundSet, rhs: SoundSet) -> Bool { return lhs.url == rhs.url }
