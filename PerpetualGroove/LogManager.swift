//
// LogManager.swift
// PerpetualGroove
//
// Created by Jason Cardwell on 10/21/15.
// Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import CocoaLumberjack
import class SpriteKit.SKNode

final class LogManager: MoonKit.LogManager {

  fileprivate(set) static var initialized = false

  static let MIDIFileContext  = LogContext(rawValue: 0b0000_0010_0000) ∪ .file
  static let SF2FileContext   = LogContext(rawValue: 0b0000_0100_0000) ∪ .file
  static let SequencerContext = LogContext(rawValue: 0b0000_1000_0000) ∪ .file
  static let SceneContext     = LogContext(rawValue: 0b0001_0000_0000) ∪ .file
  static let UIContext        = LogContext(rawValue: 0b0010_0000_0000) ∪ .file

  /** initialize */
  static func initialize() {
    guard !initialized else { return }

    #if LogLevelVerbose
      logLevel = .verbose
    #elseif LogLevelDebug
      logLevel = .debug
    #elseif LogLevelInfo
      logLevel = .info
    #elseif LogLevelWarning
      logLevel = .warning
    #elseif LogLevelError
      logLevel = .error
    #elseif LogLevelOff
      logLevel = .off
    #endif

    setLogLevel(.verbose, forType: NotificationReceptionist.self)

    registerLogContextNames()

    logContext = .console
    setDefaultLogContexts()

    addConsoleLoggers()
    addFileLoggers()

    initialized = true
  }

  /**
  defaultFileLoggerForContext:directory:

  - parameter context: LogContext
  - parameter subdirectory: String?

  - returns: DDFileLogger
  */
  static override func defaultFileLoggerForContext(_ context: LogContext, subdirectory: String?) -> DDFileLogger {
    let logger = super.defaultFileLoggerForContext(context, subdirectory: subdirectory)
    logger.doNotReuseLogFiles = true
    return logger
  }

  /** registerLogContextNames */
  static fileprivate func registerLogContextNames() {
    logContextNames[MIDIFileContext] = "MIDI"
    logContextNames[SF2FileContext] = "SoundFont"
    logContextNames[SequencerContext] = "Sequencer"
    logContextNames[SceneContext] = "Scene"
    logContextNames[UIContext] = "UI"
    logContextNames[MIDIFileContext ∪ .console] = "MIDI"
    logContextNames[SF2FileContext ∪ .console] = "SoundFont"
    logContextNames[SequencerContext ∪ .console] = "Sequencer"
    logContextNames[SceneContext ∪ .console] = "Scene"
    logContextNames[UIContext ∪ .console] = "UI"
  }

  /** addFileLoggers */
  static fileprivate func addFileLoggers() {
    let logsDirectory = self.logsDirectory
    addDefaultFileLoggerForContext(.any, subdirectory: "Default")
    addDefaultFileLoggerForContext(MIDIFileContext,   subdirectory: "MIDI")
    addDefaultFileLoggerForContext(SF2FileContext,    subdirectory: "SoundFont")
    addDefaultFileLoggerForContext(SequencerContext,  subdirectory: "Sequencer")
    addDefaultFileLoggerForContext(SceneContext,      subdirectory: "Scene")
    addDefaultFileLoggerForContext(UIContext,         subdirectory: "UI")
    print([
      "main bundle: '\(Bundle.main.bundlePath)'",
      "default log directory: '\(logsDirectory.path)'",
      "log level: \(logLevel)"
      ].joined(separator: "\n"))
  }

