//
//  Instrument.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AVFoundation
import MoonKit
import AudioToolbox


class Instrument: Equatable {

  // MARK: - The SoundSet enumeration
  enum SoundSet: Equatable {

    case Identifier(baseName: String, ext: String)

    static let HipHopKit = SoundSet.Identifier(baseName: "Hip Hop Kit", ext: "exs")
    static let GrandPiano = SoundSet.Identifier(baseName: "Grand Piano", ext: "exs")
    static let PureOscillators = SoundSet.Identifier(baseName: "SPYRO's Pure Oscillators", ext: "sf2")
    static let FluidR3 = SoundSet.Identifier(baseName: "FluidR3", ext: "sf2")

    var baseName: String { switch self { case .Identifier(let baseName, _): return baseName } }
    var ext: String { switch self { case .Identifier(_, let ext): return ext } }

    var url: NSURL {
      guard let url = NSBundle.mainBundle().URLForResource(baseName, withExtension: ext) else {
        fatalError("missing bundle resource")
      }
      return url
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

    static var all: [SoundSet] { return [PureOscillators, GrandPiano, FluidR3, HipHopKit] }
  }

  // MARK: - Properties

  let sampler: AVAudioUnitSampler
  var program: UInt8
  var channel: UInt8

  var connected: Bool { return sampler.engine != nil }

  // MARK: - Initialization

  /**
  initWithSoundSet:program:channel:

  - parameter soundSet: SoundSet
  - parameter program: UInt8 = 0
  - parameter channel: UInt8 = 0
  */
  init(soundSet: SoundSet, program p: UInt8 = 0, channel c: UInt8 = 0) {
    sampler = AVAudioUnitSampler()
    program = p
    channel = c
    MidiManager.connectInstrument(self)
    do {
      try sampler.loadInstrumentAtURL(soundSet.url)
      sampler.sendProgramChange(p, onChannel: c)
    } catch {
      logError(error)
    }
  }

  // MARK: - The Note struct
  struct Note {
    var duration = 0.25
    var value: MIDINote = .Pitch(letter: .C, octave: 4)
    var velocity: UInt8 = 64
  }

  enum MIDINote: RawRepresentable {

    enum Letter: String {

      case C = "C", CSharp = "C♯", D = "D", DSharp = "D♯", E = "E", F = "F", FSharp = "F♯",
           G = "G", GSharp = "G♯", A = "A", ASharp = "A♯", B = "B"

      init(_ i: UInt8) { self = Letter.all[Int(i % 12)] }

      static let all: [Letter] = [C, CSharp, D, DSharp, E, F, FSharp, G, GSharp, A, ASharp, B]
      var intValue: Int { return Letter.all.indexOf(self)! }
    }

    case Pitch(letter: Letter, octave: Int)

    /**
    Initialize from MIDI value from 0 ... 127

    - parameter midi: Int
    */
    init(var midi: UInt8) { midi %= 128; self = .Pitch(letter: Letter(midi), octave: (Int(midi) / 12) - 1) }

    /**
    Initialize with string representation

    - parameter rawValue: String
    */
    init?(rawValue: String) {
      guard let match = (~/"^([A-G]♯?)((?:-1)|[0-9])$").firstMatch(rawValue),
                rawLetter = match.captures[1]?.string,
                letter = Letter(rawValue: rawLetter),
                rawOctave = match.captures[2]?.string,
                octave = Int(rawOctave) else { return nil }

      self = .Pitch(letter: letter, octave :octave)
    }

    var rawValue: String { switch self { case let .Pitch(letter, octave): return "\(letter.rawValue)\(octave)" } }

    var midi: UInt8 {  switch self { case let .Pitch(letter, octave): return UInt8((octave + 1) * 12 + letter.intValue) } }

    static let all: [MIDINote] =  (0...127).map(MIDINote.init)
  }

  /**
  playNote:

  - parameter note: Note
  */
  func playNote(note: Note) {
    
    sampler.startNote(note.value.midi, withVelocity: note.velocity, onChannel: channel)
    dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, Int64(note.duration * Double(NSEC_PER_SEC))),
      dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
    ) {
      [weak self] in
      guard let instrument = self else { return }
      instrument.sampler.stopNote(note.value.midi, onChannel: instrument.channel)
    }
  }

}

