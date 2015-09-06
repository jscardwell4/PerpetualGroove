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
import CoreAudio

final class Mixer {

  // MARK: - An enumeration to wrap up notifications

  enum Notification: NotificationType {
    case BusAdded (Bus)
    case BusRemoved (Bus)

    enum Name: String, NotificationNameType { case DidAddBus, DidRemoveBus }

    static let BusKey = "bus"

    var name: Name {
      switch self {
        case .BusAdded: return .DidAddBus
        case .BusRemoved: return .DidRemoveBus
      }
    }

    var userInfo: [NSObject:AnyObject]? {
      switch self {
        case .BusAdded(let bus):   return[Notification.BusKey: NSNumber(unsignedInt: bus.element)]
        case .BusRemoved(let bus): return [Notification.BusKey: NSNumber(unsignedInt: bus.element)]
      }
    }

    var object: AnyObject? { return Mixer.self }

  }

  // MARK: - Type for Mixer-specific errors

  enum Error: String, ErrorType, CustomStringConvertible {
    case GraphAlreadyExists = "The mixer already has a graph"
    case AudioUnitIsNotAMixer = "The audio unit for the specified node is not a mixer unit"
    case GraphNotInitialized = "The audio graph should already be initialized"
    case NilGraph = "Graph is nil"
    case InstrumentAlreadyConnected = "Instrument is already connected"
    case NilMixerNode = "Mixer node is nil"
    case NilMixerUnit = "Mixer unit is nil"
    case MixerNotInitialized = "Mixer has not been initialized"

    var description: String { return rawValue }
  }


  // MARK: - Static properties

  static private(set) var instruments: OrderedDictionary<AudioUnitElement, Instrument> = [:]

  static private var reassignableBuses: OrderedSet<AudioUnitElement> = [] { didSet { reassignableBuses.sortInPlace() } }

  static private var mixerNode: AUNode?
  static private var mixerUnit: AudioUnit?
  static private var initialized = false

  // MARK: - Initializing the mixer

  /**
  initializeWithNode:

  - parameter node: AUNode
  */
  static func initialize(node node: AUNode) throws {
    guard !initialized else { return }
    var isInitialized = DarwinBoolean(false)
    let graph = AudioManager.graph
    try AUGraphIsInitialized(graph, &isInitialized) ➤ "\(location()) Failed to check whether graph is initialized"
    guard isInitialized else { throw Error.GraphNotInitialized }
    var audioUnit = AudioUnit()
    try AUGraphNodeInfo(graph, node, nil, &audioUnit) ➤ "\(location()) Failed to get audio unit from graph"
    var description = AudioComponentDescription()
    try AudioComponentGetDescription(audioUnit, &description) ➤ "\(location()) Failed to get audio unit description"
    guard description.componentType == kAudioUnitType_Mixer
       && description.componentSubType == kAudioUnitSubType_MultiChannelMixer
       && description.componentManufacturer == kAudioUnitManufacturer_Apple else { throw Error.AudioUnitIsNotAMixer }
    mixerUnit = audioUnit
    mixerNode = node
    initialized = true

    try Metronome.initialize()
  }

  // MARK: - Connecting/Disconnecting instruments

  /**
  nextAvailableBus

  - returns: Bus
  */
  private static func nextAvailableBus() -> AudioUnitElement {
    guard instruments.count > 0 else { return 1 }
    return reassignableBuses.popFirst() ?? instruments.keys.maxElement()! + 1
  }

  /**
  connectInstrument:

  - parameter instrument: Instrument
  */
  static func connectInstrument(instrument: Instrument) throws -> Bus {
    guard initialized else { throw Error.MixerNotInitialized }
    let graph = AudioManager.graph

    guard !instruments.values.contains(instrument) else { throw Error.InstrumentAlreadyConnected }

    guard let mixerNode = mixerNode else { throw Error.NilMixerNode }

    let element = nextAvailableBus()

    try AUGraphConnectNodeInput(graph, instrument.node, 0, mixerNode, element)
      ➤ "\(location()) Failed to connect instrument to mixer"

    try AUGraphUpdate(graph, nil) ➤ "\(location()) Failed to update audio graph"

    instruments[element] = instrument

    let bus = Bus(element, instrument)
    Notification.BusAdded(bus).post()

    return bus
  }

