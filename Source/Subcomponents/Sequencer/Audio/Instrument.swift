//
//  Instrument.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/8/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import AVFoundation
import Foundation
import MIDI
import MoonKit
import SoundFont

// MARK: - Instrument

/// A class for generating audio output via a sampler loaded with a preset from a
/// sound font file.
public final class Instrument
{
  // MARK: Stored Properties
  
  /// The instrument's MIDI client.
  private var client = MIDIClientRef()
  
  /// The MIDI out port for the instrument.
  public private(set) var outPort = MIDIPortRef()
  
  /// The MIDI endpoint for the instrument.
  public private(set) var endPoint = MIDIEndpointRef()
  
  /// The sound font preset loaded into the instrument's sampler. Changes to the
  /// value of this property trigger the posting of sound font and program change
  /// notifications.
  public var preset: Preset
  {
    didSet
    {
      $soundFont = preset
      $channel = preset
      
      // Check that the sound font containing the preset has changed.
      if !preset.soundFont.isEqualTo(oldValue.soundFont)
      {
        // Post notification that the instrument's sound font has changed.
        postNotification(name: .instrumentSoundFontDidChange,
                         object: self,
                         userInfo: ["oldSoundFont": oldValue.soundFontName,
                                    "newSoundFont": preset.soundFontName])
      }
      
      // Check that the preset's header has changed.
      if preset.presetHeader != oldValue.presetHeader
      {
        // Post notification the instrument's program has changed.
        postNotification(name: .instrumentProgramDidChange,
                         object: self,
                         userInfo: ["oldProgramName": oldValue.programName,
                                    "newProgramName": preset.programName])
      }
    }
  }
  
  // MARK: Computed Properties
  
  /// The sound font utitlized by `preset`.
  @PassThrough(\Instrument.Preset.soundFont)
  public var soundFont: SoundFont2
  
  /// The MIDI channel used by the instrument. Wrapper for the `channel` property
  /// of `preset`.
  @WritablePassThrough(\Instrument.Preset.channel)
  public var channel: UInt8
  
  /// The MIDI bank containing the MIDI program loaded by the instrument.
  @PassThrough(\Instrument.Preset.bank)
  public var bank: UInt8
  
  /// The MIDI program loaded by the instrument.
  @PassThrough(\Instrument.Preset.program)
  public var program: UInt8
  
  /// The sampler audio unit attached to the audio engine and connected to the
  /// mixer's output.
  private let sampler = AVAudioUnitSampler()
  
  /// The mixer input bus to which the instrument is connected.
  public var bus: AVAudioNodeBus
  {
    sampler.destination(forMixer: audioEngine.mixer, bus: 0)?.connectionPoint.bus ?? -1
  }
  
  /// The output level for the mixer input bus to which the instrument is connected.
  /// The value of this property is ≥ `0` and ≤ `1`.
  @ClampingWritablePassThrough(\AVAudioUnitSampler.volume, 0 ... 1)
  public var volume: Float
  
  /// The position in the stereo field for the mixer input bus to which the
  /// instrument is connected. The value of this property is ≥ `-1` and ≤ `1`
  /// which corresponds to full left and full right.
  @ClampingWritablePassThrough(\AVAudioUnitSampler.pan, -1 ... 1)
  public var pan: Float
  
  /// The gain in decibels of all notes played by the audio unit used by the
  /// instrument to generate audio output. The value of this property is ≥ `-90`
  /// and ≤ `12`. The default value is 0.
  @ClampingWritablePassThrough(\AVAudioUnitSampler.masterGain, -90 ... 12)
  public var masterGain: Float
  
  /// The position in the stereo field for the audio unit used by the instrument
  /// to generate audio output. The value of this property is ≥ `-1` and ≤ `1`
  /// which corresponds to full left and full right.
  @ClampingWritablePassThrough(\AVAudioUnitSampler.stereoPan, -1 ... 1)
  public var stereoPan: Float
  
  /// Sends a 'note on' event through `outPort` to `endPoint` using `generator`.
  /// Waits the duration specified by `generator` and then sends a 'note off'
  /// event through `outPort` to `endPoint`.
  ///
  /// - Parameter generator: Responsible for creating and sending the MIDI packets.
  public func playNote(_ generator: AnyGenerator)
  {
    do
    {
      // Use the generator to send a 'note on' event.
      try generator.sendNoteOn(outPort: outPort, endPoint: endPoint, ticks: time.ticks)
      
      // Translate the generator's duration into nanoseconds.
      let nanoseconds = UInt64(generator.duration.seconds(withBPM: sequencer.tempo)
                                * Double(NSEC_PER_SEC))
      
      // Convert the nanosecond value into a dispatch time.
      let deadline = DispatchTime(uptimeNanoseconds: nanoseconds)
      
      // Create a closure that sends the 'note off' event.
      let sendNoteOff = {
        [outPort = outPort, endPoint = endPoint] in
        
        do
        {
          // Use the generator to send a 'note off' event.
          try generator.sendNoteOff(
            outPort: outPort,
            endPoint: endPoint,
            ticks: time.ticks
          )
        }
        catch
        {
          // Just log the error.
          loge("\(error)")
        }
      }
      
      // Dispatch the closure for delayed execution.
      DispatchQueue.main.asyncAfter(deadline: deadline, execute: sendNoteOff)
    }
    catch
    {
      // Just log the error.
      loge("\(error as NSObject)")
    }
  }
  
