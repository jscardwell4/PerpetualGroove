//
//  Metronome.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreMIDI
import AudioToolbox
import MoonKit

final class Metronome {

  static private var audioUnit = MusicDeviceComponent()
  static private var node = AUNode()
  static private let time = BarBeatTime(clockSource: Sequencer.clockSource)

  static var channel: Byte = 0
  static var on = false {
    didSet {
      guard oldValue != on else { return }
      if on { time.registerCallback(click, predicate: isAudibleTick, forKey: callbackKey) }
      else { time.removeCallbackForKey(callbackKey) }
    }
  }
  
  static private var initialized = false

  /** initialize */
  static func initialize() throws {
    guard !initialized else { return }
    let graph = AudioManager.graph
    var instrumentComponentDescription = AudioComponentDescription(componentType: kAudioUnitType_MusicDevice,
                                                               componentSubType: kAudioUnitSubType_Sampler,
                                                               componentManufacturer: kAudioUnitManufacturer_Apple,
                                                               componentFlags: 0,
                                                               componentFlagsMask: 0)
    try AUGraphAddNode(graph, &instrumentComponentDescription, &node)
      ➤ "\(location()) Failed to add instrument node to audio graph"

    try AUGraphNodeInfo(graph, node, nil, &audioUnit)
      ➤ "\(location()) Failed to retrieve instrument audio unit from audio graph node"

    guard let url = NSBundle.mainBundle().URLForResource("Woodblock", withExtension: "wav") else {
      fatalError("Failed to get url for 'Woodblock.wav'")
    }
    var instrumentData = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(url),
                                                 instrumentType: UInt8(kInstrumentType_Audiofile),
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
    try Mixer.connectMetronomeNode(node)
    initialized = true
  }

  static private let callbackKey = "click"

  /**
  click:

  - parameter time: CABarBeatTime
  */
  static private func click(time: CABarBeatTime) {
    let note: Byte = time.beat == 1 ? 0x3C : 0x37
    var noteParams = MusicDeviceNoteParams()
    noteParams.argCount = 2
    noteParams.mPitch = Float32(note)
    noteParams.mVelocity = 64
    MusicDeviceStartNote(audioUnit, 0, UInt32(channel), nil, 0, &noteParams)
  }


  /**
  isAudibleTick:

  - parameter time: CABarBeatTime

  - returns: Bool
  */
  static private func isAudibleTick(time: CABarBeatTime) -> Bool { return time.subbeat  == 1 }

}