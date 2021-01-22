//
//  Generator.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/13/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonDev

// TODO: Review file
import CoreMIDI

// MARK: - Generator

public protocol Generator: Codable
{
  var duration: Duration { get set }
  var velocity: Velocity { get set }
  var octave: Octave { get set }
  var root: Note { get set }

  func sendNoteOn(outPort: MIDIPortRef, endPoint: MIDIEndpointRef, ticks: UInt64) throws
  func sendNoteOff(outPort: MIDIPortRef, endPoint: MIDIEndpointRef, ticks: UInt64) throws

  func receiveNoteOn(endPoint: MIDIEndpointRef, identifier: UInt, ticks: UInt64) throws
  func receiveNoteOff(endPoint: MIDIEndpointRef, identifier: UInt, ticks: UInt64) throws
}

// MARK: - AnyGenerator

public enum AnyGenerator
{
  case note(NoteGenerator)
  case chord(ChordGenerator)

  public init() { self = .note(NoteGenerator()) }

  public init<M: Generator>(_ generator: M)
  {
    switch generator
    {
      case let generator as NoteGenerator: self = .note(generator)
      case let generator as ChordGenerator: self = .chord(generator)
      case let generator as AnyGenerator: self = generator
      default: fatalError("Unknown generator type provided")
    }
  }

  fileprivate var generator: Generator
  {
    switch self
    {
      case let .note(generator): return generator
      case let .chord(generator): return generator
    }
  }
}

// MARK: Generator

extension AnyGenerator: Generator
{
  public var duration: Duration
  {
    get { return generator.duration }
    set
    {
      switch generator
      {
        case var generator as NoteGenerator: generator
        .duration = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator
        .duration = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  public var velocity: Velocity
  {
    get { return generator.velocity }
    set
    {
      switch generator
      {
        case var generator as NoteGenerator: generator
        .velocity = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator
        .velocity = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  public var octave: Octave
  {
    get { return generator.octave }
    set
    {
      switch generator
      {
        case var generator as NoteGenerator: generator
        .octave = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator
        .octave = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  public var root: Note
  {
    get { return generator.root }
    set
    {
      switch generator
      {
        case var generator as NoteGenerator: generator
        .root = newValue; self = .note(generator)
        case var generator as ChordGenerator: generator
        .root = newValue; self = .chord(generator)
        default: break
      }
    }
  }

  public func receiveNoteOn(
    endPoint: MIDIEndpointRef,
    identifier: UInt,
    ticks: UInt64
  ) throws
  {
    try generator.receiveNoteOn(endPoint: endPoint, identifier: identifier, ticks: ticks)
  }

  public func receiveNoteOff(
    endPoint: MIDIEndpointRef,
    identifier: UInt,
    ticks: UInt64
  ) throws
  {
    try generator.receiveNoteOff(endPoint: endPoint, identifier: identifier, ticks: ticks)
  }

  public func sendNoteOn(
    outPort: MIDIPortRef,
    endPoint: MIDIEndpointRef,
    ticks: UInt64
  ) throws
  {
    try generator.sendNoteOn(outPort: outPort, endPoint: endPoint, ticks: ticks)
  }

  public func sendNoteOff(
    outPort: MIDIPortRef,
    endPoint: MIDIEndpointRef,
    ticks: UInt64
  ) throws
  {
    try generator.sendNoteOff(outPort: outPort, endPoint: endPoint, ticks: ticks)
  }
}

// MARK: Hashable

extension AnyGenerator: Hashable
{
  public func hash(into hasher: inout Hasher)
  {
    switch self
    {
      case let .note(generator): generator.hash(into: &hasher)
      case let .chord(generator): generator.hash(into: &hasher)
    }
  }

  public static func == (lhs: AnyGenerator, rhs: AnyGenerator) -> Bool
  {
    switch (lhs, rhs)
    {
      case let (.note(generator1), .note(generator2))
      where generator1 == generator2: return true
      case let (.chord(generator1), .chord(generator2))
      where generator1 == generator2: return true
      default: return false
    }
  }
}

// MARK: Codable

extension AnyGenerator: Codable
{
  public enum Error: String, Swift.Error { case decodingError }

  private enum CodingKeys: String, CodingKey { case note, chord }

  public func encode(to encoder: Encoder) throws
  {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self
    {
      case let .note(generator):
        try container.encode(generator, forKey: .note)
      case let .chord(generator):
        try container.encode(generator, forKey: .chord)
    }
  }

  public init(from decoder: Decoder) throws
  {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let generator = try container.decodeIfPresent(NoteGenerator.self, forKey: .note)
    {
      self = .note(generator)
    }
    else if let generator = try container.decodeIfPresent(
      ChordGenerator.self,
      forKey: .chord
    )
    {
      self = .chord(generator)
    }
    else
    {
      throw Error.decodingError
    }
  }
}

//// MARK: LosslessJSONValueConvertible
//
// extension AnyGenerator: LosslessJSONValueConvertible
// {
//  public var jsonValue: JSONValue { return generator.jsonValue }
//
//  public init?(_ jsonValue: JSONValue?)
//  {
//    if let generator = NoteGenerator(jsonValue) { self = .note(generator) }
//    else if let generator = ChordGenerator(jsonValue) { self = .chord(generator) }
//    else { return nil }
//  }
// }