/**
subscript:rhs:

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.sampler === rhs.sampler }

/**
Equatable compliance

- parameter lhs: Instrument.SoundSet
- parameter rhs: Instrument.SoundSet

- returns: Bool
*/
func ==(lhs: Instrument.SoundSet, rhs: Instrument.SoundSet) -> Bool {
  switch (lhs, rhs) {
    case let (.Identifier(lBaseName, lExt), .Identifier(rBaseName, rExt)) where lBaseName == rBaseName && lExt == rExt: return true
    default: return false
  }
}

private let pureOscillatorsPrograms = [
  "Blob",
  "Brown Noise Decay",
  "Pink Noise Decay",
  "White Noise Decay",
  "Brown Noise",
  "Pink Noise",
  "White Noise",
  "Rebirth 3 (++quick)",
  "Rebirth 2 (+quick)",
  "Rebirth",
  "Inv Saw Stereo Exp",
  "Inv Sawtooth+Triangl",
  "Inv Sawtooth+Square",
  "Inv Sawtooth S/R+Vib",
  "Inv Sawtooth Vibravl",
  "Inv Sawtooth Slo Rel",
  "Inv Sawtooth",
  "Sine Exp Min7 Soft",
  "Sine Exp Maj7 Soft",
  "Saw Exp Min7",
  "Square Exp Min7",
  "Sine Exp Min7",
  "Saw Exp Maj7",
  "Square Exp Maj7",
  "Sine Exp Maj7",
  "Sine Exp Maj Chords",
  "Saw Stereo Expanded",
  "Square Stereo Expand",
  "Triang Stereo Expand",
  "Sine Stereo Expanded",
  "Rare Instrument6",
  "Rare Instrument5fast",
  "Rare Instrument5",
  "Rare Instrument4",
  "Rare Instrument3",
  "Rare Instrument2",
  "Rare Instrument1",
  "Sawtooth Aug 4th's",
  "Square Aug 4th's",
  "Triangle Aug 4th's",
  "Sine Aug 4th's",
  "Square Maj Sixths",
  "Triangle Maj Sixths",
  "Sawtooth Fourths",
  "Square Fourths",
  "Triangle Fourths",
  "Sawtooth Fifths",
  "Square Fifths",
  "Triangle Fifths",
  "Sine Fifths",
  "Saw W/H Octave",
  "Square W/H Octave",
  "Triangle W/H Octave",
  "Sine W/H Octave",
  "Saw With Harm's",
  "Square With Harm's",
  "Triangle With Harm's",
  "Sine With Harm´s",
  "Sawtooth Bubble",
  "Square Bubble",
  "Triangle Bubble",
  "Sine Bubble",
  "Sine+Tri+Saw+squ Vib",
  "Sine+Tri+Saw+Square",
  "Sine+Tri+Saw",
  "Sine+Tri+quare",
  "Sawtooth+Square",
  "Sawtooth+Sine",
  "Square+Triangle",
  "Square+Sawtooth",
  "Square+Sine",
  "Triangle+Inv Sine2",
  "Triangle+Inv Sine",
  "Triangle+Sawtooth",
  "Triangle+Square",
  "Sine+Inv Sine",
  "Sine+Sawtooth",
  "Sine+Square",
  "Sine+Triangle",
  "Sawtooth Sl Rel+Vib",
  "Square Sl Rel+Vib",
  "Triangle Sl Rel+Vib",
  "Inv Sine3 Sl Rel+Vib",
  "Inv Sine2 Sl Rel+Vib",
  "Inv Sine Sl Rel+Vib",
  "Sine3 Sl Rel+Vib",
  "Sine2 Sl Rel+Vib",
  "Sine Sl Rel+Vib",
  "Sawtooth Vibravol",
  "Square Vibravol",
  "Triangle Vibravol",
  "Inv Sine3 Vibravol",
  "Inv Sine2 Vibravol",
  "Inv Sine Vibravol",
  "Sine3 Vibravol",
  "Sine2 Vibravol",
  "Sine Vibravol",
  "Sawtooth Slow Rel",
  "Square Slow Rel",
  "Triangle Slow Rel",
  "Inv Sine3 Slow Rel",
  "Inv Sine2 Slow Rel",
  "Inv Sine Slow Rel",
  "Sine3 Slow Rel",
  "Sine2 Slow Rel",
  "Sine Slow Rel",
  "Sawtooth",
  "Square",
  "Triangle",
  "Inv Sine3",
  "Inv Sine2",
  "Inv Sine",
  "Sine3",
  "Sine2",
  "Sine"]

extension Instrument.SoundSet {
  var programs: [String] {
    switch self {
      case let soundSet where soundSet == Instrument.SoundSet.PureOscillators:
        return pureOscillatorsPrograms
      default:
        return []
    }
  }
}