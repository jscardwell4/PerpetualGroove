//
//  MIDIGenerator.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/13/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import CoreMIDI

// MARK: - MIDIGeneratorType
protocol MIDIGeneratorType: JSONValueConvertible, JSONValueInitializable {
  var duration: Duration { get set }
  var velocity: Velocity { get set }
  var octave: Octave     { get set }
  var root: Note { get set }
  func sendNoteOn(_ outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws
  func sendNoteOff(_ outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws
  func receiveNoteOn(_ endPoint: MIDIEndpointRef, _ identifier: UInt64) throws
  func receiveNoteOff(_ endPoint: MIDIEndpointRef, _ identifier: UInt64) throws
}

enum MIDIGenerator {
  case note (NoteGenerator)
  case chord (ChordGenerator)

  /**
   init:

   - parameter note: NoteGenerator
  */
  init(_ note: NoteGenerator) { self = .note(note) }

  /**
   init:

   - parameter chord: ChordGenerator
  */
  init(_ chord: ChordGenerator) { self = .chord(chord) }

  /**
   init:

   - parameter generator: M
  */
  init<M:MIDIGeneratorType>(_ generator: M) {
    switch generator {
      case let generator as NoteGenerator:  self = .note(generator)
      case let generator as ChordGenerator: self = .chord(generator)
      case let generator as MIDIGenerator:  self = generator
      default:                              fatalError("Unknown generator type provided")
    }
  }

  fileprivate var generator: MIDIGeneratorType {
    switch self {
      case .note(let generator): return generator
      case .chord(let generator): return generator
    }
  }
}

extension MIDIGenerator: MIDIGeneratorType {

  var duration: Duration {
    get { return generator.duration }
    set {
      switch generator {
        case var generator as NoteGenerator: generator.duration = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator.duration = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  var velocity: Velocity {
    get { return generator.velocity }
    set {
      switch generator {
        case var generator as NoteGenerator: generator.velocity = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator.velocity = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  var octave: Octave {
    get { return generator.octave }
    set {
      switch generator {
        case var generator as NoteGenerator: generator.octave = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator.octave = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  var root: Groove.Note {
    get { return generator.root }
    set {
      switch generator {
        case var generator as NoteGenerator: generator.root = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator.root = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  /**
   receiveNoteOn:identifier:

   - parameter endPoint: MIDIEndpointRef
   - parameter identifier: UInt64
  */
  func receiveNoteOn(_ endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
    try generator.receiveNoteOn(endPoint, identifier)
  }


  /**
   receiveNoteOff:identifier:

   - parameter endPoint: MIDIEndpointRef
   - parameter identifier: UInt64
  */
  func receiveNoteOff(_ endPoint: MIDIEndpointRef, _ identifier: UInt64) throws {
    try generator.receiveNoteOff(endPoint, identifier)
  }

  /**
   sendNoteOn:endPoint:

   - parameter outPort: MIDIPortRef
   - parameter endPoint: MIDIEndpointRef
  */
  func sendNoteOn(_ outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws {
    try generator.sendNoteOn(outPort, endPoint)
  }

  /**
   sendNoteOff:endPoint:

   - parameter outPort: MIDIPortRef
   - parameter endPoint: MIDIEndpointRef
  */
  func sendNoteOff(_ outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws {
    try generator.sendNoteOff(outPort, endPoint)
  }

}

extension MIDIGenerator: Equatable {}

func ==(lhs: MIDIGenerator, rhs: MIDIGenerator) -> Bool {
  switch (lhs, rhs) {
    case let (.note(generator1), .note(generator2)) where generator1 == generator2:   return true
    case let (.chord(generator1), .chord(generator2)) where generator1 == generator2: return true
    default:                                                                          return false
  }
}


extension MIDIGenerator: JSONValueConvertible {
  var jsonValue: JSONValue { return generator.jsonValue }
}

extension MIDIGenerator: JSONValueInitializable {
  /**
   init:

   - parameter jsonValue: JSONValue?
  */
  init?(_ jsonValue: JSONValue?) {
    if let generator = NoteGenerator(jsonValue) { self = .note(generator) }
    else if let generator = ChordGenerator(jsonValue) { self = .chord(generator) }
    else { return nil }
  }
}
