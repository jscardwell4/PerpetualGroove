//
//  Instrument.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import SoundFont
import AVFoundation
import MIDI

/// A class for generating audio output via a sampler loaded with a preset from a sound font file.
final class Instrument: Equatable, CustomStringConvertible, NotificationDispatching {

  /// The sound font preset loaded into the instrument's sampler. Changes to the value of this
  /// property trigger the posting of sound font and program change notifications.
  var preset: Preset {

    didSet {

      // Check that the sound font containing the preset has changed.
      if !preset.soundFont.isEqualTo(oldValue.soundFont) {

        // Post notification that the instrument's sound font has changed.
        postNotification(name: .soundFontDidChange,
                         object: self,
                         userInfo: ["oldSoundFont": oldValue.soundFontName,
                                    "newSoundFont": preset.soundFontName])

      }

      // Check that the preset's header has changed.
      if preset.presetHeader != oldValue.presetHeader {

        // Post notification the instrument's program has changed.
        postNotification(name: .programDidChange,
                         object: self,
                         userInfo: ["oldProgramName": oldValue.programName,
                                    "newProgramName": preset.programName])

      }

    }

  }

  /// The sound font utitlized by `preset`.
  var soundFont: SoundFont2 { return preset.soundFont }

  /// The MIDI channel used by the instrument. Wrapper for the `channel` property of `preset`.
  var channel: UInt8 {
    get { return preset.channel }
    set { preset.channel = newValue }
  }

  /// The MIDI bank containing the MIDI program loaded by the instrument.
  var bank: UInt8 { return preset.bank }

  /// The MIDI program loaded by the instrument.
  var program: UInt8 { return preset.program }

  /// A weak reference to the instrument track to which the instrument has been assigned.
  weak var track: InstrumentTrack?

  /// The sampler audio unit attached to the audio engine and connected to the mixer's output.
  private let sampler = AVAudioUnitSampler()

  /// The mixer input bus to which the instrument is connected.
  var bus: AVAudioNodeBus {
    return sampler.destination(forMixer: AudioManager.mixer, bus: 0)?.connectionPoint.bus ?? -1
  }

  /// The output level for the mixer input bus to which the instrument is connected.
  /// The value of this property is ≥ `0` and ≤ `1`.
  var volume: Float {
    get { return sampler.volume }
    set { sampler.volume = (0 ... 1).clampValue(newValue)  }
  }

  /// The position in the stereo field for the mixer input bus to which the instrument is connected.
  /// The value of this property is ≥ `-1` and ≤ `1` which corresponds to full left and full right.
  var pan: Float {
    get { return sampler.pan }
    set { sampler.pan = (-1 ... 1).clampValue(newValue) }
  }

  /// The gain in decibels of all notes played by the audio unit used by the instrument to generate
  /// audio output. The value of this property is ≥ `-90` and ≤ `12`. The default value is 0.
  var masterGain: Float {
    get { return sampler.masterGain }
    set { sampler.masterGain = (-90 ... 12).clampValue(newValue) }
  }

  /// The position in the stereo field for the audio unit used by the instrument to generate audio
  /// output. The value of this property is ≥ `-1` and ≤ `1` which corresponds to full left and 
  /// full right.
  var stereoPan: Float {
    get { return sampler.stereoPan }
    set { sampler.stereoPan = newValue }
  }

  /// The instrument's MIDI client.
  private var client   = MIDIClientRef()

  /// The MIDI out port for the instrument.
  private(set) var outPort = MIDIPortRef()

  /// The MIDI endpoint for the instrument.
  private(set) var endPoint = MIDIEndpointRef()

