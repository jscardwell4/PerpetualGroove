//   LogManager.swift   PerpetualGroove    Created by Jason Cardwell on
//10/21/15.   Copyright © 2015 Moondeer Studios. All rights reserved.

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime
import class SpriteKit.SKNode

final class LogManager: MoonKit.LogManager {

  private(set) static var initialized = false

  static let MIDIFileContext  = LogContext(rawValue: 0b0000_0010_0000)// ∪ .Console
  static let SF2FileContext   = LogContext(rawValue: 0b0000_0100_0000)// ∪ .Console
  static let SequencerContext = LogContext(rawValue: 0b0000_1000_0000)// ∪ .Console
  static let SceneContext     = LogContext(rawValue: 0b0001_0000_0000)// ∪ .Console
  static let UIContext        = LogContext(rawValue: 0b0010_0000_0000)// ∪ .Console

  /** initialize */
  static func initialize() {
    guard !initialized else { return }

    logLevel = .Debug
    setLogLevel(.Verbose, forType: NotificationReceptionist.self)

    logContext = .Console
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
  static override func defaultFileLoggerForContext(context: LogContext, subdirectory: String?) -> DDFileLogger {
    let logger = super.defaultFileLoggerForContext(context, subdirectory: subdirectory)
    logger.doNotReuseLogFiles = true
    return logger
  }

  /** addFileLoggers */
  static private func addFileLoggers() {
    let logsDirectory = self.logsDirectory
    addDefaultFileLoggerForContext([.File, .Console])
    addDefaultFileLoggerForContext(MIDIFileContext,  subdirectory: "MIDI")
    addDefaultFileLoggerForContext(SF2FileContext,   subdirectory: "SoundFont")
    addDefaultFileLoggerForContext(SequencerContext, subdirectory: "Sequencer")
    addDefaultFileLoggerForContext(SceneContext,     subdirectory: "Scene")
    addDefaultFileLoggerForContext(UIContext,        subdirectory: "UI")
    logDebug("\n".join("main bundle: '\(NSBundle.mainBundle().bundlePath)'",
                       "default log directory: '\(logsDirectory.path!)'"))
  }

  /** setDefaultLogContexts */
  static private func setDefaultLogContexts() {
    MIDIDocumentManager.defaultLogContext     = MIDIFileContext// ∪ .Console
    MIDIDocument.defaultLogContext            = MIDIFileContext// ∪ .Console
    MIDIFile.defaultLogContext                = MIDIFileContext// ∪ .Console
    MIDIFileHeaderChunk.defaultLogContext     = MIDIFileContext// ∪ .Console
    MIDIFileTrackChunk.defaultLogContext      = MIDIFileContext// ∪ .Console
    MetaEvent.defaultLogContext               = MIDIFileContext// ∪ .Console
    ChannelEvent.defaultLogContext            = MIDIFileContext// ∪ .Console
    VariableLengthQuantity.defaultLogContext  = MIDIFileContext// ∪ .Console
    MIDINodeEvent.defaultLogContext           = MIDIFileContext// ∪ .Console
    MIDIEventContainer.defaultLogContext      = MIDIFileContext// ∪ .Console

    SF2File.defaultLogContext    = SF2FileContext// ∪ .Console
    Instrument.defaultLogContext = SF2FileContext// ∪ .Console
    SoundSet.defaultLogContext   = SF2FileContext// ∪ .Console
    INFOChunk.defaultLogContext  = SF2FileContext// ∪ .Console
    SDTAChunk.defaultLogContext  = SF2FileContext// ∪ .Console
    PDTAChunk.defaultLogContext  = SF2FileContext// ∪ .Console

    Sequencer.defaultLogContext       = SequencerContext// ∪ .Console
    Track.defaultLogContext           = SequencerContext// ∪ .Console
    Sequence.defaultLogContext        = SequencerContext// ∪ .Console
    AudioManager.defaultLogContext    = SequencerContext// ∪ .Console
    CABarBeatTime.defaultLogContext   = SequencerContext// ∪ .Console
    TimeSignature.defaultLogContext   = SequencerContext// ∪ .Console
    TrackColor.defaultLogContext      = SequencerContext// ∪ .Console
    Metronome.defaultLogContext       = SequencerContext// ∪ .Console
    MIDIClock.defaultLogContext       = SequencerContext// ∪ .Console
    BarBeatTime.defaultLogContext     = SequencerContext// ∪ .Console

    MIDIPlayerScene.defaultLogContext     = SceneContext// ∪ .Console
    MIDINodeHistory.defaultLogContext     = SceneContext// ∪ .Console
    MIDIPlayerNode.defaultLogContext      = SceneContext// ∪ .Console
    MIDIPlayerFieldNode.defaultLogContext = SceneContext// ∪ .Console
    MIDINode.defaultLogContext            = SceneContext// ∪ .Console
    Placement.defaultLogContext           = SceneContext// ∪ .Console

    MIDIPlayerViewController.defaultLogContext     = UIContext// ∪ .Console
    PurgatoryViewController.defaultLogContext      = UIContext// ∪ .Console
    DocumentsViewController.defaultLogContext      = UIContext// ∪ .Console
    InstrumentViewController.defaultLogContext     = UIContext// ∪ .Console
    NoteViewController.defaultLogContext           = UIContext// ∪ .Console
    DocumentsViewLayout.defaultLogContext          = UIContext// ∪ .Console
    MixerLayout.defaultLogContext                  = UIContext// ∪ .Console
    BarBeatTimeLabel.defaultLogContext             = UIContext// ∪ .Console
    DocumentCell.defaultLogContext                 = UIContext// ∪ .Console
    DocumentItem.defaultLogContext                 = UIContext// ∪ .Console
    MixerCell.defaultLogContext                    = UIContext// ∪ .Console
    MixerViewController.defaultLogContext          = UIContext// ∪ .Console

    SettingsManager.defaultLogContext = .File
  }

}

extension SF2File: Loggable {}
extension Instrument: Loggable {}
extension SoundSet: Loggable {}
extension EmaxSoundSet: Loggable {}
extension INFOChunk: Loggable {}
extension SDTAChunk: Loggable {}
extension PDTAChunk: Loggable {}

extension Sequencer: Loggable {}
extension Track: Loggable {}
extension Sequence: Loggable {}
extension AudioManager: Loggable {}
extension CABarBeatTime: Loggable {}
extension TimeSignature: Loggable {}
extension TrackColor: Loggable {}
extension Metronome: Loggable {}
extension MIDIClock: Loggable {}
extension BarBeatTime: Loggable {}

extension MIDIDocumentManager: Loggable {}
extension MIDIDocument: Loggable {}
extension MIDIFile: Loggable {}
extension MIDIFileHeaderChunk: Loggable {}
extension MIDIFileTrackChunk: Loggable {}
extension MetaEvent: Loggable {}
extension ChannelEvent: Loggable {}
extension VariableLengthQuantity: Loggable {}
extension MIDINodeEvent: Loggable {}
extension MIDINodeHistory: Loggable {}
extension MIDIEventContainer: Loggable {}

extension MIDIPlayerScene: Loggable {}
extension MIDIPlayerNode: Loggable {}
extension MIDIPlayerFieldNode: Loggable {}
extension MIDINode: Loggable {}
extension Placement: Loggable {}
extension SKNode: Nameable {}

extension MIDIPlayerViewController: Loggable {}
extension PurgatoryViewController: Loggable {}
extension DocumentsViewController: Loggable {}
extension InstrumentViewController: Loggable {}
extension NoteViewController: Loggable {}
extension DocumentsViewLayout: Loggable {}
extension MixerViewController: Loggable {}
extension MixerLayout: Loggable {}
extension BarBeatTimeLabel: Loggable {}
extension DocumentCell: Loggable {}
extension DocumentItem: Loggable {}
extension MixerCell: Loggable {}

extension SettingsManager: Loggable {}
