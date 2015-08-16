//
//  Instrument.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import AVFoundation
import MoonKit
import AudioToolbox
import CoreAudio

struct InstrumentDescription: Hashable {
  let soundSet: SoundSet
  let program: UInt8
  let channel: MusicDeviceGroupID

  var hashValue: Int { return soundSet.hashValue ^ program.hashValue ^ channel.hashValue }
}

/**
Equatable compliance for `InstrumentDescription`

- parameter lhs: InstrumentDescription
- parameter rhs: InstrumentDescription

- returns: Bool
*/
func ==(lhs: InstrumentDescription, rhs: InstrumentDescription) -> Bool {
  return lhs.soundSet == rhs.soundSet && lhs.program == rhs.program && lhs.channel == rhs.channel
}

final class Instrument: Equatable {

  // MARK: - Properties

  let soundSet: SoundSet
  var program: UInt8
  var channel: MusicDeviceGroupID

  var instrumentDescription: InstrumentDescription {
    return InstrumentDescription(soundSet: soundSet, program: program, channel: channel)
  }

  private let instrumentUnit: MusicDeviceComponent

  // MARK: - Initialization

  /**
  initWithSoundSet:program:channel:

  - parameter description: InstrumentDescription
  - parameter unit: MusicDeviceConponent
  */
  init(description: InstrumentDescription, unit: MusicDeviceComponent) throws {
    soundSet = description.soundSet
    program = description.program
    channel = description.channel
    instrumentUnit = unit

    var instrumentData = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(soundSet.url),
                                                 instrumentType: soundSet.instrumentType.rawValue,
                                                 bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                 bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                                                 presetID: program)


    try checkStatus(
      AudioUnitSetProperty(instrumentUnit,
                           AudioUnitPropertyID(kAUSamplerProperty_LoadInstrument),
                           AudioUnitScope(kAudioUnitScope_Global),
                           AudioUnitElement(0),
                           &instrumentData,
                           UInt32(sizeof(AUSamplerInstrumentData))),
      "Failed to load instrument into audio unit")

  }

  // MARK: - The Note struct
  struct Note {
    var duration = 0.25
    var value: MIDINote = .Pitch(letter: .C, octave: 4)
    var velocity: UInt8 = 64

    var noteParams: MusicDeviceNoteParams {
      var noteParams = MusicDeviceNoteParams()
      noteParams.argCount = 2
      noteParams.mPitch = Float(value.midi)
      noteParams.mVelocity = Float(velocity)
      return noteParams
    }
  }

  private var nodesPlaying: [String:NoteInstanceID] = [:]

  /**
  playNoteForNode:

  - parameter node: MIDINode
  */
  func playNoteForNode(node: MIDINode) throws {
    var noteID = NoteInstanceID()
    var noteParams = node.note.noteParams
    let status = MusicDeviceStartNote(instrumentUnit, kMusicNoteEvent_Unused, channel, &noteID, 0, &noteParams)
    try checkStatus(status, "MusicDeviceStartNote")
    nodesPlaying[node.id] = noteID
  }

  /**
  stopNoteForNode:

  - parameter node: MIDINode
  */
  func stopNoteForNode(node: MIDINode) throws {
    guard let playingNote = nodesPlaying.removeValueForKey(node.id) else { return }
    let channel = MusicDeviceGroupID(self.channel)
    let offset = UInt32(0)
    let status = MusicDeviceStopNote(instrumentUnit, channel, playingNote, offset)
    try checkStatus(status, "MusicDeviceStopNote")
  }

}

/**
subscript:rhs:

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.instrumentUnit == rhs.instrumentUnit }
