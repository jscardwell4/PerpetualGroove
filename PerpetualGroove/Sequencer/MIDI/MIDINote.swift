//
//  MIDINote.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/18/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file

/// A structure for specifying a note's pitch and octave
struct MIDINote {

  var note: Note
  var octave: Octave

  /// Returns the normalized value for the specified `note`. i.e. B♯ ➞ C
  static func normalizedNote(for note: Note) -> Note {
    switch note {
      case .natural(.c),
           .accidental(.b, .sharp),
           .accidental(.d, .doubleFlat):
        return MIDINote.normalizedNotes[0]
      case .accidental(.c, .sharp),
           .accidental(.d, .flat):
        return MIDINote.normalizedNotes[1]
      case .natural(.d),
           .accidental(.e, .doubleFlat):
        return MIDINote.normalizedNotes[2]
      case .accidental(.d, .sharp),
           .accidental(.e, .flat),
           .accidental(.f, .doubleFlat):
        return MIDINote.normalizedNotes[3]
      case .natural(.e),
           .accidental(.f, .flat):
        return MIDINote.normalizedNotes[4]
      case .natural(.f),
           .accidental(.e, .sharp),
           .accidental(.g, .doubleFlat):
        return MIDINote.normalizedNotes[5]
      case .accidental(.f, .sharp),
           .accidental(.g, .flat):
        return MIDINote.normalizedNotes[6]
      case .natural(.g),
           .accidental(.a, .doubleFlat):
        return MIDINote.normalizedNotes[7]
      case .accidental(.g, .sharp),
           .accidental(.a, .flat):
        return MIDINote.normalizedNotes[8]
      case .natural(.a),
           .accidental(.b, .doubleFlat):
        return MIDINote.normalizedNotes[9]
      case .accidental(.a, .sharp),
           .accidental(.b, .flat),
           .accidental(.c, .doubleFlat):
        return MIDINote.normalizedNotes[10]
      case .natural(.b),
           .accidental(.c, .flat):
        return MIDINote.normalizedNotes[11]
    }
  }

  static let normalizedNotes: [Note] = [
    .natural(.c), .accidental(.c, .sharp), .natural(.d), .accidental(.d, .sharp), .natural(.e), .natural(.f),
    .accidental(.f, .sharp), .natural(.g), .accidental(.g, .sharp), .natural(.a), .accidental(.a, .sharp),
    .natural(.b)
  ]

  /// Returns the index of a note within the 12-note octave
  static func index(for note: Note) -> Int { return normalizedNotes.firstIndex(of: normalizedNote(for: note))! }

  init(_ note: Note, _ octave: Octave) {
    self.note = note
    self.octave = octave
  }

  /// Initialize from MIDI value from 0 ... 127
  init(midi value: UInt8) {
    note = MIDINote.normalizedNotes[Int(value) % 12]
    octave = Octave(rawValue: Int(value / 12 - 1)) ?? .four
  }

  var midi: UInt8 { return UInt8((octave.rawValue + 1) * 12 + MIDINote.index(for: note)) }

  var percussionMapping: PercussionMapping? { return PercussionMapping(rawValue: midi) }

}

extension MIDINote: RawRepresentable, LosslessJSONValueConvertible {

  /// Initialize with string representation
  init?(rawValue: String) {
    guard let captures = (~/"^([A-G][♭♯𝄫]?) ?((?:-1)|[0-9])$").firstMatch(in: rawValue),
          let pitch = Note(rawValue: String(captures[1]?.substring ?? "")),
          let rawOctave = Int(String(captures[2]?.substring ?? "")),
          let octave = Octave(rawValue: rawOctave) else { return nil }

    self.note = pitch
    self.octave = octave
  }

  var rawValue: String { return "\(note.rawValue)\(octave.rawValue)" }

}

extension MIDINote: Hashable {

  var hashValue: Int { return midi.hashValue }

  static func ==(lhs: MIDINote, rhs: MIDINote) -> Bool {
    return lhs.note == rhs.note && lhs.octave == rhs.octave
  }

}

extension MIDINote: CustomStringConvertible {

  var description: String { return rawValue }

}

extension MIDINote {

