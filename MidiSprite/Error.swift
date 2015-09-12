//
//  Error.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// MARK: - An enumeration for `OSStatus` codes returned by `CoreMIDI`
enum MIDIError: OSStatus, ErrorType, CustomStringConvertible {
  case InvalidClient      = -10830
  case InvalidPort        = -10831
  case WrongEndpointType  = -10832
  case NoConnection       = -10833
  case UnknownEndpoint    = -10834
  case UnknownProperty    = -10835
  case WrongPropertyType  = -10836
  case NoCurrentSetup     = -10837
  case MessageSendErr     = -10838
  case ServerStartErr     = -10839
  case SetupFormatErr     = -10840
  case WrongThread        = -10841
  case ObjectNotFound     = -10842
  case IDNotUnique        = -10843
  case NotPermitted       = -10844

  var description: String {
    switch self {
      case .InvalidClient:     return "Invalid Client"
      case .InvalidPort:       return "Invalid Port"
      case .WrongEndpointType: return "Wrong Endpoint Type"
      case .NoConnection:      return "No Connection"
      case .UnknownEndpoint:   return "Unknown Endpoint"
      case .UnknownProperty:   return "Unknown Property"
      case .WrongPropertyType: return "Wrong Property Type"
      case .NoCurrentSetup:    return "No Current Setup"
      case .MessageSendErr:    return "Message Send Err"
      case .ServerStartErr:    return "Server Start Err"
      case .SetupFormatErr:    return "Setup Format Err"
      case .WrongThread:       return "Wrong Thread"
      case .ObjectNotFound:    return "Object Not Found"
      case .IDNotUnique:       return "ID Not Unique"
      case .NotPermitted:      return "Not Permitted"
    }
  }
}

struct MIDIFileError: ExtendedErrorType {
  var line: Int32 = -1
  var function: String = ""
  var file: String = ""
  var _reason: String = ""
  var reason: String {
    get { return _reason.isEmpty ? type.rawValue : "\(type.rawValue): \(_reason)" }
    set { _reason = newValue }
  }
  var type: Type = .Unspecified
  init() {}

  init(type: Type,  line: Int32 = __LINE__, function: String = __FUNCTION__, file: String = __FILE__, reason: String) {
    self.init(line: line, function: function, file: file, reason: reason)
    self.type = type
  }

  enum Type: String {
    case Unspecified
    case ReadFailure
    case FileStructurallyUnsound
    case InvalidHeader
    case InvalidLength
    case UnsupportedEvent
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
enum OSStatusError: ErrorType, CustomStringConvertible {
  case OSStatusCode (OSStatus)
  var description: String { switch self { case .OSStatusCode(let code): return "error code: \(code)" } }
}

// MARK: - An enumeration to package one of the other enumeration cases along with a string to provide some context
enum Error: ErrorType, CustomStringConvertible {
  case MIDI (MIDIError, String)
//  case AudioUnit (AudioUnitError, String)
//  case AudioComponent (AudioComponentError, String)
//  case Graph (GraphError, String)
//  case Player (MusicPlayerError, String)
  case OSStatusCode (OSStatusError, String)

  var description: String {
    switch self {
      case let .MIDI(error, message):           return "<MIDI>\(message) - \(error)"
//      case let .AudioUnit(error, message):      return "<AudioUnit>\(message) - \(error)"
//      case let .AudioComponent(error, message): return "<AudioComponent>\(message) - \(error)"
//      case let .Graph(error, message):          return "<Graph>\(message) - \(error)"
//      case let .Player(error, message):         return "<Player>\(message) - \(error)"
      case let .OSStatusCode(error, message):   return "\(message) - \(error)"
    }
  }
}

// MARK: - Utility functions

/**
Function of convenience for capturing function and line information to include in an error message

- parameter function: String = __FUNCTION__
- parameter line: Int32 = __LINE__

- returns: String
*/
func location(function: String = __FUNCTION__, line: Int32 = __LINE__) -> String { return "[\(function):\(line)]" }

/**
Compares the specified `OSStatus` code against `noErr` and throws an error when they are not equal

- parameter status: OSStatus
- parameter message: () -> String
- throws: An error describing the provided `status`
*/
func checkStatus(status: OSStatus, @autoclosure _ message: () -> String) throws {
  guard status == noErr else { throw error(status, message()) }
}


/** An infix operator for `checkStatus:_:` to make code more legible */
infix operator ➤ {}
func ➤(@autoclosure lhs: () -> OSStatus, @autoclosure rhs: () -> String) throws { try checkStatus(lhs(), rhs()) }

/**
Generates an `ErrorType` for the specified `OSStatus`

- parameter code: OSStatus

- returns: ErrorType
*/
func error(code: OSStatus, @autoclosure _ message: () -> String) -> ErrorType {
  guard code != noErr else { fatalError("The irony, fatal error caused by a 'noErr' status code") }
  let error: ErrorType = MIDIError(rawValue: code)
//           ?? AudioUnitError(rawValue: code)
//           ?? AudioComponentError(rawValue: code)
//           ?? GraphError(rawValue: code)
//           ?? MusicPlayerError(rawValue: code)
           ?? OSStatusError.OSStatusCode(code)

  switch error {
    case let e as MIDIError:           return Error.MIDI(e, message())
//    case let e as AudioUnitError:      return Error.AudioUnit(e, message())
//    case let e as AudioComponentError: return Error.AudioComponent(e, message())
//    case let e as GraphError:          return Error.Graph(e, message())
//    case let e as MusicPlayerError:    return Error.Player(e, message())
    case let e as OSStatusError:       return Error.OSStatusCode(e, message())
    default:                           fatalError("this should be unreachable")
  }
}

/**
Convenience function for `try`ing something that `throws` and just logging the error when caught

- parameter throwingBlock: () throws -> Void
*/
func handle(@autoclosure throwingBlock: () throws -> Void) { do { try throwingBlock() } catch { logError(error) } }
