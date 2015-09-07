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

  enum Error: String, ErrorType {
    case InvalidFileName = "Failed to locate the specified instrument file"
  }

  var event: InstrumentEvent {
    let fileType: InstrumentEvent.FileType = soundSet.instrumentType == .EXS24 ? .EXS : .SF2
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
    let fileName: String
    let type: SoundSet.InstrumentType
    let lowerRegister: ProgramRegister
    let upperRegister: ProgramRegister
    var bytes: [Byte] { return lowerRegister.bytes + upperRegister.bytes + [type.rawValue] + fileName.bytes }
    init(_ bytes: [Byte]) {
      guard bytes.count > 17 else { type = .SF2; fileName = ""; lowerRegister = 0; upperRegister = 0; return }
      lowerRegister = ProgramRegister(bytes[0 ..< 8])
      upperRegister = ProgramRegister(bytes[8 ..< 16])
      type = SoundSet.InstrumentType(rawValue: bytes[16]) ?? .SF2
      fileName = String(bytes[17..<])
    }
    init(fileName: String,
         type: SoundSet.InstrumentType,
         lowerRegister: ProgramRegister,
         upperRegister: ProgramRegister)
    {
      self.fileName = fileName
      self.type = type
      self.lowerRegister = lowerRegister
      self.upperRegister = upperRegister
    }
  }

  typealias Program = Byte
  typealias Channel = MusicDeviceGroupID

  let soundSet: SoundSet
  let node: AUNode
  private var channelPrograms: [Program] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

  var preset: Preset {
    return Preset(fileName: soundSet.fileName,
                  type: soundSet.instrumentType,
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

  var description: String {
    return "\(self.dynamicType.self) { \n\tsoundSet: \(soundSet)\n\tchannelPrograms: \(channelPrograms)\n}"
  }

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
  init:

  - parameter set: SoundSet
  */
  init(soundSet set: SoundSet) throws {
    soundSet = set
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

    let name = "Instrument \(ObjectIdentifier(self).uintValue)"
    try MIDIClientCreateWithBlock(name, &client, nil) ➤ "Failed to create midi client"
    try MIDIDestinationCreateWithBlock(client, name, &endPoint, read) ➤ "Failed to create end point for instrument"
  }

  /**
  initWithPreset:

  - parameter preset: Preset
  */
  convenience init(preset: Preset) throws {
    guard let set = SoundSet(fileName: preset.fileName) else { throw Error.InvalidFileName }
    try self.init(soundSet: set)
  }

}

/**
Equatable compliance

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.audioUnit == rhs.audioUnit }