  enum PercussionMapping: UInt8 {
    case acousticBassDrum = 35 
    case bassDrum1        = 36 
    case sideStick        = 37 
    case acousticSnare    = 38 
    case handClap         = 39 
    case electricSnare    = 40 
    case lowFloorTom      = 41 
    case closedHiHat      = 42 
    case highFloorTom     = 43 
    case pedalHiHat       = 44 
    case lowTom           = 45 
    case openHiHat        = 46 
    case lowMidTom        = 47 
    case hiMidTom         = 48 
    case crashCymbal1     = 49 
    case highTom          = 50 
    case rideCymbal1      = 51 
    case chineseCymbal    = 52 
    case rideBell         = 53 
    case tambourine       = 54 
    case splashCymbal     = 55 
    case cowbell          = 56 
    case crashCymbal2     = 57 
    case vibraslap        = 58 
    case rideCymbal2      = 59 
    case hiBongo          = 60 
    case lowBongo         = 61 
    case muteHiConga      = 62 
    case openHiConga      = 63 
    case lowConga         = 64 
    case highTimbale      = 65 
    case lowTimbale       = 66 
    case highAgogo        = 67 
    case lowAgogo         = 68 
    case cabasa           = 69 
    case maracas          = 70 
    case shortWhistle     = 71 
    case longWhistle      = 72 
    case shortGuiro       = 73 
    case longGuiro        = 74 
    case claves           = 75 
    case hiWoodBlock      = 76 
    case lowWoodBlock     = 77 
    case muteCuica        = 78 
    case openCuica        = 79 
    case muteTriangle     = 80 
    case openTriangle     = 81 


    var displayName: String {
      switch self {
        case .acousticBassDrum:  return "Acoustic Bass Drum"
        case .bassDrum1:         return "Bass Drum 1"
        case .sideStick:         return "Side Stick"
        case .acousticSnare:     return "Acoustic Snare"
        case .handClap:          return "Hand Clap"
        case .electricSnare:     return "Electric Snare"
        case .lowFloorTom:       return "Low Floor Tom"
        case .closedHiHat:       return "Closed Hi-Hat"
        case .highFloorTom:      return "High Floor Tom"
        case .pedalHiHat:        return "Pedal Hi-Hat"
        case .lowTom:            return "Low Tom"
        case .openHiHat:         return "Open Hi-Hat"
        case .lowMidTom:         return "Low-Mid Tom"
        case .hiMidTom:          return "High-Mid Tom"
        case .crashCymbal1:      return "Crash Cymbal 1"
        case .highTom:           return "High Tom"
        case .rideCymbal1:       return "Ride Cymbal 1"
        case .chineseCymbal:     return "Chinese Cymbal"
        case .rideBell:          return "Ride Bell"
        case .tambourine:        return "Tambourine"
        case .splashCymbal:      return "Splash Cymbal"
        case .cowbell:           return "Cowbell"
        case .crashCymbal2:      return "Crash Cymbal 2"
        case .vibraslap:         return "Vibraslap"
        case .rideCymbal2:       return "Ride Cymbal 2"
        case .hiBongo:           return "Hi Bongo"
        case .lowBongo:          return "Low Bongo"
        case .muteHiConga:       return "Mute Hi Conga"
        case .openHiConga:       return "Open Hi Conga"
        case .lowConga:          return "Low Conga"
        case .highTimbale:       return "High Timbale"
        case .lowTimbale:        return "Low Timbale"
        case .highAgogo:         return "High Agogo"
        case .lowAgogo:          return "Low Agogo"
        case .cabasa:            return "Cabasa"
        case .maracas:           return "Maracas"
        case .shortWhistle:      return "Short Whistle"
        case .longWhistle:       return "Long Whistle"
        case .shortGuiro:        return "Short Guiro"
        case .longGuiro:         return "Long Guiro"
        case .claves:            return "Claves"
        case .hiWoodBlock:       return "Hi Wood Block"
        case .lowWoodBlock:      return "Low Wood Block"
        case .muteCuica:         return "Mute Cuica"
        case .openCuica:         return "Open Cuica"
        case .muteTriangle:      return "Mute Triangle"
        case .openTriangle:      return "Open Triangle"
      }
    }
  }

}
