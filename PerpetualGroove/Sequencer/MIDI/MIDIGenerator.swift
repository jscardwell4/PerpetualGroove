//
//  MIDIGenerator.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/13/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file
import CoreMIDI

protocol MIDIGenerator: LosslessJSONValueConvertible {

  var duration: Duration { get set }
  var velocity: Velocity { get set }
  var octave:   Octave   { get set }
  var root:     Note     { get set }

  func sendNoteOn (outPort: MIDIPortRef, endPoint: MIDIEndpointRef) throws
  func sendNoteOff(outPort: MIDIPortRef, endPoint: MIDIEndpointRef) throws

  func receiveNoteOn (endPoint: MIDIEndpointRef, identifier: UInt) throws
  func receiveNoteOff(endPoint: MIDIEndpointRef, identifier: UInt) throws

}

enum AnyMIDIGenerator {
  case note (NoteGenerator)
  case chord (ChordGenerator)

  init() { self = .note(NoteGenerator()) }

  init<M:MIDIGenerator>(_ generator: M) {
    switch generator {
      case let generator as NoteGenerator:  self = .note(generator)
      case let generator as ChordGenerator: self = .chord(generator)
      case let generator as AnyMIDIGenerator:  self = generator
      default:                              fatalError("Unknown generator type provided")
    }
  }

  fileprivate var generator: MIDIGenerator {
    switch self {
      case .note(let generator): return generator
      case .chord(let generator): return generator
    }
  }
}

extension AnyMIDIGenerator: MIDIGenerator {

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

  var root: Note {
    get { return generator.root }
    set {
      switch generator {
        case var generator as NoteGenerator: generator.root = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator.root = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  func receiveNoteOn(endPoint: MIDIEndpointRef, identifier: UInt) throws {
    try generator.receiveNoteOn(endPoint: endPoint, identifier: identifier)
  }


  func receiveNoteOff(endPoint: MIDIEndpointRef, identifier: UInt) throws {
    try generator.receiveNoteOff(endPoint: endPoint, identifier: identifier)
  }

  func sendNoteOn(outPort: MIDIPortRef, endPoint: MIDIEndpointRef) throws {
    try generator.sendNoteOn(outPort: outPort, endPoint: endPoint)
  }

  func sendNoteOff(outPort: MIDIPortRef, endPoint: MIDIEndpointRef) throws {
    try generator.sendNoteOff(outPort: outPort, endPoint: endPoint)
  }

}

extension AnyMIDIGenerator: Hashable {

  var hashValue: Int {
    switch self {
      case .note(let generator):  return generator.hashValue
      case .chord(let generator): return generator.hashValue
    }
  }

  static func ==(lhs: AnyMIDIGenerator, rhs: AnyMIDIGenerator) -> Bool {
    switch (lhs, rhs) {
      case let (.note(generator1), .note(generator2)) where generator1 == generator2:   return true
      case let (.chord(generator1), .chord(generator2)) where generator1 == generator2: return true
      default:                                                                          return false
    }
  }

}

extension AnyMIDIGenerator: LosslessJSONValueConvertible {

  var jsonValue: JSONValue { return generator.jsonValue }

  init?(_ jsonValue: JSONValue?) {
    if let generator = NoteGenerator(jsonValue) { self = .note(generator) }
    else if let generator = ChordGenerator(jsonValue) { self = .chord(generator) }
    else { return nil }
  }

}
