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

final class Mixer {

  private let mixerUnit: AudioUnit

  /**
  init:

  - parameter mixer: AudioUnit
  */
  init(mixerUnit mixer: AudioUnit) { mixerUnit = mixer }

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
  private func setParameter(parameter: Parameter,
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
  private func valueForParameter(parameter: Parameter,
                           onBus bus: AudioUnitElement,
                           scope: Scope) throws -> AudioUnitParameterValue
  {
    var value = AudioUnitParameterValue()
    let status = AudioUnitGetParameter(mixerUnit, parameter.id, scope.value, bus, &value)
    try checkStatus(status, "retrieving \(parameter.rawValue.lowercaseString) on bus \(bus)")
    return value
  }

  /**
  setMasterVolume:

  - parameter volume: AudioUnitParameterValue
  */
  func setMasterVolume(volume: AudioUnitParameterValue) throws {
    try setParameter(.Volume, onBus: 0, toValue: volume, scope: .Output)
  }

  /** masterVolume */
  func masterVolume() throws -> AudioUnitParameterValue {
    return try valueForParameter(.Volume, onBus: 0, scope: .Output)
  }

  /**
  setMasterPan:

  - parameter pan: AudioUnitParameterValue
  */
  func setMasterPan(pan: AudioUnitParameterValue) throws {
    try setParameter(.Pan, onBus: 0, toValue: pan, scope: .Output)
  }

  /** masterPan */
  func masterPan() throws -> AudioUnitParameterValue {
    return try valueForParameter(.Pan, onBus: 0, scope: .Output)
  }

  /**
  setVolume:onBus:

  - parameter volume: AudioUnitParameterValue
  - parameter bus: AudioUnitElement
  */
  func setVolume(volume: AudioUnitParameterValue, onBus bus: AudioUnitElement) throws {
    try setParameter(.Volume, onBus: bus, toValue: volume, scope: .Input)
  }

  /**
  setPan:onBus:

  - parameter pan: AudioUnitParameterValue
  - parameter bus: AudioUnitElement
  */
  func setPan(pan: AudioUnitParameterValue, onBus bus: AudioUnitElement) throws {
    try setParameter(.Pan, onBus: bus, toValue: pan, scope: .Input)
  }

  /**
  volumeOnBus:

  - parameter bus: AudioUnitElement
  */
  func volumeOnBus(bus: AudioUnitElement) throws -> AudioUnitParameterValue {
    return try valueForParameter(.Volume, onBus: bus, scope: .Input)
  }

  /**
  panOnBus:

  - parameter bus: AudioUnitElement
  */
  func panOnBus(bus: AudioUnitElement) throws -> AudioUnitParameterValue {
    return try valueForParameter(.Pan, onBus: bus, scope: .Input)
  }

  /**
  enableBus:

  - parameter bus: AudioUnitElement
  */
  func enableBus(bus: AudioUnitElement) throws {
    try setParameter(.Enable, onBus: bus, toValue: AudioUnitParameterValue(1), scope: .Input)
  }

  /**
  disableBus:

  - parameter bus: AudioUnitElement
  */
  func disableBus(bus: AudioUnitElement) throws {
    try setParameter(.Enable, onBus: bus, toValue: AudioUnitParameterValue(0), scope: .Input)
  }

  /**
  isBusEnabled:

  - parameter bus: AudioUnitElement
  */
  func isBusEnabled(bus: AudioUnitElement) throws -> Bool {
    return try valueForParameter(.Enable, onBus: bus, scope: .Input) == 1
  }

}