  /// Sends a 'note on' event through `outPort` to `endPoint` using `generator`. Waits the duration
  /// specified by `generator` and then sends a 'note off' event through `outPort` to `endPoint`.
  /// - Parameter generator: Responsible for creating and sending the MIDI packets.
  func playNote(_ generator: AnyMIDIGenerator) {

    do {

      // Use the generator to send a 'note on' event.
      try generator.sendNoteOn(outPort: outPort, endPoint: endPoint)

      // Translate the generator's duration into nanoseconds.
      let nanoseconds = UInt64(generator.duration.seconds(withBPM: Sequencer.tempo) * Double(NSEC_PER_SEC))

      // Convert the nanosecond value into a dispatch time.
      let deadline = DispatchTime(uptimeNanoseconds: nanoseconds)

      // Create a closure that sends the 'note off' event.
      let sendNoteOff = {
        [outPort = outPort, endPoint = endPoint] in

        do {

          // Use the generator to send a 'note off' event.
          try generator.sendNoteOff(outPort: outPort, endPoint: endPoint)

        } catch {

          // Just log the error.
          loge("\(error)")

        }

      }

      // Dispatch the closure for delayed execution.
      DispatchQueue.main.asyncAfter(deadline: deadline, execute: sendNoteOff)

    } catch {

      // Just log the error.
      loge("\(error)")

    }

  }

  /// Handler for MIDI packets received through `endPoint`. This method simply iterates through
  /// `packetList` forwarding the packets to `sampler`.
  private func read(_ packetList: UnsafePointer<MIDIPacketList>,
                    context: UnsafeMutableRawPointer?)
  {
    // Iterate the packets in the packet list.
    for packet in packetList.pointee {

      // Send the packet to the sampler.
      sampler.sendMIDIEvent(packet.data.0, data1: packet.data.1, data2: packet.data.2)

    }

  }

  /// Loads `preset` into the instrument's sampler. This method does nothing if `preset` has
  /// already been loaded into the sampler as determined by the instrument's `preset` property.
  /// - Note: This is the only place, aside from the initializer, where a preset is loaded
  ///         into the sampler. Both here and in the intializer, the `preset` property is set
  ///         to the preset loaded into the sampler. In this way, the instrument's `preset` 
  ///         property value stays synchronized with the loaded sampler.
  /// - Parameter preset: Holds the sound font, program, and bank data for loading.
  /// - Throws: Any error encountered performing the sampler's load operation.
  func load(preset: Preset) throws {

    // Check that the preset has not already been loaded.
    guard self.preset != preset else { return }

    // Load the sampler using the `preset` property values.
    try sampler.loadSoundBankInstrument(at: preset.soundFont.url,
                                        program: preset.program,
                                        bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                        bankLSB: preset.bank)

    // Update the `preset` property.
    self.preset = preset

  }

  /// Initializing with a preset and an optional track.
  /// - Parameters:
  ///   - track: The instrument track to which the instrument should be assigned or `nil`.
  ///   - preset: The preset to be loaded into the intrument's sampler.
  /// - Throws: 
  ///   * `Error.AttachNodeFailed` when attaching the instrument's sampler to the audio engine fails.
  ///   * Any error encountered loading the specified preset into the instrument's sampler.
  ///   * Any error encountered creating the instrument's MIDI client.
  ///   * Any error encountered creating the out port for the instrument's MIDI client.
  ///   * Any error encountered creating the destination for the instrument's MIDI client.
  init(track: InstrumentTrack? = nil, preset: Preset) throws {

    // Initialize the property values using the parameter values.
    self.track = track
    self.preset = preset

    // Use the audio manager to attach instrument's sampler to the audio engine.
    AudioManager.attach(node: sampler, for: self)

    // Check that the sampler has been attached to the audio engine.
    guard sampler.engine != nil else { throw Error.AttachNodeFailed }

    // Load the preset into the sampler.
    try sampler.loadSoundBankInstrument(at: preset.soundFont.url,
                                     program: preset.program,
                                     bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                     bankLSB: preset.bank)

    // Create a name for the instrument's MIDI client.
    let name = withUnsafePointer(to: self) { "Instrument \(UInt(bitPattern: $0))" as CFString }

    // Create the instrument's MIDI client.
    try MIDIClientCreateWithBlock(name, &client, nil) ➤ "Failed to create MIDI client"

    // Create the MIDI client's out port.
    try MIDIOutputPortCreate(client, "Output" as CFString, &outPort) ➤ "Failed to create out port"

    // Create the MIDI client's destination.
    try MIDIDestinationCreateWithBlock(client, name, &endPoint, read) ➤ "Failed to create endpoint"

  }