  /// Handler for MIDI packets received through `endPoint`. This method simply
  /// iterates through `packetList` forwarding the packets to `sampler`.
  private func read(_ packetList: UnsafePointer<MIDIPacketList>,
                    context: UnsafeMutableRawPointer?)
  {
    // Iterate the packets in the packet list.
    for packet in packetList.pointee
    {
      // Send the packet to the sampler.
      sampler.sendMIDIEvent(packet.data.0, data1: packet.data.1, data2: packet.data.2)
    }
  }
  
  /// Loads `preset` into the instrument's sampler. This method does nothing if
  /// `preset` has already been loaded into the sampler as determined by the
  /// instrument's `preset` property.
  ///
  /// - Note: This is the only place, aside from the initializer, where a preset
  ///         is loaded into the sampler. Both here and in the intializer, the
  ///         `preset` property is set to the preset loaded into the sampler. In
  ///         this way, the instrument's `preset` property value stays synchronized
  ///         with the loaded sampler.
  ///
  /// - Parameter preset: Holds the sound font, program, and bank data for loading.
  /// - Throws: Any error encountered performing the sampler's load operation.
  public func load(preset: Preset) throws
  {
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
  ///   - preset: The preset to be loaded into the intrument's sampler.
  /// - Throws:
  ///   * `Error.AttachNodeFailed` when attaching the instrument's sampler to
  ///      the audio engine fails.
  ///   * Any error encountered loading the specified preset into the instrument's
  ///     sampler.
  ///   * Any error encountered creating the instrument's MIDI client.
  ///   * Any error encountered creating the out port for the instrument's MIDI client.
  ///   * Any error encountered creating the destination for the instrument's MIDI client.
  public init(preset: Preset, audioEngine: AudioEngine) throws
  {
    // Initialize the property values using the parameter values.
    self.preset = preset
    
    $volume = sampler
    $pan = sampler
    $masterGain = sampler
    $stereoPan = sampler
    
    // Use the audio manager to attach instrument's sampler to the audio engine.
    audioEngine.attach(node: sampler /* , for: self */ )
    
    // Check that the sampler has been attached to the audio engine.
    guard sampler.engine != nil else { throw Error.AttachNodeFailed }
    
    // Load the preset into the sampler.
    try sampler.loadSoundBankInstrument(at: preset.soundFont.url,
                                        program: preset.program,
                                        bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                        bankLSB: preset.bank)
    
    // Create a name for the instrument's MIDI client.
    let name = withUnsafePointer(to: self)
    {
      "Instrument \(UInt(bitPattern: $0))" as CFString
    }
    
    // Create the instrument's MIDI client.
    try require(MIDIClientCreateWithBlock(name, &client, nil),
                "Failed to create MIDI client")
    // Create the MIDI client's out port.
    try require(MIDIOutputPortCreate(client, "Output" as CFString, &outPort),
                "Failed tocreate out port")
    
    // Create the MIDI client's destination.
    try require(MIDIDestinationCreateWithBlock(client, name, &endPoint, read),
                "Failed tocreate endpoint")
  }
  
  /// Initializing with MIDI event data.
  /// - Parameters:
  ///   - instrument: The `MetaEvent` with the instrument name.
  ///   - program: The `ChannelEvent` with the program and channel information.
  /// - Throws: `Error.InvalidEvent` or `Error.AttachNodeFailed`
  public convenience init(instrument: MetaEvent, program: ChannelEvent) throws
  {
    // Get the instrument name from the event or throw.
    guard case var .text(name) = instrument.data,
          name.hasPrefix("instrument:"),
          program.status.kind == .programChange
    else { throw Error.InvalidEvent }
    
    // Drop the first 11 characters.
    name = String(name.dropFirst(11))
    
    // Retrieve the URL.
    guard let url = Bundle.main.url(forResource: name, withExtension: nil)
    else
    {
      throw Error.InvalidEvent
    }
    
    guard let soundFont: SoundFont2 =
            ((try? EmaxSoundFont(url: url)) ?? (try? AnySoundFont(url: url)))
    else
    {
      throw Error.InvalidEvent
    }
    
    let channel = program.status.channel
    let program = program.data1
    
    // Incorrectly, just assume a bank value of `0`.
    let bank: UInt8 = 0
    
    logw("\(#function) not yet fully implemented. The bank value needs handling")
    
    guard let header = soundFont[program: program, bank: bank]
    else
    {
      throw Error.InvalidEvent
    }
    
    // Create a preset using the derived values.
    let preset = Preset(soundFont: soundFont, presetHeader: header, channel: channel)
    
    try self.init(preset: preset, audioEngine: audioEngine)
  }
}

// MARK: Equatable

extension Instrument: Equatable
{
  /// Returns `true` iff both instruments use the same sampler.
  public static func == (lhs: Instrument, rhs: Instrument) -> Bool
  {
    lhs.sampler === rhs.sampler
  }
}

// MARK: CustomStringConvertible

extension Instrument: CustomStringConvertible
{
  public var description: String { "Instrument {preset: \(preset)}" }
}

// MARK: - Preset

public extension Instrument
{
  /// A struct for coupling a sound font, a preset header within the sound font,
  /// and a MIDI channel.
  struct Preset: Equatable, LosslessJSONValueConvertible
  {
    /// The sound font providing the source data for the preset.
    public let soundFont: SoundFont2
    
