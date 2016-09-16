//
//  Instrument.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import AudioToolbox
import CoreAudio
import AVFoundation

final class Instrument: Equatable {

  enum Error: String, Swift.Error { case AttachNodeFailed = "Failed to attach sampler node to audio engine" }

  typealias Bank    = Byte
  typealias Program = Byte
  typealias Channel = Byte

  typealias Preset = SF2File.Preset

  var soundSet: SoundSetType {
    didSet {
      guard !soundSet.isEqualTo(oldValue) else { return }
      Notification.SoundSetDidChange.post(object: self)
    }
  }
  var channel: Channel = 0
  var bank: Bank = 0
  var program: Program = 0
  var preset: Preset { return soundSet[program, bank] }
  weak var track: InstrumentTrack?
  fileprivate let node = AVAudioUnitSampler()

  fileprivate var soundLoaded = false

  var bus: AVAudioNodeBus {
    return node.destination(forMixer: AudioManager.mixer, bus: 0)?.connectionPoint.bus ?? -1
  }

  /**
  loadSoundSet:preset:

  - parameter soundSet: SoundSetType
  - parameter preset: Preset
  */
  func loadSoundSet(_ soundSet: SoundSetType, preset: Preset) throws {
    try loadSoundSet(soundSet, program: preset.program, bank: preset.bank)
  }

  /**
  loadPreset:

  - parameter preset: Preset
  */
  func loadPreset(_ preset: Preset) throws {
    try loadSoundSet(soundSet, program: preset.program, bank: preset.bank)
  }

  var volume: Float { get { return node.volume } set { node.volume = (0 ... 1).clampValue(newValue)  } }
  var pan:    Float { get { return node.pan    } set { node.pan    = (-1 ... 1).clampValue(newValue) } }

  /// The default value is 0.0 db. The range of valid values is -90.0 db to 12.0 db.
  var masterGain: Float { get { return node.masterGain } set { node.masterGain = newValue } }

  /// Adjusts the stereo panning for all the notes played.
  var stereoPan: Float { get { return node.stereoPan } set { node.stereoPan = newValue } }

  fileprivate      var client   = MIDIClientRef()
  fileprivate(set) var outPort  = MIDIPortRef()
  fileprivate(set) var endPoint = MIDIEndpointRef()

  /**
  playNote:

  - parameter generator: MIDIGenerator
  */
  func playNote(_ generator: MIDIGenerator) {
    do {
      try generator.sendNoteOn(outPort, endPoint)
      DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: secondsToNanoseconds(generator.duration.seconds))) {
        [weak self] in
        guard let weakself = self else { return }
        do { try generator.sendNoteOff(weakself.outPort, weakself.endPoint) }
        catch { MoonKit.logError(error) }
      }
    } catch {
      logError(error)
    }
  }

  /**
  read:context:

  - parameter packetList: UnsafePointer<MIDIPacketList>
  - parameter context: UnsafeMutablePointer<Void>
  */
  fileprivate func read(_ packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutableRawPointer) {
    for packet in packetList.pointee {
      node.sendMIDIEvent(packet.data.0, data1: packet.data.1, data2: packet.data.2)
    }
  }

  /**
  All program changes run through this method

  - parameter soundSet: SoundSetType
  */
  func loadSoundSet(_ soundSet: SoundSetType, program: Program = 0, bank: Bank = 0) throws {
    guard !soundLoaded || !(self.soundSet.isEqualTo(soundSet) && preset == soundSet[program, bank]) else { return }
    let oldPresetName = preset.name
    let program = (0 ... 127).clampValue(program)
    let bank    = (0 ... 127).clampValue(bank)
    do {
      try node.loadSoundBankInstrument(at: soundSet.url as URL,
                                    program: program,
                                    bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                    bankLSB: bank)
    } catch {
      throw error
    }
    soundLoaded = true
    self.soundSet = soundSet
    self.program  = program
    self.bank     = bank
    let newPresetName = preset.name
    Notification.PresetDidChange.post(object: self, userInfo: [.OldValue: oldPresetName, .NewValue: newPresetName])
  }

  /**
  Whether the specified `Intrument` has the same settings as this `Instrument`

  - parameter instrument: Instrument

  - returns: Bool
  */
  func settingsEqualTo(_ instrument: Instrument) -> Bool {
    return soundSet.url == instrument.soundSet.url
        && program      == instrument.program
        && bank         == instrument.bank
        && channel      == instrument.channel
  }

  /**
  init:

  - parameter set: SoundSetType
  - parameter program: Program
  */
  init(track: InstrumentTrack?,
       soundSet: SoundSetType,
       program: Program = 0,
       bank: Bank = 0,
       channel: Channel = 0) throws
  {
    self.track = track
    self.soundSet = soundSet
    self.bank     = bank
    self.program  = program
    self.channel  = channel

    AudioManager.attachNode(node, forInstrument: self)
    guard node.engine != nil else { throw Error.AttachNodeFailed }

    try loadSoundSet(soundSet, program: program, bank: bank)

    let name = "Instrument \(UInt(bitPattern: ObjectIdentifier(self)))"
    try MIDIClientCreateWithBlock(name as CFString, &client, nil) ➤ "Failed to create midi client"
    try MIDIOutputPortCreate(client, "Output" as CFString, &outPort) ➤ "Failed to create out port"
    try MIDIDestinationCreateWithBlock(client, name as CFString, &endPoint, read as! MIDIReadBlock) ➤ "Failed to create end point for instrument"
  }

  /**
  initWithInstrument:

  - parameter instrument: Instrument
  */
  convenience init(track: InstrumentTrack?, instrument: Instrument) {
    try! self.init(track: track,
                   soundSet: instrument.soundSet,
                   program: instrument.program,
                   bank: instrument.bank,
                   channel: instrument.channel)
  }

}

extension Instrument: CustomStringConvertible {

  var description: String {
    return "{soundSet: \(soundSet), program: \(program), bank: \(bank), channel: \(channel)}"
  }

}

extension Instrument: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}

extension Instrument: JSONValueConvertible {
  var jsonValue: JSONValue { return ["soundset":soundSet, "preset": preset, "channel": channel] }
}

extension Instrument: JSONValueInitializable {
  convenience init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
      let soundSet: SoundSetType = EmaxSoundSet(dict["soundset"]) ?? SoundSet(dict["soundset"]),
      let preset = Preset(dict["preset"]),
      let channel = Channel(dict["channel"])
    else { return nil }
    do {
      try self.init(track: nil, soundSet: soundSet, program: preset.program, bank: preset.bank, channel: channel)
    } catch {
      return nil
    }
  }
}

// MARK: - Notifications
extension Instrument: NotificationDispatching {
  enum NotificationName: String, LosslessStringConvertible {
    case presetDidChange, soundSetDidChange
  }
}

extension Notification {
  var oldPresetName: String? { return userInfo?["oldValue"] as? String }
  var newPresetName: String? { return userInfo?["newValue"] as? String }
}

/**
Equatable compliance

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.node === rhs.node }
