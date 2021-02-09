//
//  Environment.swift
//  Sequencing
//
//  Created by Jason Cardwell on 2/6/21.
//
import Foundation
import SwiftUI
import SoundFont

/// An environment key for the audio engine.
private struct AudioEngineKey: EnvironmentKey
{
  static let defaultValue  = AudioEngine()
}

/// An environment key for the current transport.
/// The default is the linear mode transport.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
private struct CurrentTransportKey: EnvironmentKey
{
  static var defaultValue: Transport { LinearTransportKey.defaultValue }
}

/// An environment key for linear mode transport.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
private struct LinearTransportKey: EnvironmentKey
{
  static let defaultValue: Transport = Transport(name: Mode.linear.rawValue)
}

/// An environment key for the loop mode transport.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
private struct LoopTransportKey: EnvironmentKey
{
  static let defaultValue: Transport = Transport(name: Mode.loop.rawValue)
}

/// An environment key for the current node dispatch.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
private struct CurrentDispatchKey: EnvironmentKey
{
  static let defaultValue: NodeDispatch? = nil
}

/// An environment key for the current mode.
private struct CurrentModeKey: EnvironmentKey
{
  static let defaultValue: Mode = .linear
}

/// An environment key for the audition instrument.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
private struct AuditionInstrumentKey: EnvironmentKey
{
  static let defaultValue: Instrument =
    {
      do
      {
        let soundFont = SoundFont.keyboardsAndSynths
        let header = soundFont.presetHeaders[0]
        let preset = Instrument.Preset(font: soundFont, header: header)
        return try Instrument(preset: preset)
      }
      catch
      {
        fatalError("\(#fileID) \(#function) \(error)")
      }
    }()

}

/// An environment key for the player.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
private struct PlayerKey: EnvironmentKey
{
  static let defaultValue = Player(size: CGSize(square: 300))
}


/// An environment key for the player's toolset.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
private struct ToolsetKey: EnvironmentKey
{
  static let defaultValue = Toolset()
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension EnvironmentValues
{
  /// The audio engine.
  public var audioEngine: AudioEngine
  {
    get { self[AudioEngineKey.self] }
    set { self[AudioEngineKey.self] = newValue }
  }

  /// The current transport.
  public var currentTransport: Transport
  {
    get { self[CurrentTransportKey.self] }
    set { self[CurrentTransportKey.self] = newValue }
  }

  /// The linear mode transport.
  public var linearTransport: Transport
  {
    get { self[LinearTransportKey.self] }
    set { self[LinearTransportKey.self] = newValue }
  }

  /// The loop mode transport.
  public var loopTransport: Transport
  {
    get { self[LoopTransportKey.self] }
    set { self[LoopTransportKey.self] = newValue }
  }

  /// The current node dispatch.
  var currentDispatch: NodeDispatch?
  {
    get { self[CurrentDispatchKey.self] }
    set { self[CurrentDispatchKey.self] = newValue }
  }

  /// The current mode.
  public var currentMode: Mode
  {
    get { self[CurrentModeKey.self] }
    set { self[CurrentModeKey.self] = newValue }
  }

  /// The audition instrument.
  public var auditionInstrument: Instrument
  {
    get { self[AuditionInstrumentKey.self] }
    set { self[AuditionInstrumentKey.self] = newValue }
  }

  /// The player.
  public var player: Player
  {
    get { self[PlayerKey.self] }
    set { self[PlayerKey.self] = newValue }
  }

  /// The player's toolset.
  var toolset: Toolset
  {
    get { self[ToolsetKey.self] }
    set { self[ToolsetKey.self] = newValue }
  }
}