    /// The preset header within the sound font's file specified by this preset.
    public let presetHeader: PresetHeader
    
    /// The MIDI channel assigned to the preset.
    public var channel: UInt8
    
    /// The display name of the sound font.
    public var soundFontName: String { soundFont.displayName }
    
    /// The program name from the preset header.
    public var programName: String { presetHeader.name }
    
    /// The MIDI program value from the preset header.
    public var program: UInt8 { presetHeader.program }
    
    /// The MIDI bank value from the preset header.
    public var bank: UInt8 { presetHeader.bank }
    
    /// Initializing with a sound font, preset header, and MIDI channel.
    ///
    /// - Parameters:
    ///   - soundFont: The sound font to assign to the preset.
    ///   - presetHeader: The preset header to assign to the preset.
    ///   - channel: The MIDI channel to assign to the preset. The default value is `0`.
    public init(soundFont: SoundFont2, presetHeader: PresetHeader, channel: UInt8 = 0)
    {
      self.soundFont = soundFont
      self.presetHeader = presetHeader
      self.channel = channel
    }
    
    /// Returns `true` iff the `soundFont`, `presetHeader`, and `channel` values of
    /// `lhs` and `rhs` are equal.
    public static func == (lhs: Preset, rhs: Preset) -> Bool
    {
      lhs.soundFont.isEqualTo(rhs.soundFont)
        && lhs.presetHeader == rhs.presetHeader
        && lhs.channel == rhs.channel
    }
    
    /// A JSON object with entries for the preset's `soundFont`, `presetHeader`,
    /// and `channel` properties.
    public var jsonValue: JSONValue
    {
      ["soundFont": soundFont, "presetHeader": presetHeader, "channel": channel]
    }
    
    /// Initializing with a JSON value.
    /// - Parameter jsonValue: To be successful `jsonValue` must be a JSON object with
    ///                        'soundFont', 'presetHeader', and 'channel' entries whose
    ///                        values may be converted as appropriate for assigning to
    ///                        the preset's properties.
    public init?(_ jsonValue: JSONValue?)
    {
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
}

// MARK: - Error

public extension Instrument
{
  /// An enumeration of the possible errors thrown by `Instrument`.
  enum Error: String, Swift.Error
  {
    case AttachNodeFailed = "Failed to attach sampler node to audio engine"
    case InvalidEvent = "Invalid MIDI event provided"
  }
}

// MARK: NotificationDispatching

extension Instrument: NotificationDispatching
{
  public static let programDidChangeNotification =
    Notification.Name("programDidChange")
  
  public static let soundFontDidChangeNotification =
    Notification.Name("soundFontDidChange")
}

public extension Notification.Name
{
  static let instrumentProgramDidChange = Instrument.programDidChangeNotification
  static let instrumentSoundFontDidChange = Instrument.soundFontDidChangeNotification
}

public extension Notification
{
  /// The name of the program unloaded by the instrument that posted the notification.
  var oldProgramName: String? { userInfo?["oldProgram"] as? String }
  
  /// The name of the program loaded by the instrument that posted the notification.
  var newProgramName: String? { userInfo?["newProgram"] as? String }
  
  /// The name of the sound font unloaded by the instrument that posted the notification.
  var oldSoundFontName: String? { userInfo?["oldSoundFont"] as? String }
  
  /// The name of the sound font loaded by the instrument that posted the notification.
  var newSoundFontName: String? { userInfo?["newSoundFont"] as? String }
}
