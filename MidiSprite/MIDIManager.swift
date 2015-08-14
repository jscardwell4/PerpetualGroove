//
//  MIDIManager.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AVFoundation
import MoonKit
import CoreMIDI
import CoreAudio
import AudioToolbox

final class MIDIManager {

  static let queue = dispatch_queue_create("midi", DISPATCH_QUEUE_SERIAL)

  static private var graph = AUGraph()
  static private var ioNode = AUNode()
  static private var ioUnit = AudioUnit()
  static private var mixerNode = AUNode()
  static private var mixerUnit = AudioUnit()

  private static var initialized = false

  /** initialize */
  static func initialize() {
    guard !initialized else { return }

    // Try to configure the audio session
    do {
      try configureAudioSession()
      try configureAudioGraph()
    } catch { logError(error); return }


  }

  /** configureAudioSession */
  private static func configureAudioSession() throws {
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(AVAudioSessionCategoryPlayback)
    try audioSession.setActive(true)
  }

  /** configureAudioGraph */
  private static func configureAudioGraph() throws {
    // Create graph
    var status = NewAUGraph(&graph)
    guard status == noErr else { throw error(status, "Failed to create new audio graph") }

    // Add node
    var ioComponentDescription = AudioComponentDescription()
    ioComponentDescription.componentType = kAudioUnitType_Output
    ioComponentDescription.componentSubType = kAudioUnitSubType_RemoteIO
    ioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple

    status = AUGraphAddNode(graph, &ioComponentDescription, &ioNode)
    guard status == noErr else { throw error(status, "Failed to add io node to audio graph") }

    var mixerComponentDescription = AudioComponentDescription()
    mixerComponentDescription.componentType = kAudioUnitType_Mixer
    mixerComponentDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer
    mixerComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple

    status = AUGraphAddNode(graph, &mixerComponentDescription, &mixerNode)
    guard status == noErr else { throw error(status, "Failed to add mixer node to audio graph") }


    // Open graph

    status = AUGraphOpen(graph)
    guard status == noErr else { throw error(status, "Failed to open audio graph") }

    // Retrieve audio units

    status = AUGraphNodeInfo(graph, ioNode, nil, &ioUnit)
    guard status == noErr else { throw error(status, "Failed to retrieve io audio unit from audio graph node") }

    status = AUGraphNodeInfo(graph, mixerNode, nil, &mixerUnit)
    guard status == noErr else { throw error(status, "Failed to retrieve mixer audio unit from audio graph node") }

    // Connect units

    status = AUGraphConnectNodeInput(graph, mixerNode, 0, ioNode, 0)
    guard status == noErr else { throw error(status, "Failed to connect mixer to io") }

    // Initialize graph

    status = AUGraphInitialize(graph)
    guard status == noErr else { throw error(status, "Failed to initialize audio graph") }

    // Start graph

    status = AUGraphStart(graph)
    guard status == noErr else { throw error(status, "Failed to start audio graph") }

    print("graph after \(__FUNCTION__)…")
    CAShow(UnsafeMutablePointer<COpaquePointer>(graph))
    print("")
  }

  static private(set) var instruments: [Instrument] = []

  /**
  connectedInstrumentWithSoundSet:program:channel:

  - parameter soundSet: Instrument.SoundSet
  - parameter program: UInt8
  - parameter channel: UInt8

  - returns: Instrument?
  */
  static func connectedInstrumentWithSoundSet(soundSet: SoundSet, program: UInt8, channel: MusicDeviceGroupID) -> Instrument? {
    return instruments.filter({ $0.soundSet == soundSet && $0.program == program && $0.channel == channel }).first
  }

  /**
  connectInstrument:

  - parameter instrument: Instrument
  */
  static func connectInstrument(instrument: Instrument) throws -> MusicDeviceComponent {
    var instrumentComponentDescription = AudioComponentDescription()
    instrumentComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple
    instrumentComponentDescription.componentType = kAudioUnitType_MusicDevice
    instrumentComponentDescription.componentSubType = kAudioUnitSubType_Sampler

    var instrumentNode = AUNode()
    var instrumentUnit = MusicDeviceComponent()
    var status = AUGraphAddNode(graph, &instrumentComponentDescription, &instrumentNode)
    guard status == noErr else { throw error(status, "Failed to add instrument node to audio graph") }

    status = AUGraphNodeInfo(graph, instrumentNode, nil, &instrumentUnit)
    guard status == noErr else { throw error(status, "Failed to retrieve instrument audio unit from audio graph node") }

    status = AUGraphConnectNodeInput(graph, instrumentNode, 0, mixerNode, UInt32(instruments.count))
    guard status == noErr else { throw error(status, "Failed to connect instrument node to output node") }

    status = AUGraphUpdate(graph, nil)
    guard status == noErr else { throw error(status, "Failed to update audio graph") }

    print("graph before \(__FUNCTION__)…")
    CAShow(UnsafeMutablePointer<COpaquePointer>(graph))
    print("")

    instruments.append(instrument)
    return instrumentUnit
  }


  // MARK: - Some error types wrapping `OSStatus` codes

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