  /// Returns `true` iff both instruments use the same sampler.
  static func ==(lhs: Instrument, rhs: Instrument) -> Bool { return lhs.sampler === rhs.sampler }

  var description: String {
    return "Instrument { track: \(track?.name ?? "nil"); preset: \(preset)}"
  }

  /// A struct for coupling a sound font, a preset header within the sound font, and a MIDI channel.
  struct Preset: Equatable, LosslessJSONValueConvertible {

    /// The sound font providing the source data for the preset.
    let soundFont: SoundFont2

    /// The preset header within the sound font's file specified by this preset.
    let presetHeader: PresetHeader

    /// The MIDI channel assigned to the preset.
    var channel: UInt8

    /// The display name of the sound font.
    var soundFontName: String { return soundFont.displayName }

    /// The program name from the preset header.
    var programName: String { return presetHeader.name }

    /// The MIDI program value from the preset header.
    var program: UInt8 { return presetHeader.program }

    /// The MIDI bank value from the preset header.
    var bank: UInt8 { return presetHeader.bank }

    /// Initializing with a sound font, preset header, and MIDI channel.
    /// - Parameters:
    ///   - soundFont: The sound font to assign to the preset.
    ///   - presetHeader: The preset header to assign to the preset.
    ///   - channel: The MIDI channel to assign to the preset. The default value is `0`.
    init(soundFont: SoundFont2, presetHeader: PresetHeader, channel: UInt8 = 0) {
      self.soundFont = soundFont
      self.presetHeader = presetHeader
      self.channel = channel
    }

    /// Returns `true` iff the `soundFont`, `presetHeader`, and `channel` values of `lhs` and `rhs`
    /// are equal.
    static func ==(lhs: Preset, rhs: Preset) -> Bool {
      return lhs.soundFont.isEqualTo(rhs.soundFont)
          && lhs.presetHeader == rhs.presetHeader
          && lhs.channel == rhs.channel
    }

    /// A JSON object with entries for the preset's `soundFont`, `presetHeader`, and `channel`
    /// properties.
    var jsonValue: JSONValue {
      return ["soundFont": soundFont, "presetHeader": presetHeader, "channel": channel]
    }

    /// Initializing with a JSON value.
    /// - Parameter jsonValue: To be successful `jsonValue` must be a JSON object with 'soundFont',
    ///                        'presetHeader', and 'channel' entries whose values may be converted
    ///                        as appropriate for assigning to the preset's properties.
    init?(_ jsonValue: JSONValue?) {

      // Extract the property values from the JSON value.
      guard let dict = ObjectJSONValue(jsonValue),
            let soundFont: SoundFont2 = EmaxSoundFont(dict["soundFont"])
                                       ?? AnySoundFont(dict["soundFont"]),
            let presetHeader = PresetHeader(dict["presetHeader"]),
            let channel = UInt8(dict["channel"])
        else
      {
        return nil
      }

      // Initialize the properties with the extracted values.
      self.soundFont = soundFont
      self.presetHeader = presetHeader
      self.channel = channel

    }

  }

  /// An enumeration of the possible errors thrown by `Instrument`.
  enum Error: String, Swift.Error {
    case AttachNodeFailed = "Failed to attach sampler node to audio engine"
  }

  /// An enumeration of names for notification posted by `Instrument`.
  enum NotificationName: String, LosslessStringConvertible {

    case programDidChange, soundFontDidChange

    var description: String { return rawValue }

    init?(_ description: String) { self.init(rawValue: description) }

  }

}

extension Notification {

  /// The name of the program unloaded by the instrument that posted the notification.
  var oldProgramName: String? { return userInfo?["oldProgram"] as? String }

  /// The name of the program loaded by the instrument that posted the notification.
  var newProgramName: String? { return userInfo?["newProgram"] as? String }

  /// The name of the sound font unloaded by the instrument that posted the notification.
  var oldSoundFontName: String? { return userInfo?["oldSoundFont"] as? String }

  /// The name of the sound font loaded by the instrument that posted the notification.
  var newSoundFontName: String? { return userInfo?["newSoundFont"] as? String }

}
