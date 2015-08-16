//
//  Mixer.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import AudioToolbox
import AudioUnit

final class Mixer {

  static private(set) var tracks: [TrackType] = [MasterTrack.sharedInstance]

  static var instrumentTracks: [InstrumentTrack] {
    guard tracks.count > 1, let instrumentTracks = Array(tracks[1..<]) as? [InstrumentTrack] else { return [] }
    return instrumentTracks
  }

  static var instruments: [Instrument] { return instrumentTracks.map { $0.instrument } }

  // MARK: - Type for Mixer-specific errors

  enum Error: String, ErrorType, CustomStringConvertible {
    case GraphOpen = "The graph provided has already been opened"
    case GraphNotOpen = "The graph provided has not already been opened"
    case IOUnitNotFound = "Failed to find an appropriate IO audio unit"

    var description: String { return rawValue }
  }

  // MARK: - Initializing the audio unit

  private static var mixerComponentDescription = AudioComponentDescription(
    componentType: kAudioUnitType_Mixer,
    componentSubType: kAudioUnitSubType_MultiChannelMixer,
    componentManufacturer: kAudioUnitManufacturer_Apple,
    componentFlags: 0,
    componentFlagsMask: 0
  )

  private static var mixerNode = AUNode()
  private static var mixerUnit = AudioUnit()

  /**
  addNodeToGraph:connectingOutputTo:

  - parameter graph: AUGraph
  - parameter node: AUNode
  */
  static func addNodeToGraph(graph: AUGraph) throws {
    var isOpen = DarwinBoolean(false)
    try checkStatus(AUGraphIsOpen(graph, &isOpen), "Failed to determine whether graph has been opened")
    guard !isOpen else { throw Error.GraphOpen }
    try checkStatus(AUGraphAddNode(graph, &mixerComponentDescription, &mixerNode), "Failed to add mixer node to audio graph")
  }

  /**
  configureMixerUnitInGraph:

  - parameter graph: AUGraph
  */
  static func configureMixerUnitInGraph(graph: AUGraph, outputNode: AUNode) throws {
    var isOpen = DarwinBoolean(false)
    try checkStatus(AUGraphIsOpen(graph, &isOpen), "Failed to determine whether graph has been opened")
    guard isOpen else { throw Error.GraphNotOpen }
    try checkStatus(AUGraphNodeInfo(graph, mixerNode, nil, &mixerUnit), "Failed to retrieve mixer audio unit from audio graph")
    var maxFrames = UInt32(4096)
    try checkStatus(
      AudioUnitSetProperty(mixerUnit,
                          kAudioUnitProperty_MaximumFramesPerSlice,
                          AudioUnitScope(kAudioUnitScope_Global),
                          0,
                          &maxFrames,
                          UInt32(sizeof(UInt32.self))),
      "Failed to set maximum frames per slice on mixer unit"
    )

    try checkStatus(AUGraphConnectNodeInput(graph, mixerNode, 0, outputNode, 0), "Failed to connect mixer output to io input" )
  }

  // MARK: - Adding tracks

  /**
  existingTrackForInstrumentWithDescription:

  - parameter description: InstrumentDescription

  - returns: InstrumentTrack?
  */
  static func existingTrackForInstrumentWithDescription(description: InstrumentDescription) -> InstrumentTrack? {
    return instrumentTracks.filter({$0.instrument.instrumentDescription == description}).first
  }

