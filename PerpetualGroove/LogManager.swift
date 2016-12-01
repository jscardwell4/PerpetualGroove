//
// LogManager.swift
// PerpetualGroove
//
// Created by Jason Cardwell on 10/21/15.
// Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import class SpriteKit.SKNode

final class LogManager {

  private static var initialized = false

  typealias Context = Log.Context

  static let MIDIFileContext  = Context(rawValue: 0b0000_0010_0000) ∪ .file
  static let SF2FileContext   = Context(rawValue: 0b0000_0100_0000) ∪ .file
  static let SequencerContext = Context(rawValue: 0b0000_1000_0000) ∪ .file
  static let SceneContext     = Context(rawValue: 0b0001_0000_0000) ∪ .file
  static let UIContext        = Context(rawValue: 0b0010_0000_0000) ∪ .file

  static func initialize() {
    guard !initialized else { return }

    Log.initialize()
    Log.Level.globalLevel = .verbose

    registerLogContextNames()

    setDefaultLogContexts()

    addFileLoggers()

    initialized = true
  }

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

  static private func addFileLoggers() {
    for (context, subdirectory) in [
      (.any, "Default"),
      (MIDIFileContext, "MIDI"),
      (SF2FileContext, "SoundFont"),
      (SequencerContext, "Sequencer"),
      (SceneContext, "Scene"),
      (UIContext, "UI")
      ] as [(Context, String)]
    {
      let manager = Log.FileLogger.LogManager(subdirectory: subdirectory)
      let logger = Log.FileLogger(context: context, manager: manager)
      logger.prohibitFileReuse = true
      Log.add(logger: logger)
    }
    print([
      "main bundle: '\(Bundle.main.bundlePath)'",
      "default log directory: '\(Log.FileLogger.LogManager.LogsDirectory.defaultLogsDirectoryURL.path)'",
      "log level: \(Log.Level.globalLevel)"
      ].joined(separator: "\n"))
  }

  static private func setDefaultLogContexts() {
    Context.set(context: MIDIFileContext, forType: DocumentManager.self)
    Context.set(context: MIDIFileContext ∪ .console, forType: Document.self)
    Context.set(context: MIDIFileContext, forType: MIDIFile.self)
    Context.set(context: MIDIFileContext, forType: GrooveFile.self)
    Context.set(context: MIDIFileContext, forType: MIDIEventContainer.self)

    Context.set(context: SF2FileContext, forType: SF2File.self)
    Context.set(context: SF2FileContext, forType: Instrument.self)
    Context.set(context: SF2FileContext, forType: SoundSet.self)

    Context.set(context: SequencerContext, forType: Sequencer.self)
    Context.set(context: SequencerContext, forType: Track.self)
    Context.set(context: SequencerContext, forType: Sequence.self)
    Context.set(context: SequencerContext, forType: AudioManager.self)
    Context.set(context: SequencerContext, forType: BarBeatTime.self)
    Context.set(context: SequencerContext, forType: TimeSignature.self)
    Context.set(context: SequencerContext, forType: TrackColor.self)
    Context.set(context: SequencerContext, forType: Metronome.self)
    Context.set(context: SequencerContext, forType: MIDIClock.self)
    Context.set(context: SequencerContext, forType: Time.self)
    Context.set(context: SequencerContext, forType: Transport.self)

    Context.set(context: SceneContext, forType: MIDINodePlayer.self)
    Context.set(context: SceneContext, forType: MIDINodePlayerScene.self)
    Context.set(context: SceneContext, forType: MIDINodeHistory.self)
    Context.set(context: SceneContext, forType: MIDINodePlayerNode.self)
    Context.set(context: SceneContext, forType: AddTool.self)
    Context.set(context: SceneContext, forType: RemoveTool.self)
    Context.set(context: SceneContext, forType: GeneratorTool.self)
    Context.set(context: SceneContext, forType: MIDINode.self)

    Context.set(context: UIContext, forType: MIDINodePlayerViewController.self)
    Context.set(context: UIContext, forType: PurgatoryViewController.self)
    Context.set(context: UIContext  ∪ .console, forType: DocumentsViewController.self)
    Context.set(context: UIContext, forType: InstrumentViewController.self)
    Context.set(context: UIContext, forType: GeneratorViewController.self)
    Context.set(context: UIContext, forType: DocumentsViewLayout.self)
    Context.set(context: UIContext, forType: MixerLayout.self)
    Context.set(context: UIContext, forType: BarBeatTimeLabel.self)
    Context.set(context: UIContext ∪ .console, forType: DocumentCell.self)
    Context.set(context: UIContext ∪ .console, forType: DocumentItem.self)
    Context.set(context: UIContext, forType: MixerCell.self)
    Context.set(context: UIContext, forType: MixerViewController.self)
    Context.set(context: UIContext, forType: RootViewController.self)
    Context.set(context: UIContext, forType: TransportViewController.self)

    Context.set(context: .file, forType: SettingsManager.self)
  }

}