  enum AudioUnitError: OSStatus, ErrorType, CustomStringConvertible {
    case InvalidProperty          = -10879
    case InvalidParameter         = -10878
    case InvalidElement           = -10877
    case NoConnection             = -10876
    case FailedInitialization     = -10875
    case TooManyFramesToProcess   = -10874
    case InvalidFile              = -10871
    case UnknownFileType          = -10870
    case FileNotSpecified         = -10869
    case FormatNotSupported       = -10868
    case Uninitialized            = -10867
    case InvalidScope             = -10866
    case PropertyNotWritable      = -10865
    case CannotDoInCurrentContext = -10863
    case InvalidPropertyValue     = -10851
    case PropertyNotInUse         = -10850
    case Initialized              = -10849
    case InvalidOfflineRender     = -10848
    case Unauthorized             = -10847
    case IllegalInstrument        = -10873
    case InstrumentTypeNotFound   = -10872
    
    var description: String {
      switch self {
        case .InvalidProperty:          return "Invalid Property"
        case .InvalidParameter:         return "Invalid Parameter"
        case .InvalidElement:           return "Invalid Element"
        case .NoConnection:             return "No Connection"
        case .FailedInitialization:     return "Failed Initialization"
        case .TooManyFramesToProcess:   return "Too Many Frames To Process"
        case .InvalidFile:              return "Invalid File"
        case .UnknownFileType:          return "Unknown File Type"
        case .FileNotSpecified:         return "File Not Specified"
        case .FormatNotSupported:       return "Format Not Supported"
        case .Uninitialized:            return "Uninitialized"
        case .InvalidScope:             return "Invalid Scope"
        case .PropertyNotWritable:      return "Property Not Writable"
        case .CannotDoInCurrentContext: return "Cannot Do In Current Context"
        case .InvalidPropertyValue:     return "Invalid Property Value"
        case .PropertyNotInUse:         return "Property Not In Use"
        case .Initialized:              return "Initialized"
        case .InvalidOfflineRender:     return "Invalid Offline Render"
        case .Unauthorized:             return "Unauthorized"
        case .IllegalInstrument:        return "Illegal Instrument"
        case .InstrumentTypeNotFound:   return "Instrument Type Not Found"        
      }
    }
  }

  enum AudioComponentError: OSStatus, ErrorType, CustomStringConvertible {
    case InstanceInvalidated    = -66749
    case DuplicateDescription   = -66752
    case UnsupportedType        = -66751
    case TooManyInstances       = -66750
    case NotPermitted           = -66748
    case InitializationTimedOut = -66747
    case InvalidFormat          = -66746
    
    var description: String {
      switch self {
        case .InstanceInvalidated:    return "Instance Invalidated"
        case .DuplicateDescription:   return "Duplicate Description"
        case .UnsupportedType:        return "Unsupported Type"
        case .TooManyInstances:       return "Too Many Instances"
        case .NotPermitted:           return "Not Permitted"
        case .InitializationTimedOut: return "Initialization Timed Out"
        case .InvalidFormat:          return "Invalid Format"
      }
    }
  }

  enum GraphError: OSStatus, ErrorType, CustomStringConvertible {
    case NodeNotFound             = -10860
    case InvalidConnection        = -10861
    case OutputNodeErr            = -10862
    case CannotDoInCurrentContext = -10863
    case InvalidAudioUnit         = -10864

    var description: String {
      switch self {
        case .NodeNotFound:             return "Node Not Found"
        case .InvalidConnection:        return "Invalid Connection"
        case .OutputNodeErr:            return "Output Node Err"
        case .CannotDoInCurrentContext: return "Cannot Do In Current Context"
        case .InvalidAudioUnit:         return "Invalid Audio Unit"
      }
    }
  }

  enum OSStatusError: ErrorType, CustomStringConvertible {
    case OSStatusCode (OSStatus)
    var description: String { switch self { case .OSStatusCode(let code): return "error code: \(code)" } }
  }

  enum Error: ErrorType, CustomStringConvertible {
    case MIDI (MIDIError, String)
    case AudioUnit (AudioUnitError, String)
    case AudioComponent (AudioComponentError, String)
    case Graph (GraphError, String)
    case OSStatusCode (OSStatusError, String)

    var description: String {
      switch self {
        case let .MIDI(error, message):           return "<MIDI>\(message) - \(error)"
        case let .AudioUnit(error, message):      return "<AudioUnit>\(message) - \(error)"
        case let .AudioComponent(error, message): return "<AudioComponent>\(message) - \(error)"
        case let .Graph(error, message):          return "<Graph>\(message) - \(error)"
        case let .OSStatusCode(error, message):   return "\(message) - \(error)"
      }
    }
  }

  /**
  error:

  - parameter code: OSStatus

  - returns: ErrorType
  */
  static func error(code: OSStatus, @autoclosure _ message: () -> String) -> ErrorType {
    let error: ErrorType = MIDIError(rawValue: code)
             ?? AudioUnitError(rawValue: code)
             ?? AudioComponentError(rawValue: code)
             ?? GraphError(rawValue: code)
             ?? OSStatusError.OSStatusCode(code)

    switch error {
      case let e as MIDIError:           return Error.MIDI(e, message())
      case let e as AudioUnitError:      return Error.AudioUnit(e, message())
      case let e as AudioComponentError: return Error.AudioComponent(e, message())
      case let e as GraphError:          return Error.Graph(e, message())
      case let e as OSStatusError:       return Error.OSStatusCode(e, message())
      default:                           fatalError("this should be unreachable")
    }
  }

}