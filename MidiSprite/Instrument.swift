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

final class Instrument: Equatable, CustomStringConvertible {

  var event: InstrumentEvent {
    let fileType: InstrumentEvent.FileType = .SF2
    return InstrumentEvent(fileType, soundSet.url)
  }


  struct Preset: ByteArrayConvertible {
    let fileURL: NSURL
    let program: Program
    let channel: Channel
    var bytes: [Byte] { return program.bytes + channel.bytes + fileURL.absoluteString.bytes }
    init(_ bytes: [Byte]) {
      guard bytes.count > 2 else { fileURL = NSURL(string: "")!; program = 0; channel = 0; return }
      program = bytes[0]
      channel = bytes[1]
      fileURL = NSURL(string: String(bytes[2..<])) ?? NSURL(string: "")!
    }
    init(fileURL f: NSURL, program p: Program, channel c: Channel) { fileURL = f; program = p; channel = c }
  }

  typealias Program = Byte
  typealias Channel = Byte

  var soundSet: SoundSet
  var channel: Channel
  var program: Program
  let node: AUNode

  var preset: Preset { return Preset(fileURL: soundSet.url, program: 0, channel: 0) }

  /**
  setProgram:onChannel:

  - parameter program: Program
  - parameter onChannel: Channel
  */
  func setProgram(program: Program) throws { try loadSoundSet(soundSet, program: program) }

  /**
  playNoteWithAttributes:

  - parameter attributes: NoteAttributes
  */
  func playNoteWithAttributes(attributes: NoteAttributes) throws {
    let note = UInt32(attributes.note.MIDIValue)
    let velocity = UInt32(attributes.velocity.MIDIValue)
    let duration = attributes.duration.seconds
    let channel = UInt32(self.channel)
    try MusicDeviceMIDIEvent(audioUnit, 0x90 | channel, note, velocity, 0) ➤ "\(location()) Failed to send note on midi event"
    // TODO: try sending note off with an offset instead of using gcd
    delayedDispatch(duration, dispatch_get_main_queue()) {
      [audioUnit = audioUnit] in
      let status = MusicDeviceMIDIEvent(audioUnit, 0x80 | channel, note, 0, 0)
      if status != noErr { logError(error(status, "\(location()) Failed to send note off midi event")) }
    }
  }


  var description: String { return "Instrument { \n\tsoundSet: \(soundSet)\n\tprogram: \(program)\n\tchannel: \(channel)\n}" }

  private let audioUnit: MusicDeviceComponent
  private var client = MIDIClientRef()
  private(set) var endPoint = MIDIEndpointRef()

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
      MusicDeviceMIDIEvent(audioUnit, UInt32(packet.data.0), UInt32(packet.data.1), UInt32(packet.data.2), 0)
      packetPointer = MIDIPacketNext(packetPointer)
    }
  }

  /**
  loadSoundSet:

  - parameter soundSet: SoundSet
  */
  func loadSoundSet(soundSet: SoundSet, var program: Program = 0) throws {
    program = (0 ... 127).clampValue(program)
    var instrumentData = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(soundSet.url),
                                                 instrumentType: UInt8(kInstrumentType_DLSPreset),
                                                 bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                 bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                                                 presetID: program)

    try AudioUnitSetProperty(audioUnit,
                             AudioUnitPropertyID(kAUSamplerProperty_LoadInstrument),
                             AudioUnitScope(kAudioUnitScope_Global),
                             AudioUnitElement(0),
                             &instrumentData,
                             UInt32(sizeof(AUSamplerInstrumentData)))
      ➤ "\(location()) Failed to load instrument into audio unit"
    self.soundSet = soundSet
    self.program = program
  }

  /**
  init:

  - parameter set: SoundSet
  - parameter program: Program
  */
  init(soundSet set: SoundSet, program p: Program = 0, channel c: Channel = 0) throws {
    soundSet = set
    channel = c
    program = p
    node = AUNode()
    audioUnit = MusicDeviceComponent()
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

    try loadSoundSet(soundSet, program: program)

    let name = "Instrument \(ObjectIdentifier(self).uintValue)"
    try MIDIClientCreateWithBlock(name, &client, nil) ➤ "Failed to create midi client"
    try MIDIDestinationCreateWithBlock(client, name, &endPoint, read) ➤ "Failed to create end point for instrument"
  }

  /**
  initWithPreset:

  - parameter preset: Preset
  */
  convenience init(preset: Preset) throws {
    let soundSet = try SoundSet(url: preset.fileURL)
    try self.init(soundSet: soundSet, program: preset.program, channel: preset.channel)
  }

}

/**
Equatable compliance

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.audioUnit == rhs.audioUnit }