  /** setDefaultLogContexts */
  static fileprivate func setDefaultLogContexts() {
    DocumentManager.defaultLogContext         = MIDIFileContext//  ∪ .Console
    Document.defaultLogContext                = MIDIFileContext  ∪ .console
    MIDIFile.defaultLogContext                = MIDIFileContext//  ∪ .Console
    GrooveFile.defaultLogContext              = MIDIFileContext//  ∪ .Console
//    MIDIFile.HeaderChunk.defaultLogContext     = MIDIFileContext//  ∪ .Console
//    MIDIFile.TrackChunk.defaultLogContext      = MIDIFileContext//  ∪ .Console
//    MetaEvent.defaultLogContext               = MIDIFileContext//  ∪ .Console
//    ChannelEvent.defaultLogContext            = MIDIFileContext//  ∪ .Console
//    VariableLengthQuantity.defaultLogContext  = MIDIFileContext//  ∪ .Console
//    MIDINodeEvent.defaultLogContext           = MIDIFileContext//  ∪ .Console
    MIDIEventContainer.defaultLogContext      = MIDIFileContext//  ∪ .Console

    SF2File.defaultLogContext    = SF2FileContext//  ∪ .Console
    Instrument.defaultLogContext = SF2FileContext//  ∪ .Console
    SoundSet.defaultLogContext   = SF2FileContext//  ∪ .Console
    SF2File.INFOChunk.defaultLogContext  = SF2FileContext//  ∪ .Console
//    SF2File.SDTAChunk.defaultLogContext  = SF2FileContext//  ∪ .Console
    SF2File.PDTAChunk.defaultLogContext  = SF2FileContext//  ∪ .Console

    Sequencer.defaultLogContext       = SequencerContext//  ∪ .Console
    Track.defaultLogContext           = SequencerContext//  ∪ .Console
    Sequence.defaultLogContext        = SequencerContext//  ∪ .Console
    AudioManager.defaultLogContext    = SequencerContext//  ∪ .Console
    BarBeatTime.defaultLogContext     = SequencerContext//  ∪ .Console
    TimeSignature.defaultLogContext   = SequencerContext//  ∪ .Console
    TrackColor.defaultLogContext      = SequencerContext//  ∪ .Console
    Metronome.defaultLogContext       = SequencerContext//  ∪ .Console
    MIDIClock.defaultLogContext       = SequencerContext//  ∪ .Console
    Time.defaultLogContext            = SequencerContext//  ∪ .Console
    Transport.defaultLogContext       = SequencerContext//  ∪ .Console

    MIDINodePlayer.defaultLogContext           = SceneContext//  ∪ .Console
    MIDINodePlayerScene.defaultLogContext      = SceneContext//  ∪ .Console
    MIDINodeHistory.defaultLogContext      = SceneContext//  ∪ .Console
    MIDINodePlayerNode.defaultLogContext       = SceneContext//  ∪ .Console
    AddTool.defaultLogContext              = SceneContext//  ∪ .Console
    RemoveTool.defaultLogContext           = SceneContext//  ∪ .Console
    GeneratorTool.defaultLogContext        = SceneContext//  ∪ .Console
    MIDINode.defaultLogContext             = SceneContext//  ∪ .Console

    MIDINodePlayerViewController.defaultLogContext     = UIContext//  ∪ .Console
    PurgatoryViewController.defaultLogContext      = UIContext//  ∪ .Console
    DocumentsViewController.defaultLogContext      = UIContext  ∪ .console
    InstrumentViewController.defaultLogContext     = UIContext//  ∪ .Console
    GeneratorViewController.defaultLogContext      = UIContext//  ∪ .Console
    DocumentsViewLayout.defaultLogContext          = UIContext//  ∪ .Console
    MixerLayout.defaultLogContext                  = UIContext//  ∪ .Console
    BarBeatTimeLabel.defaultLogContext             = UIContext//  ∪ .Console
    DocumentCell.defaultLogContext                 = UIContext  ∪ .console
    DocumentItem.defaultLogContext                 = UIContext  ∪ .console
    MixerCell.defaultLogContext                    = UIContext//  ∪ .Console
    MixerViewController.defaultLogContext          = UIContext//  ∪ .Console
    RootViewController.defaultLogContext           = UIContext//  ∪ .Console
    TransportViewController.defaultLogContext      = UIContext//  ∪ .Console

    SettingsManager.defaultLogContext = .file
  }

}

extension SF2File: Loggable {}
extension Instrument: Loggable {}
extension SoundSet: Loggable {}
extension EmaxSoundSet: Loggable {}
extension SF2File.INFOChunk: Loggable {}
//extension SF2File.SDTAChunk: Loggable {}
extension SF2File.PDTAChunk: Loggable {}

extension Sequencer: Loggable {}
extension Track: Loggable {}
extension Sequence: Loggable {}
extension AudioManager: Loggable {}
extension BarBeatTime: Loggable {}
extension TimeSignature: Loggable {}
extension TrackColor: Loggable {}
extension Metronome: Loggable {}
extension MIDIClock: Loggable {}
extension Time: Loggable {}

extension DocumentManager: Loggable {}
extension Document: Loggable {}
extension MIDIFile: Loggable {}
//extension MIDIFile.HeaderChunk: Loggable {}
//extension MIDIFile.TrackChunk: Loggable {}
//extension MetaEvent: Loggable {}
//extension ChannelEvent: Loggable {}
//extension VariableLengthQuantity: Loggable {}
//extension MIDINodeEvent: Loggable {}
extension MIDINodeHistory: Loggable {}
extension MIDIEventContainer: Loggable {}
extension GrooveFile: Loggable {}

extension MIDINodePlayer: Loggable {}
extension MIDINodePlayerScene: Loggable {}
extension MIDINodePlayerNode: Loggable {}
extension AddTool: Loggable {}
extension RemoveTool: Loggable {}
extension GeneratorTool: Loggable {}
extension MIDINode: Loggable {}
extension SKNode: Nameable {}

extension RootViewController: Loggable {}
extension TransportViewController: Loggable {}
extension Transport: Loggable {}
extension MIDINodePlayerViewController: Loggable {}
extension PurgatoryViewController: Loggable {}
extension DocumentsViewController: Loggable {}
extension InstrumentViewController: Loggable {}
extension GeneratorViewController: Loggable {}
extension DocumentsViewLayout: Loggable {}
extension MixerViewController: Loggable {}
extension MixerLayout: Loggable {}
extension BarBeatTimeLabel: Loggable {}
extension DocumentCell: Loggable {}
extension DocumentItem: Loggable {}
extension MixerCell: Loggable {}

extension SettingsManager: Loggable {}
