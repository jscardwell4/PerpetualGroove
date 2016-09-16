//
//  Error.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// MARK: - An enumeration for `OSStatus` codes returned by `CoreMIDI`
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

struct MIDIFileError: ExtendedErrorType {
  var line: UInt = 0
  var function: String = ""
  var file: String = ""
  var _reason: String = ""
  var reason: String {
    get { return _reason.isEmpty ? type.rawValue : "\(type.rawValue): \(_reason)" }
    set { _reason = newValue }
  }
  var type: `Type` = .unspecified
  var name: String { return type.rawValue }
  init() {}

  init(type: `Type`,  line: UInt = #line, function: String = #function, file: String = #file, reason: String) {
    self.init(line: line, function: function, file: file, reason: reason)
    self.type = type
  }

  enum `Type`: String {
    case unspecified
    case readFailure
    case fileStructurallyUnsound
    case invalidHeader
    case invalidLength
    case unsupportedEvent
    case missingEvent
  }
}

// MARK: - An enumeration for `OSStatus` codes returned by `AudioUnit`
//enum AudioUnitError: OSStatus, ErrorType, CustomStringConvertible {
//  case InvalidProperty          = -10879
//  case InvalidParameter         = -10878
//  case InvalidElement           = -10877
//  case NoConnection             = -10876
//  case FailedInitialization     = -10875
//  case TooManyFramesToProcess   = -10874
//  case InvalidFile              = -10871
//  case UnknownFileType          = -10870
//  case FileNotSpecified         = -10869
//  case FormatNotSupported       = -10868
//  case Uninitialized            = -10867
//  case InvalidScope             = -10866
//  case PropertyNotWritable      = -10865
//  case CannotDoInCurrentContext = -10863
//  case InvalidPropertyValue     = -10851
//  case PropertyNotInUse         = -10850
//  case Initialized              = -10849
//  case InvalidOfflineRender     = -10848
//  case Unauthorized             = -10847
//  case IllegalInstrument        = -10873
//  case InstrumentTypeNotFound   = -10872
//  
//  var description: String {
//    switch self {
//      case .InvalidProperty:          return "Invalid Property"
//      case .InvalidParameter:         return "Invalid Parameter"
//      case .InvalidElement:           return "Invalid Element"
//      case .NoConnection:             return "No Connection"
//      case .FailedInitialization:     return "Failed Initialization"
//      case .TooManyFramesToProcess:   return "Too Many Frames To Process"
//      case .InvalidFile:              return "Invalid File"
//      case .UnknownFileType:          return "Unknown File Type"
//      case .FileNotSpecified:         return "File Not Specified"
//      case .FormatNotSupported:       return "Format Not Supported"
//      case .Uninitialized:            return "Uninitialized"
//      case .InvalidScope:             return "Invalid Scope"
//      case .PropertyNotWritable:      return "Property Not Writable"
//      case .CannotDoInCurrentContext: return "Cannot Do In Current Context"
//      case .InvalidPropertyValue:     return "Invalid Property Value"
//      case .PropertyNotInUse:         return "Property Not In Use"
//      case .Initialized:              return "Initialized"
//      case .InvalidOfflineRender:     return "Invalid Offline Render"
//      case .Unauthorized:             return "Unauthorized"
//      case .IllegalInstrument:        return "Illegal Instrument"
//      case .InstrumentTypeNotFound:   return "Instrument Type Not Found"        
//    }
//  }
//}

// MARK: - An enumeration for `OSStatus` codes returned by `AudioComponent`
//enum AudioComponentError: OSStatus, ErrorType, CustomStringConvertible {
//  case InstanceInvalidated    = -66749
//  case DuplicateDescription   = -66752
//  case UnsupportedType        = -66751
//  case TooManyInstances       = -66750
//  case NotPermitted           = -66748
//  case InitializationTimedOut = -66747
//  case InvalidFormat          = -66746
//  
//  var description: String {
//    switch self {
//      case .InstanceInvalidated:    return "Instance Invalidated"
//      case .DuplicateDescription:   return "Duplicate Description"
//      case .UnsupportedType:        return "Unsupported Type"
//      case .TooManyInstances:       return "Too Many Instances"
//      case .NotPermitted:           return "Not Permitted"
//      case .InitializationTimedOut: return "Initialization Timed Out"
//      case .InvalidFormat:          return "Invalid Format"
//    }
//  }
//}

// MARK: - An enumeration for `OSStatus` codes returned by `AUGraph`
//enum GraphError: OSStatus, ErrorType, CustomStringConvertible {
//  case NodeNotFound             = -10860
//  case InvalidConnection        = -10861
//  case OutputNodeErr            = -10862
//  case CannotDoInCurrentContext = -10863
//  case InvalidAudioUnit         = -10864
//
//  var description: String {
//    switch self {
//      case .NodeNotFound:             return "Node Not Found"
//      case .InvalidConnection:        return "Invalid Connection"
//      case .OutputNodeErr:            return "Output Node Err"
//      case .CannotDoInCurrentContext: return "Cannot Do In Current Context"
//      case .InvalidAudioUnit:         return "Invalid Audio Unit"
//    }
//  }
//}

