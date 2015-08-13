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

  /**
  logStatus:

  - parameter status: OSStatus
  */
  static func logStatus(status: OSStatus, @autoclosure _ message: () -> String) {
    let statusDescription: String
    switch status {
      case kMIDIInvalidClient:     statusDescription = "Invalid Client"
      case kMIDIInvalidPort:       statusDescription = "Invalid Port"
      case kMIDIWrongEndpointType: statusDescription = "Wrong Endpoint Type"
      case kMIDINoConnection:      statusDescription = "No Connection"
      case kMIDIUnknownEndpoint:   statusDescription = "Unknown Endpoint"
      case kMIDIUnknownProperty:   statusDescription = "Unknown Property"
      case kMIDIWrongPropertyType: statusDescription = "Wrong Property Type"
      case kMIDINoCurrentSetup:    statusDescription = "No Current Setup"
      case kMIDIMessageSendErr:    statusDescription = "Message Send Err"
      case kMIDIServerStartErr:    statusDescription = "Server Start Err"
      case kMIDISetupFormatErr:    statusDescription = "Setup Format Err"
      case kMIDIWrongThread:       statusDescription = "Wrong Thread"
      case kMIDIObjectNotFound:    statusDescription = "Object Not Found"
      case kMIDIIDNotUnique:       statusDescription = "ID Not Unique"
     
      case kAudioUnitErr_InvalidProperty:          statusDescription = "Invalid Property"
      case kAudioUnitErr_InvalidParameter:         statusDescription = "Invalid Parameter"
      case kAudioUnitErr_InvalidElement:           statusDescription = "Invalid Element"
      case kAudioUnitErr_NoConnection:             statusDescription = "No Connection"
      case kAudioUnitErr_FailedInitialization:     statusDescription = "Failed Initialization"
      case kAudioUnitErr_TooManyFramesToProcess:   statusDescription = "Too Many Frames To Process"
      case kAudioUnitErr_InvalidFile:              statusDescription = "Invalid File"
      case kAudioUnitErr_UnknownFileType:          statusDescription = "Unknown File Type"
      case kAudioUnitErr_FileNotSpecified:         statusDescription = "File Not Specified"
      case kAudioUnitErr_FormatNotSupported:       statusDescription = "Format Not Supported"
      case kAudioUnitErr_Uninitialized:            statusDescription = "Uninitialized"
      case kAudioUnitErr_InvalidScope:             statusDescription = "Invalid Scope"
      case kAudioUnitErr_PropertyNotWritable:      statusDescription = "Property Not Writable"
      case kAudioUnitErr_CannotDoInCurrentContext: statusDescription = "Cannot Do In Current Context"
      case kAudioUnitErr_InvalidPropertyValue:     statusDescription = "Invalid Property Value"
      case kAudioUnitErr_PropertyNotInUse:         statusDescription = "Property Not In Use"
      case kAudioUnitErr_Initialized:              statusDescription = "Initialized"
      case kAudioUnitErr_InvalidOfflineRender:     statusDescription = "Invalid Offline Render"
      case kAudioUnitErr_Unauthorized:             statusDescription = "Unauthorized"
      case kAudioComponentErr_InstanceInvalidated: statusDescription = "Instance Invalidated"
      
      case kAudioComponentErr_DuplicateDescription:   statusDescription = "Duplicate Description"
      case kAudioComponentErr_UnsupportedType:        statusDescription = "Unsupported Type"
      case kAudioComponentErr_TooManyInstances:       statusDescription = "Too Many Instances"
      case kAudioComponentErr_NotPermitted:           statusDescription = "Not Permitted"
      case kAudioComponentErr_InitializationTimedOut: statusDescription = "Initialization Timed Out"
      case kAudioComponentErr_InvalidFormat:          statusDescription = "Invalid Format"
      case kAudioUnitErr_IllegalInstrument:      statusDescription = "Illegal Instrument"
      case kAudioUnitErr_InstrumentTypeNotFound: statusDescription = "Instrument Type Not Found"
      
      default: statusDescription = "???"
    }
    MSLogError("\(message())…error code: \(status) - \(statusDescription)")

  }

  static private var midiClient = MIDIClientRef()
  static private var midiClientInputPort = MIDIPortRef()

  /**
  readMidiClientInput:context:

  - parameter packetList: UnsafePointer<MIDIPacketList>
  - parameter context: UnsafeMutablePointer<Void>
  */
  static func readMidiClientInput(packetList packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutablePointer<Void>) {
    MSLogDebug("packetList = \(packetList); context = \(context)")
  }

  /**
  receiveMidiClientNotification:

  - parameter notification: UnsafePointer<MIDINotification>
  */
  static func receiveMidiClientNotification(notification: UnsafePointer<MIDINotification>) {
    MSLogDebug("notification = \(notification)")
  }

  static let session = MIDINetworkSession.defaultSession()

  static func initialize() {

    session.enabled = true
    session.connectionPolicy = .Anyone
    print("network session '\(session.networkName):\(session.localName)' enabled \(session.enabled)")


    var status = MIDIClientCreateWithBlock("MIDIManager Listener", &midiClient, receiveMidiClientNotification)
    guard status == noErr else { logStatus(status, "MIDIClientCreateWithBlock"); return }

    status = MIDIInputPortCreateWithBlock(midiClient, "Input", &midiClientInputPort, readMidiClientInput)
    guard status == noErr else { logStatus(status, "MIDIInputPortCreateWithBlock"); return }

    for i in 0 ..< MIDIGetNumberOfSources() {

      let endPoint = MIDIGetSource(i)

      var name = Unmanaged<CFString>?()
      status = MIDIObjectGetStringProperty(endPoint, kMIDIPropertyName, &name)

      guard status == noErr, let endPointName = name else { logStatus(status, "MIDIObjectGetStringProperty"); continue }
      MSLogDebug("\(i): \(endPointName)")


      status = MIDIPortConnectSource(midiClientInputPort, endPoint, nil)
      guard status == noErr else { logStatus(status, "MIDIPortConnectSource"); continue }

    }


  }
  
  static let engine = AVAudioEngine()
  static let mixer = engine.mainMixerNode

  static private(set) var instruments: [Instrument] = []

  /**
  connectedInstrumentWithSoundSet:program:channel:

  - parameter soundSet: Instrument.SoundSet
  - parameter program: UInt8
  - parameter channel: UInt8

  - returns: Instrument?
  */
  static func connectedInstrumentWithSoundSet(soundSet: Instrument.SoundSet, program: UInt8, channel: UInt8) -> Instrument? {
    return instruments.filter({ $0.soundSet == soundSet && $0.program == program && $0.channel == channel }).first
  }

  /**
  connectInstrument:

  - parameter instrument: Instrument
  */
  static func connectInstrument(instrument: Instrument) {
    guard !instrument.connected else { return }
    engine.attachNode(instrument.sampler)
    engine.connect(instrument.sampler, to: mixer, format: nil)
    instruments.append(instrument)
    guard !engine.running else { return }
    do {
      try engine.start()
    } catch {
      logError(error)
    }
  }

  /**
  disconnectInstrument:

  - parameter instrument: Instrument
  */
  static func disconnectInstrument(instrument: Instrument) {
    guard let idx = instruments.indexOf(instrument) else { return }
    engine.disconnectNodeOutput(instrument.sampler)
    instruments.removeAtIndex(idx)
  }

  /** 
  Starts the audio engine if not already running
  
  - throws: Any error encountered starting `engine`
  */
  static func startEngine() throws { guard !engine.running else { return }; try engine.start() }


}