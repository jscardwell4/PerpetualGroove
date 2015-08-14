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

class Instrument: Equatable {


  // MARK: - Properties

  let soundSet: SoundSet
  var program: UInt8
  var channel: MusicDeviceGroupID

  private var instrumentUnit: MusicDeviceComponent!

  // MARK: - Initialization

  /**
  initWithSoundSet:program:channel:

  - parameter soundSet: SoundSet
  - parameter program: UInt8 = 0
  - parameter channel: MusicDeviceGroupID = 0
  */
  init(soundSet s: SoundSet, program p: UInt8 = 0, channel c: MusicDeviceGroupID = 0, unit: MusicDeviceComponent? = nil) throws {
    soundSet = s
    program = p
    channel = c
    if let unit = unit { instrumentUnit = unit }
    else { instrumentUnit = try MIDIManager.connectInstrument(self) }

    var instrumentData = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(soundSet.url),
                                                 instrumentType: soundSet.instrumentType.rawValue,
                                                 bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                 bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                                                 presetID: program)


    let status = AudioUnitSetProperty(
      instrumentUnit,
      AudioUnitPropertyID(kAUSamplerProperty_LoadInstrument),
      AudioUnitScope(kAudioUnitScope_Global),
      AudioUnitElement(0),
      &instrumentData,
      UInt32(sizeof(AUSamplerInstrumentData)))

    guard status == noErr else { throw MIDIManager.error(status, "AudioUnitSetProperty") }

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
    var status = noErr

//    stopNoteForNode(node)

    var noteID = NoteInstanceID()
    var noteParams = node.note.noteParams
    status = MusicDeviceStartNote(instrumentUnit, kMusicNoteEvent_Unused, MusicDeviceGroupID(channel), &noteID, 0, &noteParams)
    guard status == noErr else { throw MIDIManager.error(status, "MusicDeviceStartNote") }
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
    guard status == noErr else { throw MIDIManager.error(status, "MusicDeviceStopNote") }
  }

}

/**
subscript:rhs:

- parameter lhs: Instrument
- parameter rhs: Instrument

- returns: Bool
*/
func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.instrumentUnit == rhs.instrumentUnit }