// MARK: - An enumeration for `OSStatus` codes returned by `MusicPlayer`
//enum MusicPlayerError: OSStatus, ErrorType, CustomStringConvertible {
//  case InvalidSequenceType      = -10846
//  case TrackIndexError          = -10859
//  case TrackNotFound            = -10858
//  case EndOfTrack               = -10857
//  case StartOfTrack             = -10856
//  case IllegalTrackDestination  = -10855
//  case NoSequence               = -10854
//  case InvalidEventType         = -10853
//  case InvalidPlayerState       = -10852
//  case CannotDoInCurrentContext = -10863
//  case NoTrackDestination       = -66720
//
//  var description: String {
//    switch self {
//      case .InvalidSequenceType:      return "Invalid Sequence Type"
//      case .TrackIndexError:          return "Track Index Error"
//      case .TrackNotFound:            return "Track Not Found"
//      case .EndOfTrack:               return "End Of Track"
//      case .StartOfTrack:             return "Start Of Track"
//      case .IllegalTrackDestination:  return "Illegal Track Destination"
//      case .NoSequence:               return "No Sequence"
//      case .InvalidEventType:         return "Invalid Event Type"
//      case .InvalidPlayerState:       return "Invalid Player State"
//      case .CannotDoInCurrentContext: return "Cannot Do In Current Context"
//      case .NoTrackDestination:       return "No Track Destination"
//    }
//  }
//}

// MARK: - An catchall enumeration for `OSStatus` codes not handled by the other enumerations
enum OSStatusError: Swift.Error, CustomStringConvertible {
  case osStatusCode (OSStatus)
  var description: String { switch self { case .osStatusCode(let code): return "error code: \(code)" } }
}

// MARK: - An enumeration to package one of the other enumeration cases along with a string to provide some context
enum Error: Swift.Error, CustomStringConvertible {
  case midi (MIDIError, String)
//  case AudioUnit (AudioUnitError, String)
//  case AudioComponent (AudioComponentError, String)
//  case Graph (GraphError, String)
//  case Player (MusicPlayerError, String)
  case osStatusCode (OSStatusError, String)

  var description: String {
    switch self {
      case let .midi(error, message):           return "<MIDI>\(message) - \(error)"
//      case let .AudioUnit(error, message):      return "<AudioUnit>\(message) - \(error)"
//      case let .AudioComponent(error, message): return "<AudioComponent>\(message) - \(error)"
//      case let .Graph(error, message):          return "<Graph>\(message) - \(error)"
//      case let .Player(error, message):         return "<Player>\(message) - \(error)"
      case let .osStatusCode(error, message):   return "\(message) - \(error)"
    }
  }
}

// MARK: - Utility functions

/**
Function of convenience for capturing function and line information to include in an error message

- parameter function: String = #function
- parameter line: Int32 = #line

- returns: String
*/
func location(_ function: String = #function, line: Int32 = #line) -> String {
  return "[\(function):\(line)]"
}

/**
Compares the specified `OSStatus` code against `noErr` and throws an error when they are not equal

- parameter status: OSStatus
- parameter message: () -> String
- throws: An error describing the provided `status`
*/
func checkStatus(_ status: OSStatus, _ message: @autoclosure () -> String) throws {
  guard status == noErr else { throw error(status, message()) }
}


/** An infix operator for `checkStatus:_:` to make code more legible */
infix operator ➤
func ➤(lhs: @autoclosure () -> OSStatus, rhs: @autoclosure () -> String) throws { try checkStatus(lhs(), rhs()) }

/**
Generates an `ErrorType` for the specified `OSStatus`

- parameter code: OSStatus

- returns: ErrorType
*/
func error(_ code: OSStatus, _ message: @autoclosure () -> String) -> Swift.Error {
  guard code != noErr else { fatalError("The irony, fatal error caused by a 'noErr' status code") }
  let error: Swift.Error = MIDIError(rawValue: code)
//           ?? AudioUnitError(rawValue: code)
//           ?? AudioComponentError(rawValue: code)
//           ?? GraphError(rawValue: code)
//           ?? MusicPlayerError(rawValue: code)
           ?? OSStatusError.osStatusCode(code)

  switch error {
    case let e as MIDIError:           return Error.midi(e, message())
//    case let e as AudioUnitError:      return Error.AudioUnit(e, message())
//    case let e as AudioComponentError: return Error.AudioComponent(e, message())
//    case let e as GraphError:          return Error.Graph(e, message())
//    case let e as MusicPlayerError:    return Error.Player(e, message())
    case let e as OSStatusError:       return Error.osStatusCode(e, message())
    default:                           fatalError("this should be unreachable")
  }
}

/**
Convenience function for `try`ing something that `throws` and just logging the error when caught

- parameter throwingBlock: () throws -> Void
*/
func handle(_ throwingBlock: @autoclosure () throws -> Void) { do { try throwingBlock() } catch { logError(error) } }
