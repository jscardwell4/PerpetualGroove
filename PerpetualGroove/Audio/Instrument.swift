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

final class Instrument {

  var preset: Preset {
    didSet {
      if !preset.soundFont.isEqualTo(oldValue.soundFont) {
        postNotification(name: .soundFontDidChange,
                         object: self,
                         userInfo: ["oldSoundFont": oldValue.soundFontName,
                                    "newSoundFont": preset.soundFontName])
      }
      if preset.presetHeader != oldValue.presetHeader {
        postNotification(name: .programDidChange,
                         object: self,
                         userInfo: ["oldProgramName": oldValue.programName, "newProgramName": preset.programName])
      }
    }
  }

  var soundFont: SoundFont { return preset.soundFont }
  var channel: UInt8       { get { return preset.channel } set { preset.channel = newValue } }
  var bank: UInt8          { return preset.bank }
  var program: UInt8       { return preset.program }

  weak var track: InstrumentTrack?
  
  fileprivate let node = AVAudioUnitSampler()

  var bus: AVAudioNodeBus {
    return node.destination(forMixer: AudioManager.mixer, bus: 0)?.connectionPoint.bus ?? -1
  }

  var volume: Float {
    get { return node.volume }
    set { node.volume = (0 ... 1).clampValue(newValue)  }
  }

  var pan: Float {
    get { return node.pan }
    set { node.pan = (-1 ... 1).clampValue(newValue) }
  }

  /// The default value is 0.0 db. The range of valid values is -90.0 db to 12.0 db.
  var masterGain: Float { get { return node.masterGain } set { node.masterGain = newValue } }

  /// Adjusts the stereo panning for all the notes played.
  var stereoPan: Float { get { return node.stereoPan } set { node.stereoPan = newValue } }

  private      var client   = MIDIClientRef()
  private(set) var outPort  = MIDIPortRef()
  private(set) var endPoint = MIDIEndpointRef()

  func playNote(_ generator: AnyMIDIGenerator) {
    do {
      try generator.sendNoteOn(outPort: outPort, endPoint: endPoint)
      let nanoseconds = secondsToNanoseconds(generator.duration.seconds)
      DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: nanoseconds)) {
        [weak self] in
        guard let weakself = self else { return }
        do { try generator.sendNoteOff(outPort: weakself.outPort, endPoint: weakself.endPoint) }
        catch { MoonKit.logError(error) }
      }
    } catch {
      logError(error)
    }
  }

  fileprivate func read(_ packetList: UnsafePointer<MIDIPacketList>, context: UnsafeMutableRawPointer?) {
    for packet in packetList.pointee {
      node.sendMIDIEvent(packet.data.0, data1: packet.data.1, data2: packet.data.2)
    }
  }

  /// All program changes run through this method
  func loadPreset(_ preset: Preset) throws {
    guard self.preset != preset else { return }
    try node.loadSoundBankInstrument(at: preset.soundFont.url,
                                     program: preset.program,
                                     bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                     bankLSB: preset.bank)
    self.preset = preset
  }

  init(track: InstrumentTrack?, preset: Preset) throws {
    self.track = track
    self.preset = preset

    AudioManager.attach(node: node, for: self)
    guard node.engine != nil else { throw Error.AttachNodeFailed }

    try node.loadSoundBankInstrument(at: preset.soundFont.url,
                                     program: preset.program,
                                     bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                     bankLSB: preset.bank)

    let name = "Instrument \(UInt(bitPattern: ObjectIdentifier(self)))"
    try MIDIClientCreateWithBlock(name as CFString, &client, nil) ➤ "Failed to create midi client"
    try MIDIOutputPortCreate(client, "Output" as CFString, &outPort) ➤ "Failed to create out port"
    try MIDIDestinationCreateWithBlock(client, name as CFString, &endPoint, read) ➤ "Failed to create end point for instrument"
  }

}

extension Instrument {

  struct Preset: Equatable, LosslessJSONValueConvertible {

    let soundFont: SoundFont
    let presetHeader: SF2File.PresetHeader
    var channel: UInt8

    var soundFontName: String { return soundFont.displayName }
    var programName: String { return presetHeader.name }
    var program: UInt8 { return presetHeader.program }
    var bank: UInt8 { return presetHeader.bank }

    init(soundFont: SoundFont, presetHeader: SF2File.PresetHeader, channel: UInt8 = 0) {
      self.soundFont = soundFont
      self.presetHeader = presetHeader
      self.channel = channel
    }

    static func ==(lhs: Preset, rhs: Preset) -> Bool {
      return lhs.soundFont.isEqualTo(rhs.soundFont)
          && lhs.presetHeader == rhs.presetHeader
          && lhs.channel == rhs.channel
    }

    var jsonValue: JSONValue { return ["soundFont": soundFont, "presetHeader": presetHeader, "channel": channel] }

    init?(_ jsonValue: JSONValue?) {
      guard
        let dict = ObjectJSONValue(jsonValue),
        let soundFont: SoundFont = EmaxSoundSet(dict["soundFont"]) ?? SoundSet(dict["soundFont"]),
        let presetHeader = SF2File.PresetHeader(dict["presetHeader"]),
        let channel = UInt8(dict["channel"])
        else
      {
        return nil
      }

      self.soundFont = soundFont
      self.presetHeader = presetHeader
      self.channel = channel
    }

  }

}

extension Instrument: Equatable {

  static func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.node === rhs.node }

}

extension Instrument: CustomStringConvertible {

  var description: String { return "Instrument { track: \(track?.name ?? "nil"); preset: \(preset)}" }

}

extension Instrument {

  enum Error: String, Swift.Error {
    case AttachNodeFailed = "Failed to attach sampler node to audio engine"
    case PresetNotFound   = "Specified preset not found for sound set"
  }

}

// MARK: - Notifications
extension Instrument: NotificationDispatching {

  enum NotificationName: String, LosslessStringConvertible {
    case programDidChange, soundFontDidChange
    var description: String { return rawValue }
    init?(_ description: String) { self.init(rawValue: description) }
  }

}

extension Notification {

  var oldProgramName: String? { return userInfo?["oldProgram"] as? String }
  var newProgramName: String? { return userInfo?["newProgram"] as? String }

  var oldSoundFontName: String? { return userInfo?["oldSoundFont"] as? String }
  var newSoundFontName: String? { return userInfo?["newSoundFont"] as? String }

}
