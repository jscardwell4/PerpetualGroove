//
//  StatusError.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev

// MARK: - MIDIError

/// An enumeration for `OSStatus` codes returned by `CoreMIDI`.
public enum MIDIError: OSStatus, Swift.Error, CustomStringConvertible
{
  case invalidClient = -10_830
  case invalidPort = -10_831
  case wrongEndpointType = -10_832
  case noConnection = -10_833
  case unknownEndpoint = -10_834
  case unknownProperty = -10_835
  case wrongPropertyType = -10_836
  case noCurrentSetup = -10_837
  case messageSendErr = -10_838
  case serverStartErr = -10_839
  case setupFormatErr = -10_840
  case wrongThread = -10_841
  case objectNotFound = -10_842
  case idNotUnique = -10_843
  case notPermitted = -10_844
  
  public var description: String
  {
    switch self
    {
      case .invalidClient: return "Invalid Client"
      case .invalidPort: return "Invalid Port"
      case .wrongEndpointType: return "Wrong Endpoint Type"
      case .noConnection: return "No Connection"
      case .unknownEndpoint: return "Unknown Endpoint"
      case .unknownProperty: return "Unknown Property"
      case .wrongPropertyType: return "Wrong Property Type"
      case .noCurrentSetup: return "No Current Setup"
      case .messageSendErr: return "Message Send Err"
      case .serverStartErr: return "Server Start Err"
      case .setupFormatErr: return "Setup Format Err"
      case .wrongThread: return "Wrong Thread"
      case .objectNotFound: return "Object Not Found"
      case .idNotUnique: return "ID Not Unique"
      case .notPermitted: return "Not Permitted"
    }
  }
}

// MARK: - OSStatusError

/// A catchall enumeration for `OSStatus` codes not handled `MIDIError`.
public enum OSStatusError: Swift.Error, CustomStringConvertible
{
  case osStatusCode(OSStatus)
  
  public var description: String
  {
    switch self { case let .osStatusCode(code): return "error code: \(code)" }
  }
}

// MARK: - StatusError

/// Wrapper for `MIDIError` and `OSStatusError`.
public enum StatusError: Swift.Error, CustomStringConvertible
{
  case midi(MIDIError, String)
  case osStatusCode(OSStatusError, String)
  
  public var description: String
  {
    switch self
    {
      case let .midi(error, message): return "<MIDI>\(message) - \(error)"
      case let .osStatusCode(error, message): return "\(message) - \(error)"
    }
  }
  
  public init(status: OSStatus, message: String)
  {
    if let error = MIDIError(rawValue: status)
    {
      self = StatusError.midi(error, message)
    }
    else
    {
      self = StatusError.osStatusCode(OSStatusError.osStatusCode(status), message)
    }
  }
}

/// When you absolutely, positively must succeed.
///
/// - Warning: This function is designed to throw an error should `block`
///            not return `noErr`.
///
/// - Parameters:
///   - block: The closure to execute.
///   - message: The message to pass along if `block` does not return `noErr`.
/// - Returns: The result of invoking `block`.
public func require(_ block: @autoclosure () -> OSStatus, _ message: String) throws
{
  let status = block()
  guard status == noErr else { throw StatusError(status: status, message: message) }
}

infix operator ➤

///  Compares the specified `OSStatus` code against `noErr` and throws an error when they
///  are not equal.
public func ➤ (lhs: @autoclosure () -> OSStatus, rhs: @autoclosure () -> String) throws
{
  try require(lhs(), rhs())
}
