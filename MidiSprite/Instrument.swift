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
  init(audioUnit: MusicDeviceComponent, soundSet: SoundSet) {
    self.audioUnit = audioUnit
    self.soundSet = soundSet
    var instrumentData = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(soundSet.url),
                                                 instrumentType: soundSet.instrumentType.rawValue,
                                                 bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                 bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                                                 presetID: 0)

    do {
      try checkStatus(AudioUnitSetProperty(audioUnit,
                                           AudioUnitPropertyID(kAUSamplerProperty_LoadInstrument),
                                           AudioUnitScope(kAudioUnitScope_Global),
                                           AudioUnitElement(0),
                                           &instrumentData,
                                           UInt32(sizeof(AUSamplerInstrumentData))),
                      "Failed to load instrument into audio unit")
    } catch { logError(error) }
  }

}

/**
Equatable compliance

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.audioUnit == rhs.audioUnit }
