//
//  Instrument.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import AudioToolbox
import CoreAudio

final class Instrument: Equatable {

  typealias Program = UInt8
  typealias Channel = MusicDeviceGroupID

  let soundSet: SoundSet
  let node: AUNode

  /**
  setProgram:onChannel:

  - parameter program: Program
  - parameter onChannel: Channel
  */
  func setProgram(var program: Program, onChannel channel: Channel) throws {
    program = ClosedInterval<Program>(0, 127).clampValue(program)
    try checkStatus(MusicDeviceMIDIEvent(audioUnit, 0b11000000 | channel, UInt32(program), 0, 0),
                    "Failed to set program \(program) on channel \(channel)")
  }

  private let audioUnit: MusicDeviceComponent

  /**
  initWithAudioUnit:

  - parameter audioUnit: MusicDeviceComponent
  */
  init(graph: AUGraph, soundSet set: SoundSet) throws {
    soundSet = set

    var instrumentComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_MusicDevice,
                                                                   componentSubType: kAudioUnitSubType_Sampler,
                                                                   componentManufacturer: kAudioUnitManufacturer_Apple,
                                                                   componentFlags: 0,
                                                                   componentFlagsMask: 0)
    node = AUNode()
    audioUnit = MusicDeviceComponent()
    try checkStatus(AUGraphAddNode(graph, &instrumentComponentDescription, &node),
      "Failed to add instrument node to audio graph")

    try checkStatus(AUGraphNodeInfo(graph, node, nil, &audioUnit),
      "Failed to retrieve instrument audio unit from audio graph node")

    var instrumentData = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(soundSet.url),
                                                 instrumentType: soundSet.instrumentType.rawValue,
                                                 bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                 bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                                                 presetID: 0)

    try checkStatus(AudioUnitSetProperty(audioUnit,
                                         AudioUnitPropertyID(kAUSamplerProperty_LoadInstrument),
                                         AudioUnitScope(kAudioUnitScope_Global),
                                         AudioUnitElement(0),
                                         &instrumentData,
                                         UInt32(sizeof(AUSamplerInstrumentData))),
                    "Failed to load instrument into audio unit")

  }

}

/**
Equatable compliance

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.audioUnit == rhs.audioUnit }
