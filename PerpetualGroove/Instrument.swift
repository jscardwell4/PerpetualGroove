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

  enum Error: String, ErrorType { case AttachNodeFailed = "Failed to attach sampler node to audio engine" }

  typealias Bank    = Byte
  typealias Program = Byte
  typealias Channel = Byte

  typealias Preset = SF2File.Preset

  var soundSet: SoundSetType
  var channel: Channel = 0
  var bank: Bank = 0
  var program: Program = 0
  var preset: Preset { return soundSet[program, bank] }
  weak var track: InstrumentTrack?
  private let node = AVAudioUnitSampler()

  var bus: AVAudioNodeBus {
    return node.destinationForMixer(AudioManager.mixer, bus: 0)?.connectionPoint.bus ?? -1
  }

  /**
  loadSoundSet:preset:

  - parameter soundSet: SoundSetType
  - parameter preset: Preset
  */
  func loadSoundSet(soundSet: SoundSetType, preset: Preset) throws {
    try loadSoundSet(soundSet, program: preset.program, bank: preset.bank)
  }

  /**
  loadPreset:

  - parameter preset: Preset
  */
  func loadPreset(preset: Preset) throws {
    try loadSoundSet(soundSet, program: preset.program, bank: preset.bank)
  }

  var volume: Float { get { return node.volume } set { node.volume = (0 ... 1).clampValue(newValue)  } }
  var pan:    Float { get { return node.pan    } set { node.pan    = (-1 ... 1).clampValue(newValue) } }

  private      var client   = MIDIClientRef()
  private(set) var outPort  = MIDIPortRef()
  private(set) var endPoint = MIDIEndpointRef()

  /**
  playNote:

  - parameter noteGenerator: MIDINoteGenerator
  */
  func playNote(noteGenerator: MIDINoteGenerator) {
    do {
      try noteGenerator.sendNoteOn(outPort, endPoint)
      delayedDispatchToMain(noteGenerator.duration.seconds) {
        [weak self] in
        guard let weakself = self else { return }
        do { try noteGenerator.sendNoteOff(weakself.outPort, weakself.endPoint) }
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
  private func read(packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutablePointer<Void>) {
    let packets = packetList.memory
    var packetPointer = UnsafeMutablePointer<MIDIPacket>.alloc(1)
    packetPointer.initialize(packets.packet)

    for _ in 0 ..< packets.numPackets {
      let packet = packetPointer.memory
      node.sendMIDIEvent(packet.data.0, data1: packet.data.1, data2: packet.data.2)
      packetPointer = MIDIPacketNext(packetPointer)
    }
  }

  /**
  All program changes run through this method

  - parameter soundSet: SoundSetType
  */
  func loadSoundSet(soundSet: SoundSetType, var program: Program = 0, var bank: Bank = 0) throws {
    guard !(self.soundSet.isEqualTo(soundSet) && preset == soundSet[program, bank]) else { return }
    let oldPresetName = preset.name
    program = (0 ... 127).clampValue(program)
    bank    = (0 ... 127).clampValue(bank)
    try node.loadSoundBankInstrumentAtURL(soundSet.url,
                                  program: program,
                                  bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                  bankLSB: bank)
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
  func settingsEqualTo(instrument: Instrument) -> Bool {
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

    let name = "Instrument \(ObjectIdentifier(self).uintValue)"
    try MIDIClientCreateWithBlock(name, &client, nil) ➤ "Failed to create midi client"
    try MIDIOutputPortCreate(client, "Output", &outPort) ➤ "Failed to create out port"
    try MIDIDestinationCreateWithBlock(client, name, &endPoint, read) ➤ "Failed to create end point for instrument"
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
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

extension Instrument: JSONValueConvertible {
  var jsonValue: JSONValue { return ["soundset":soundSet, "preset": preset, "channel": channel] }
}

extension Instrument: JSONValueInitializable {
  convenience init?(_ jsonValue: JSONValue?) {
    guard let dict = ObjectJSONValue(jsonValue),
      soundSet: SoundSetType = EmaxSoundSet(dict["soundset"]) ?? SoundSet(dict["soundset"]),
      preset = Preset(dict["preset"]),
      channel = Channel(dict["channel"])
    else { return nil }
    do {
      try self.init(track: nil, soundSet: soundSet, program: preset.program, bank: preset.bank, channel: channel)
    } catch {
      return nil
    }
  }
}

// MARK: - Notifications
extension Instrument {
  enum Notification: String, NotificationType, NotificationNameType {
    enum Key: String, KeyType { case OldValue, NewValue }
    case PresetDidChange
  }
}

extension NSNotification {
  var oldPresetName: String? { return userInfo?[Instrument.Notification.Key.OldValue.key] as? String }
  var newPresetName: String? { return userInfo?[Instrument.Notification.Key.NewValue.key] as? String }
}

/**
Equatable compliance

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.node === rhs.node }
