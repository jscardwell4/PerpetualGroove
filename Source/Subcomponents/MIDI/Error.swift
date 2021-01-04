//
//  Error.swift
//  MIDI
//
//  Created by Jason Cardwell on 1/2/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation

/// An enumeration of the possible errors thrown by `MIDIFile`.
public enum Error: LocalizedError {
  case fileStructurallyUnsound (String)
  case invalidHeader (String)
  case invalidLength (String)
  case unsupportedEvent (String)
  case unsupportedFormat (String)

  public var errorDescription: String? {
    switch self {
      case .fileStructurallyUnsound: return "File structurally unsound"
      case .invalidHeader:           return "Invalid header"
      case .invalidLength:           return "Invalid length"
      case .unsupportedEvent:        return "Unsupported event"
      case .unsupportedFormat:       return "Unsupported format"
    }
  }

  public var failureReason: String? {
    switch self {
      case .fileStructurallyUnsound(let reason),
           .invalidHeader(let reason),
           .invalidLength(let reason),
           .unsupportedEvent(let reason),
           .unsupportedFormat(let reason):
        return reason
    }
  }
}