  /**
  newTrackForInstrumentWithDescription:

  - parameter description: InstrumentDescription
  */
  static func newTrackForInstrumentWithDescription(description: InstrumentDescription) throws -> InstrumentTrack {
    var instrumentComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_MusicDevice,
                                                                   componentSubType: kAudioUnitSubType_Sampler,
                                                                   componentManufacturer: kAudioUnitManufacturer_Apple,
                                                                   componentFlags: 0,
                                                                   componentFlagsMask: 0)
    var instrumentNode = AUNode()
    try checkStatus(AUGraphAddNode(AudioManager.graph, &instrumentComponentDescription, &instrumentNode),
                    "Failed to add instrument node to audio graph")
    var instrumentUnit = MusicDeviceComponent()
    try checkStatus(AUGraphNodeInfo(AudioManager.graph, instrumentNode, nil, &instrumentUnit),
                    "Failed to retrieve instrument audio unit from audio graph node")
    let bus = AudioUnitElement(tracks.count)
    try checkStatus(AUGraphConnectNodeInput(AudioManager.graph, instrumentNode, 0, mixerNode, bus),
                    "Failed to connect instrument output to mixer input")
    let instrument = try Instrument(description: description, unit: instrumentUnit)
    try checkStatus(AUGraphUpdate(AudioManager.graph, nil), "Failed to update audio graph")
    let track = InstrumentTrack(instrument: instrument, bus: bus)
    tracks.append(track)
    return track
  }

  // MARK: - Internally used helpers

  private enum Parameter: String {
    case Volume, Pan, Enable
    var id: AudioUnitParameterID {
      switch self {
        case .Volume: return kMultiChannelMixerParam_Volume
        case .Pan:    return kMultiChannelMixerParam_Pan
        case .Enable: return kMultiChannelMixerParam_Enable
      }
    }
  }

  private enum Scope: String {
    case Input, Output
    var value: AudioUnitScope {
      switch self {
        case .Input: return kAudioUnitScope_Input
        case .Output:return kAudioUnitScope_Output
      }
    }
  }

  /**
  setParameter:forBus:toValue:

  - parameter parameter: Parameter
  - parameter bus: AudioUnitElement
  - parameter value: AudioUnitParameterValue
  */
  private static func setParameter(parameter: Parameter,
                             onBus bus: AudioUnitElement,
                           toValue value: AudioUnitParameterValue,
                             scope: Scope) throws
  {
    let status = AudioUnitSetParameter(mixerUnit, parameter.id, scope.value, bus, value, 0)
    try checkStatus(status, "adjusting \(parameter.rawValue.lowercaseString) on bus \(bus)")
  }

  /**
  valueForParameter:onBus:

  - parameter parameter: Parameter
  - parameter bus: AudioUnitElement
  */
  private static func valueForParameter(parameter: Parameter,
                                  onBus bus: AudioUnitElement,
                                  scope: Scope) throws -> AudioUnitParameterValue
  {
    var value = AudioUnitParameterValue()
    let status = AudioUnitGetParameter(mixerUnit, parameter.id, scope.value, bus, &value)
    try checkStatus(status, "retrieving \(parameter.rawValue.lowercaseString) on bus \(bus)")
    return value
  }

  // MARK: - Output volume/pan/enable

  /**
  setMasterVolume:

  - parameter volume: AudioUnitParameterValue
  */
  static func setMasterVolume(volume: AudioUnitParameterValue) throws {
    try setParameter(.Volume, onBus: 0, toValue: volume, scope: .Output)
  }

  /** masterVolume */
  static func masterVolume() throws -> AudioUnitParameterValue {
    return try valueForParameter(.Volume, onBus: 0, scope: .Output)
  }

  /**
  setMasterPan:

  - parameter pan: AudioUnitParameterValue
  */
  static func setMasterPan(pan: AudioUnitParameterValue) throws {
    try setParameter(.Pan, onBus: 0, toValue: pan, scope: .Output)
  }

  /** masterPan */
  static func masterPan() throws -> AudioUnitParameterValue {
    return try valueForParameter(.Pan, onBus: 0, scope: .Output)
  }

  /** masterEnable */
  static func masterEnable() throws {
    try setParameter(.Enable, onBus: 0, toValue: AudioUnitParameterValue(1), scope: .Output)
  }

  /** masterDisable */
  static func masterDisable() throws {
    try setParameter(.Enable, onBus: 0, toValue: AudioUnitParameterValue(0), scope: .Output)
  }

  /** isMasterEnabled */
  static func isMasterEnabled() throws -> Bool {
    return try valueForParameter(.Enable, onBus: 0, scope: .Output) == 1
  }

  // MARK: - Input volume/pan/enable

  /**
  setVolume:onBus:

  - parameter volume: AudioUnitParameterValue
  - parameter bus: AudioUnitElement
  */
  static func setVolume(volume: AudioUnitParameterValue, onBus bus: AudioUnitElement) throws {
    try setParameter(.Volume, onBus: bus, toValue: volume, scope: .Input)
  }

  /**
  setPan:onBus:

  - parameter pan: AudioUnitParameterValue
  - parameter bus: AudioUnitElement
  */
  static func setPan(pan: AudioUnitParameterValue, onBus bus: AudioUnitElement) throws {
    try setParameter(.Pan, onBus: bus, toValue: pan, scope: .Input)
  }

  /**
  volumeOnBus:

  - parameter bus: AudioUnitElement
  */
  static func volumeOnBus(bus: AudioUnitElement) throws -> AudioUnitParameterValue {
    return try valueForParameter(.Volume, onBus: bus, scope: .Input)
  }

  /**
  panOnBus:

  - parameter bus: AudioUnitElement
  */
  static func panOnBus(bus: AudioUnitElement) throws -> AudioUnitParameterValue {
    return try valueForParameter(.Pan, onBus: bus, scope: .Input)
  }

  /**
  enableBus:

  - parameter bus: AudioUnitElement
  */
  static func enableBus(bus: AudioUnitElement) throws {
    try setParameter(.Enable, onBus: bus, toValue: AudioUnitParameterValue(1), scope: .Input)
  }

  /**
  disableBus:

  - parameter bus: AudioUnitElement
  */
  static func disableBus(bus: AudioUnitElement) throws {
    try setParameter(.Enable, onBus: bus, toValue: AudioUnitParameterValue(0), scope: .Input)
  }

  /**
  isBusEnabled:

  - parameter bus: AudioUnitElement
  */
  static func isBusEnabled(bus: AudioUnitElement) throws -> Bool {
    return try valueForParameter(.Enable, onBus: bus, scope: .Input) == 1
  }

}