  /**
  connectMetronomeNode:

  - parameter node: AUNode
  */
  static func connectMetronomeNode(node: AUNode) throws {
    guard initialized, let mixerNode = mixerNode else { return }

    let graph = AudioManager.graph
    try AUGraphConnectNodeInput(graph, node, 0, mixerNode, 0)
      ➤ "\(location()) Failed to connect metronome node to mixer"

    try AUGraphUpdate(graph, nil) ➤ "\(location()) Failed to update audio graph"

  }

  /**
  removeInstrumentOnBus:

  - parameter bus: Bus
  */
  static func removeInstrumentOnBus(bus: Bus) { fatalError("removeInstrumentOnBus() not yet implemented") }

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
  - parameter bus: Bus
  - parameter value: ParameterValue
  */
  private static func setParameter(parameter: Parameter,
                             onBus bus: AudioUnitElement,
                           toValue value: Float,
                             scope: Scope) throws
  {
    guard let mixerUnit = mixerUnit else { throw Error.NilMixerUnit }
    try AudioUnitSetParameter(mixerUnit, parameter.id, scope.value, bus, value, 0)
      ➤ "\(location()) adjusting \(parameter.rawValue.lowercaseString) on bus \(bus)"
  }

  /**
  valueForParameter:onBus:

  - parameter parameter: Parameter
  - parameter bus: Bus
  */
  private static func valueForParameter(parameter: Parameter,
                                  onBus bus: AudioUnitElement,
                                  scope: Scope) throws -> Float
  {
    guard let mixerUnit = mixerUnit else { throw Error.NilMixerUnit }
    var value = Float()
    try AudioUnitGetParameter(mixerUnit, parameter.id, scope.value, bus, &value)
      ➤ "\(location()) retrieving \(parameter.rawValue.lowercaseString) on bus \(bus)"
    return value
  }

  // MARK: - Output volume/pan/enable

  /**
  setMasterVolume:

  - parameter volume: ParameterValue
  */
  static func setMasterVolume(volume: Float) throws { try setParameter(.Volume, onBus: 0, toValue: volume, scope: .Output) }

  /** masterVolume */
  static func masterVolume() throws -> Float { return try valueForParameter(.Volume, onBus: 0, scope: .Output) }

  /**
  setMasterPan:

  - parameter pan: ParameterValue
  */
  static func setMasterPan(pan: Float) throws { try setParameter(.Pan, onBus: 0, toValue: pan, scope: .Output) }

  /** masterPan */
  static func masterPan() throws -> Float { return try valueForParameter(.Pan, onBus: 0, scope: .Output) }

  /** masterEnable */
  static func masterEnable() throws { try setParameter(.Enable, onBus: 0, toValue: Float(1), scope: .Output) }

  /** masterDisable */
  static func masterDisable() throws { try setParameter(.Enable, onBus: 0, toValue: Float(0), scope: .Output) }

  /** isMasterEnabled */
  static func isMasterEnabled() throws -> Bool { return try valueForParameter(.Enable, onBus: 0, scope: .Output) == 1 }

  // MARK: - Input volume/pan/enable

  /**
  setVolume:onBus:

  - parameter volume: ParameterValue
  - parameter bus: Bus
  */
  static func setVolume(volume: Float, onBus bus: Bus) throws {
    try setParameter(.Volume, onBus: bus.element, toValue: volume, scope: .Input)
  }

  /**
  setPan:onBus:

  - parameter pan: ParameterValue
  - parameter bus: Bus
  */
  static func setPan(pan: Float, onBus bus: Bus) throws {
    try setParameter(.Pan, onBus: bus.element, toValue: pan, scope: .Input)
  }

  /**
  volumeOnBus:

  - parameter bus: Bus
  */
  static func volumeOnBus(bus: Bus) throws -> Float {
    return try valueForParameter(.Volume, onBus: bus.element, scope: .Input)
  }

  /**
  panOnBus:

  - parameter bus: Bus
  */
  static func panOnBus(bus: Bus) throws -> Float { return try valueForParameter(.Pan, onBus: bus.element, scope: .Input) }

  /**
  enableBus:

  - parameter bus: Bus
  */
  static func enableBus(bus: Bus) throws { try setParameter(.Enable, onBus: bus.element, toValue: Float(1), scope: .Input) }

  /**
  disableBus:

  - parameter bus: Bus
  */
  static func disableBus(bus: Bus) throws { try setParameter(.Enable, onBus: bus.element, toValue: Float(0), scope: .Input) }

  /**
  isBusEnabled:

  - parameter bus: Bus
  */
  static func isBusEnabled(bus: Bus) throws -> Bool {
    return try valueForParameter(.Enable, onBus: bus.element, scope: .Input) == 1
  }

}
