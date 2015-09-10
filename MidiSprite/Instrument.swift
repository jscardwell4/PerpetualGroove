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
import AVFoundation

final class Instrument: Equatable, CustomStringConvertible {

  var event: InstrumentEvent { return InstrumentEvent(.SF2, soundSet.url) }

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
  var channel: Channel = 0
  var program: Program = 0
  let node = AVAudioUnitSampler()

  var bus: AVAudioNodeBus {
    return node.destinationForMixer(AudioManager.engine.mainMixerNode, bus: 0)?.connectionPoint.bus ?? -1
  }

  var preset: Preset { return Preset(fileURL: soundSet.url, program: 0, channel: 0) }

  /**
  setProgram:onChannel:

  - parameter program: Program
  - parameter onChannel: Channel
  */
  func setProgram(program: Program) throws { try loadSoundSet(soundSet, program: program) }



  var description: String { return "Instrument { \n\tsoundSet: \(soundSet)\n\tprogram: \(program)\n\tchannel: \(channel)\n}" }

  private var client = MIDIClientRef()
  private(set) var endPoint = MIDIEndpointRef()

  /**
  playNoteWithAttributes:

  - parameter attributes: NoteAttributes
  */
  func playNoteWithAttributes(attributes: NoteAttributes) {
    node.startNote(attributes.note.MIDIValue, withVelocity: attributes.velocity.MIDIValue, onChannel: 0)
    delayedDispatch(attributes.duration.seconds, dispatch_get_main_queue()) {
      self.node.stopNote(attributes.note.MIDIValue, onChannel: 0)
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
  loadSoundSet:

  - parameter soundSet: SoundSet
  */
  func loadSoundSet(soundSet: SoundSet, var program: Program = 0) throws {
    program = (0 ... 127).clampValue(program)
    try node.loadSoundBankInstrumentAtURL(soundSet.url,
                                  program: program,
                                  bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                  bankLSB: UInt8(kAUSampler_DefaultBankLSB))
    self.soundSet = soundSet
    self.program = program
  }

  /**
  init:

  - parameter set: SoundSet
  - parameter program: Program
  */
  init(soundSet: SoundSet, program: Program = 0, channel: Channel = 0) throws {
    self.soundSet = soundSet
    self.program = program
    self.channel = channel

    AudioManager.engine.attachNode(node)
    AudioManager.engine.connect(node, to: AudioManager.engine.mainMixerNode, format: node.outputFormatForBus(0))
    try loadSoundSet(soundSet, program: program)

    let name = "Instrument \(ObjectIdentifier(self).uintValue)"
    try MIDIClientCreateWithBlock(name, &client, nil) ➤ "Failed to create midi client"
    try MIDIDestinationCreateWithBlock(client, name, &endPoint, read)
      ➤ "Failed to create end point for instrument"
  }

  /**
  initWithPreset:

  - parameter preset: Preset
  */
  convenience init(preset: Preset) throws {
    try self.init(soundSet: try SoundSet(url: preset.fileURL), program: preset.program, channel: preset.channel)
  }

  /**
  initWithInstrument:

  - parameter instrument: Instrument
  */
  convenience init(instrument: Instrument) {
    try! self.init(soundSet: instrument.soundSet, program: instrument.program, channel: instrument.channel)
  }

}

/**
Equatable compliance

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool {
  return lhs.soundSet == rhs.soundSet && lhs.program == rhs.program && lhs.channel == rhs.channel
}
