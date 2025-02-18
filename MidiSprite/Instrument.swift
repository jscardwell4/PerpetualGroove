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
  private var channelPrograms: [Program] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

  /**
  setProgram:onChannel:

  - parameter program: Program
  - parameter onChannel: Channel
  */
  func setProgram(var program: Program, var onChannel channel: Channel) throws {
    program = ClosedInterval<Program>(0, 127).clampValue(program)
    channel = ClosedInterval<Channel>(0, 15).clampValue(channel)
    try MusicDeviceMIDIEvent(audioUnit, 0b11000000 | channel, UInt32(program), 0, 0)
      ➤ "\(location()) Failed to set program \(program) on channel \(channel)"
    channelPrograms[Int(channel)] = program
  }

  /**
  programOnChannel:

  - parameter channel: Channel

  - returns: Program
  */
  func programOnChannel(channel: Channel) -> Program {
    return channelPrograms[Int(ClosedInterval<Channel>(0, 15).clampValue(channel))]
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

    try AUGraphAddNode(graph, &instrumentComponentDescription, &node)
      ➤ "\(location()) Failed to add instrument node to audio graph"

    try AUGraphNodeInfo(graph, node, nil, &audioUnit)
      ➤ "\(location()) Failed to retrieve instrument audio unit from audio graph node"

    var instrumentData = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(soundSet.url),
                                                 instrumentType: soundSet.instrumentType.rawValue,
                                                 bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                 bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                                                 presetID: 0)

    try AudioUnitSetProperty(audioUnit,
                             AudioUnitPropertyID(kAUSamplerProperty_LoadInstrument),
                             AudioUnitScope(kAudioUnitScope_Global),
                             AudioUnitElement(0),
                             &instrumentData,
                             UInt32(sizeof(AUSamplerInstrumentData)))
      ➤ "\(location()) Failed to load instrument into audio unit"

  }

}

/**
Equatable compliance

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.audioUnit == rhs.audioUnit }
