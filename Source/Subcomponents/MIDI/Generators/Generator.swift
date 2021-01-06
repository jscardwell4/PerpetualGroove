//
//  Generator.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/13/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file
import CoreMIDI

public protocol Generator: LosslessJSONValueConvertible {

  var duration: Duration { get set }
  var velocity: Velocity { get set }
  var octave:   Octave   { get set }
  var root:     Note     { get set }

  func sendNoteOn (outPort: MIDIPortRef, endPoint: MIDIEndpointRef, ticks: UInt64) throws
  func sendNoteOff(outPort: MIDIPortRef, endPoint: MIDIEndpointRef, ticks: UInt64) throws

  func receiveNoteOn (endPoint: MIDIEndpointRef, identifier: UInt, ticks: UInt64) throws
  func receiveNoteOff(endPoint: MIDIEndpointRef, identifier: UInt, ticks: UInt64) throws

}

public enum AnyGenerator {
  case note (NoteGenerator)
  case chord (ChordGenerator)

  public init() { self = .note(NoteGenerator()) }

  public init<M:Generator>(_ generator: M) {
    switch generator {
      case let generator as NoteGenerator:  self = .note(generator)
      case let generator as ChordGenerator: self = .chord(generator)
      case let generator as AnyGenerator:  self = generator
      default:                              fatalError("Unknown generator type provided")
    }
  }

  fileprivate var generator: Generator {
    switch self {
      case .note(let generator): return generator
      case .chord(let generator): return generator
    }
  }
}

extension AnyGenerator: Generator {

  public var duration: Duration {
    get { return generator.duration }
    set {
      switch generator {
        case var generator as NoteGenerator: generator.duration = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator.duration = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  public var velocity: Velocity {
    get { return generator.velocity }
    set {
      switch generator {
        case var generator as NoteGenerator: generator.velocity = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator.velocity = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  public var octave: Octave {
    get { return generator.octave }
    set {
      switch generator {
        case var generator as NoteGenerator: generator.octave = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator.octave = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  public var root: Note {
    get { return generator.root }
    set {
      switch generator {
        case var generator as NoteGenerator: generator.root = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator.root = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  public func receiveNoteOn(endPoint: MIDIEndpointRef, identifier: UInt, ticks: UInt64) throws {
    try generator.receiveNoteOn(endPoint: endPoint, identifier: identifier, ticks: ticks)
  }


  public func receiveNoteOff(endPoint: MIDIEndpointRef, identifier: UInt, ticks: UInt64) throws {
    try generator.receiveNoteOff(endPoint: endPoint, identifier: identifier, ticks: ticks)
  }

  public func sendNoteOn(outPort: MIDIPortRef, endPoint: MIDIEndpointRef, ticks: UInt64) throws {
    try generator.sendNoteOn(outPort: outPort, endPoint: endPoint, ticks: ticks)
  }

  public func sendNoteOff(outPort: MIDIPortRef, endPoint: MIDIEndpointRef, ticks: UInt64) throws {
    try generator.sendNoteOff(outPort: outPort, endPoint: endPoint, ticks: ticks)
  }

}

extension AnyGenerator: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
      case .note(let generator):  generator.hash(into: &hasher)
      case .chord(let generator): generator.hash(into: &hasher)
    }
  }

  public static func ==(lhs: AnyGenerator, rhs: AnyGenerator) -> Bool {
    switch (lhs, rhs) {
      case let (.note(generator1), .note(generator2)) where generator1 == generator2:   return true
      case let (.chord(generator1), .chord(generator2)) where generator1 == generator2: return true
      default:                                                                          return false
    }
  }

}

extension AnyGenerator: LosslessJSONValueConvertible {

  public var jsonValue: JSONValue { return generator.jsonValue }

  public init?(_ jsonValue: JSONValue?) {
    if let generator = NoteGenerator(jsonValue) { self = .note(generator) }
    else if let generator = ChordGenerator(jsonValue) { self = .chord(generator) }
    else { return nil }
  }

}
