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

  enum Error: String, ErrorType { case AttachNodeFailed = "Failed to attach sampler node to audio engine" }

  typealias Bank    = Byte
  typealias Program = Byte
  typealias Channel = Byte

  typealias Preset = SF2File.Preset

  var soundSet: SoundSet
  var channel: Channel = 0
  var bank: Bank = 0
  var program: Program = 0
  var preset: Preset { return soundSet[program, bank] }
  private let node = AVAudioUnitSampler()

  var bus: AVAudioNodeBus { return node.destinationForMixer(AudioManager.mixer, bus: 0)?.connectionPoint.bus ?? -1 }

  /**
  loadPreset:

  - parameter preset: Preset
  */
  func loadPreset(preset: Preset) throws { try loadSoundSet(soundSet, program: preset.program, bank: preset.bank) }

  /**
  setProgram:onChannel:

  - parameter program: Program
  - parameter onChannel: Channel
  */
//  func setProgram(program: Program) throws { try loadSoundSet(soundSet, program: program) }

  var volume: Float { get { return node.volume } set { node.volume = (0 ... 1).clampValue(newValue)  } }
  var pan:    Float { get { return node.pan    } set { node.pan    = (-1 ... 1).clampValue(newValue) } }

  var description: String {
    var result = "Instrument {\n\t"
    result +=  "\n\t".join("soundSet: \(soundSet)","program: \(program)", "bank: \(bank)", "channel: \(channel)")
    result += "\n}"
    return result
  }

  private      var client   = MIDIClientRef()
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
  func loadSoundSet(soundSet: SoundSet, var program: Program = 0, var bank: Bank = 0) throws {
    program = (0 ... 127).clampValue(program)
    bank    = (0 ... 127).clampValue(bank)
    try node.loadSoundBankInstrumentAtURL(soundSet.url,
                                  program: program,
                                  bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                  bankLSB: bank)
    self.soundSet = soundSet
    self.program  = program
    self.bank     = bank
  }

  /**
  Whether the specified `Intrument` has the same settings as this `Instrument`

  - parameter instrument: Instrument

  - returns: Bool
  */
  func settingsEqualTo(instrument: Instrument) -> Bool {
    return soundSet == instrument.soundSet
        && program  == instrument.program
        && bank     == instrument.bank
        && channel  == instrument.channel
  }

  /**
  init:

  - parameter set: SoundSet
  - parameter program: Program
  */
  init(soundSet: SoundSet, program: Program = 0, bank: Bank = 0, channel: Channel = 0) throws {
    self.soundSet = soundSet
    self.bank     = bank
    self.program  = program
    self.channel  = channel

    AudioManager.attachNode(node, forInstrument: self)
    guard node.engine != nil else { throw Error.AttachNodeFailed }

    try loadSoundSet(soundSet, program: program, bank: bank)

    let name = "Instrument \(ObjectIdentifier(self).uintValue)"
    try MIDIClientCreateWithBlock(name, &client, nil) ➤ "Failed to create midi client"
    try MIDIDestinationCreateWithBlock(client, name, &endPoint, read) ➤ "Failed to create end point for instrument"
  }

  /**
  initWithInstrument:

  - parameter instrument: Instrument
  */
  convenience init(instrument: Instrument) {
    try! self.init(soundSet: instrument.soundSet, program: instrument.program, bank: instrument.bank, channel: instrument.channel)
  }

}

/**
Equatable compliance

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.node === rhs.node }
