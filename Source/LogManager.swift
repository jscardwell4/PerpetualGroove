//
// LogManager.swift
// PerpetualGroove
//
// Created by Jason Cardwell on 10/21/15.
// Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// Singleton class responsible for configuring the logging environment used by the application.
final class LogManager {

  /// Flag indicating whether `initialize()` has been invoked.
  private static var isInitialized = false

  /// Context for log messages relating to MIDI files.
  static let MIDIFileContext = Logger.Context(rawValue: 0b0000_0010_0000) + .file

  /// Context for log messages relating to sound font files.
  static let SF2FileContext = Log.Context(rawValue: 0b0000_0100_0000) ∪ .file

  /// Context for log messages relating to the sequencer.
  static let SequencerContext = Log.Context(rawValue: 0b0000_1000_0000) ∪ .file

  /// Context for log messages relating to objects using `SpriteKit`.
  static let SceneContext = Log.Context(rawValue: 0b0001_0000_0000) ∪ .file

  /// Context for log messages relating to `UIKit`-based objects.
  static let UIContext = Log.Context(rawValue: 0b0010_0000_0000) ∪ .file

  /// Initializes the logging environment for use within the application.
  /// - requires: `isInitialized == false`.
  static func initialize() {

    // Check that this is the first invocation.
    guard !isInitialized else { return }

    // Initialize MoonKit.Log.
    Log.initialize()


    // Set the default global log level.
    Log.Level.globalLevel = .verbose

    // Configure log contexts.
    registerLogContextNames()
    setDefaultLogContexts()

    // Add the file loggers.
    addFileLoggers()

    // Update the flag.
    isInitialized = true

  }

  /// Attaches names to the primary logging contexts used by the application.
  static private func registerLogContextNames() {

    MIDIFileContext.name  = "MIDI"
    SF2FileContext.name   = "SoundFont"
    SequencerContext.name = "Sequencer"
    SceneContext.name     = "Scene"
    UIContext.name        = "UI"

    (MIDIFileContext ∪ .console).name  = "MIDI"
    (SF2FileContext ∪ .console).name   = "SoundFont"
    (SequencerContext ∪ .console).name = "Sequencer"
    (SceneContext ∪ .console).name     = "Scene"
    (UIContext ∪ .console).name        = "UI"

  }

  /// Adds file loggers for various logging contexts.
  static private func addFileLoggers() {
    for (context, subdirectory) in [
      (.any, "Default"),
      (MIDIFileContext, "MIDI"),
      (SF2FileContext, "SoundFont"),
      (SequencerContext, "Sequencer"),
      (SceneContext, "Scene"),
      (UIContext, "UI")
      ] as [(Log.Context, String)]
    {
      let manager = Log.FileLogger.LogManager(subdirectory: subdirectory)
      let logger = Log.FileLogger(manager: manager)
      logger.prohibitFileReuse = true
      Log.add(logger: logger, context: context)
    }

    // Print some basic information to aid with debugging.
    print([
      "main bundle: '\(Bundle.main.bundlePath)'",
      "default log directory: '\(Log.FileLogger.LogManager.LogsDirectory.defaultLogsDirectoryURL.path)'",
      "log level: \(Log.Level.globalLevel)"
      ].joined(separator: "\n"))

  }

  /// Sets the default log context for a multitude of types.
  static private func setDefaultLogContexts() {

    Log.Context.set(context: MIDIFileContext, forType: Manager.self)
    Log.Context.set(context: MIDIFileContext ∪ .console, forType: Document.self)
    Log.Context.set(context: MIDIFileContext, forType: MIDIFile.self)
    Log.Context.set(context: MIDIFileContext, forType: Documents.File.self)
    Log.Context.set(context: MIDIFileContext, forType: EventContainer.self)

    Log.Context.set(context: SF2FileContext, forType: SF2File.self)
    Log.Context.set(context: SF2FileContext, forType: Instrument.self)
    Log.Context.set(context: SF2FileContext, forType: AnySoundFont.self)

    Log.Context.set(context: SequencerContext, forType: Sequencer.self)
    Log.Context.set(context: SequencerContext, forType: Track.self)
    Log.Context.set(context: SequencerContext, forType: Sequence.self)
    Log.Context.set(context: SequencerContext, forType: AudioManager.self)
    Log.Context.set(context: SequencerContext, forType: BarBeatTime.self)
    Log.Context.set(context: SequencerContext, forType: TimeSignature.self)
    Log.Context.set(context: SequencerContext, forType: TrackColor.self)
    Log.Context.set(context: SequencerContext, forType: Metronome.self)
    Log.Context.set(context: SequencerContext, forType: MIDIClock.self)
    Log.Context.set(context: SequencerContext, forType: Time.self)
    Log.Context.set(context: SequencerContext, forType: Transport.self)

    Log.Context.set(context: SceneContext, forType: NodePlayer.self)
    Log.Context.set(context: SceneContext, forType: Scene.self)
    Log.Context.set(context: SceneContext, forType: PlayerNode.self)
    Log.Context.set(context: SceneContext, forType: AddTool.self)
    Log.Context.set(context: SceneContext, forType: RemoveTool.self)
    Log.Context.set(context: SceneContext, forType: GeneratorTool.self)
    Log.Context.set(context: SceneContext, forType: Node.self)

    Log.Context.set(context: UIContext, forType: ViewController.self)
    Log.Context.set(context: UIContext, forType: PurgatoryViewController.self)
    Log.Context.set(context: UIContext  ∪ .console, forType: Documents.ViewController.self)
    Log.Context.set(context: UIContext, forType: InstrumentViewController.self)
    Log.Context.set(context: UIContext, forType: GeneratorViewController.self)
    Log.Context.set(context: UIContext, forType: DocumentsViewLayout.self)
    Log.Context.set(context: UIContext, forType: MixerLayout.self)
    Log.Context.set(context: UIContext, forType: BarBeatTimeLabel.self)
    Log.Context.set(context: UIContext ∪ .console, forType: DocumentCell.self)
    Log.Context.set(context: UIContext ∪ .console, forType: DocumentItem.self)
    Log.Context.set(context: UIContext, forType: MixerCell.self)
    Log.Context.set(context: UIContext, forType: MixerContainer.ViewController.self)
    Log.Context.set(context: UIContext, forType: RootViewController.self)
    Log.Context.set(context: UIContext, forType: TransportViewController.self)

    Log.Context.set(context: .file, forType: SettingsManager.self)

  }

}

