//
//  StatusError.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// An enumeration for `OSStatus` codes returned by `CoreMIDI`.
enum MIDIError: OSStatus, Swift.Error, CustomStringConvertible {

  case invalidClient      = -10830
  case invalidPort        = -10831
  case wrongEndpointType  = -10832
  case noConnection       = -10833
  case unknownEndpoint    = -10834
  case unknownProperty    = -10835
  case wrongPropertyType  = -10836
  case noCurrentSetup     = -10837
  case messageSendErr     = -10838
  case serverStartErr     = -10839
  case setupFormatErr     = -10840
  case wrongThread        = -10841
  case objectNotFound     = -10842
  case idNotUnique        = -10843
  case notPermitted       = -10844

  var description: String {
    switch self {
      case .invalidClient:     return "Invalid Client"
      case .invalidPort:       return "Invalid Port"
      case .wrongEndpointType: return "Wrong Endpoint Type"
      case .noConnection:      return "No Connection"
      case .unknownEndpoint:   return "Unknown Endpoint"
      case .unknownProperty:   return "Unknown Property"
      case .wrongPropertyType: return "Wrong Property Type"
      case .noCurrentSetup:    return "No Current Setup"
      case .messageSendErr:    return "Message Send Err"
      case .serverStartErr:    return "Server Start Err"
      case .setupFormatErr:    return "Setup Format Err"
      case .wrongThread:       return "Wrong Thread"
      case .objectNotFound:    return "Object Not Found"
      case .idNotUnique:       return "ID Not Unique"
      case .notPermitted:      return "Not Permitted"
    }
  }
}

/// A catchall enumeration for `OSStatus` codes not handled `MIDIError`.
enum OSStatusError: Swift.Error, CustomStringConvertible {

  case osStatusCode (OSStatus)

  var description: String { switch self { case .osStatusCode(let code): return "error code: \(code)" } }

}

/// Wrapper for `MIDIError` and `OSStatusError`.
enum StatusError: Swift.Error, CustomStringConvertible {

  case midi (MIDIError, String)
  case osStatusCode (OSStatusError, String)

  var description: String {
    switch self {
      case let .midi(error, message):
        return "<MIDI>\(message) - \(error)"
      case let .osStatusCode(error, message):
        return "\(message) - \(error)"
    }
  }

}

infix operator ➤

///  Compares the specified `OSStatus` code against `noErr` and throws an error when they are not equal.
func ➤(lhs: @autoclosure () -> OSStatus, rhs: @autoclosure () -> String) throws {

  let status = lhs()

  guard status == noErr else {

    if let error = MIDIError(rawValue: status) {

      throw StatusError.midi(error, rhs())

    } else {

      throw StatusError.osStatusCode(OSStatusError.osStatusCode(status), rhs())

    }
    
  }

}
