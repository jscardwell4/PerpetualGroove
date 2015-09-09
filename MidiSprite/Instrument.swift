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

  enum Error: String, ErrorType {
    case InvalidFileName = "Failed to locate the specified instrument file"
  }

  var event: InstrumentEvent {
    let fileType: InstrumentEvent.FileType = .SF2
    return InstrumentEvent(fileType, soundSet.url)
  }

  struct ProgramRegister: CollectionType, ByteArrayConvertible, IntegerLiteralConvertible {
    var data: Byte8 = 0
    let count = 8
    let startIndex = 0
    let endIndex = 8
    subscript(idx: Int) -> Program {
      get {
        guard indices.contains(idx) else { fatalError("index out of bounds") }
        return Program((data >> Byte8(idx)) & 0xFF)
      }
      set {
        guard indices.contains(idx) else { fatalError("index out of bounds") }
        data |= (Byte8(newValue) << Byte8(idx))
      }
    }
    var bytes: [Byte] { return data.bytes }
    init(_ bytes: [Byte]) { data = Byte8(bytes) }
    init(integerLiteral value: Byte8) { data = value }
  }

  struct Preset: ByteArrayConvertible {
    let fileURL: NSURL
    let lowerRegister: ProgramRegister
    let upperRegister: ProgramRegister
    var bytes: [Byte] { return lowerRegister.bytes + upperRegister.bytes + fileURL.absoluteString.bytes }
    init(_ bytes: [Byte]) {
      guard bytes.count > 17 else { fileURL = NSURL(string: "")!; lowerRegister = 0; upperRegister = 0; return }
      lowerRegister = ProgramRegister(bytes[0 ..< 8])
      upperRegister = ProgramRegister(bytes[8 ..< 16])
      fileURL = NSURL(string: String(bytes[17..<]))!
    }
    init(fileURL: NSURL,
         lowerRegister: ProgramRegister,
         upperRegister: ProgramRegister)
    {
      self.fileURL = fileURL
      self.lowerRegister = lowerRegister
      self.upperRegister = upperRegister
    }
  }

  typealias Program = Byte
  typealias Channel = Byte

  let soundSet: SoundSet
  let node = AVAudioUnitSampler()
  private var channelPrograms: [Program] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

  var bus: AVAudioNodeBus {
    guard let bus = node.destinationForMixer(AudioManager.engine.mainMixerNode, bus: 0)?.connectionPoint.bus else {
      fatalError("instrument not connected to main mixer node")
    }
    return bus
  }

  var preset: Preset {
    return Preset(fileURL: soundSet.url,
                  lowerRegister: ProgramRegister(channelPrograms[0 ..< 8]),
                  upperRegister: ProgramRegister(channelPrograms[8 ..< 16]))
  }

  /**
  setProgram:onChannel:

  - parameter program: Program
  - parameter onChannel: Channel
  */
  func setProgram(var program: Program, var onChannel channel: Channel) throws {
    program = ClosedInterval<Program>(0, 127).clampValue(program)
    channel = ClosedInterval<Channel>(0, 15).clampValue(channel)
    node.sendProgramChange(program, onChannel: channel)
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

  var description: String {
    return "\(self.dynamicType.self) { \n\tsoundSet: \(soundSet)\n\tchannelPrograms: \(channelPrograms)\n}"
  }

  private var client = MIDIClientRef()
  private(set) var endPoint = MIDIEndpointRef()

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
  init:

  - parameter set: SoundSet
  */
  init(soundSet set: SoundSet, program: Program = 0) throws {
    soundSet = set
    try node.loadSoundBankInstrumentAtURL(set.url,
                                  program: program,
                                  bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                  bankLSB: UInt8(kAUSampler_DefaultBankLSB))

    AudioManager.engine.attachNode(node)
    AudioManager.engine.connect(node, to: AudioManager.engine.mainMixerNode, format: nil)

    let name = "Instrument \(ObjectIdentifier(self).uintValue)"
    try MIDIClientCreateWithBlock(name, &client, nil) ➤ "Failed to create midi client"
    try MIDIDestinationCreateWithBlock(client, name, &endPoint, read)
      ➤ "Failed to create end point for instrument"
  }

  /**
  initWithPreset:

  - parameter preset: Preset
  */
  convenience init(preset: Preset) throws { try self.init(soundSet: try SoundSet(url: preset.fileURL)) }

}

/**
Equatable compliance

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.node == rhs.node }
