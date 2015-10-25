//
//  LogManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

final class LogManager: MoonKit.LogManager {

  private static var initialized = false

  static let MIDIFileContext  = LogContext(rawValue: 0b0000_0010_0000) ∪ .Console
  static let SF2FileContext   = LogContext(rawValue: 0b0000_0100_0000)// ∪ .Console
  static let SequencerContext = LogContext(rawValue: 0b0000_1000_0000)// ∪ .Console
  static let SceneContext     = LogContext(rawValue: 0b0001_0000_0000)// ∪ .Console

  static func initialize() {
    guard !initialized else { return }

    setLogLevel(.Verbose, forType: NotificationReceptionist.self)

    MIDIDocumentManager.defaultLogContext     = MIDIFileContext
    MIDIDocument.defaultLogContext            = MIDIFileContext
    MIDIFile.defaultLogContext                = MIDIFileContext
    MIDIFileHeaderChunk.defaultLogContext     = MIDIFileContext
    MIDIFileTrackChunk.defaultLogContext      = MIDIFileContext
    MetaEvent.defaultLogContext               = MIDIFileContext
    ChannelEvent.defaultLogContext            = MIDIFileContext
    VariableLengthQuantity.defaultLogContext  = MIDIFileContext
    MIDINodeEvent.defaultLogContext           = MIDIFileContext
    MIDIEventContainer.defaultLogContext      = MIDIFileContext
    MIDIEventMap.defaultLogContext            = MIDIFileContext

    SF2File.defaultLogContext    = SF2FileContext
    Instrument.defaultLogContext = SF2FileContext
    SoundSet.defaultLogContext   = SF2FileContext
    INFOChunk.defaultLogContext  = SF2FileContext
    SDTAChunk.defaultLogContext  = SF2FileContext
    PDTAChunk.defaultLogContext  = SF2FileContext

    Sequencer.defaultLogContext       = SequencerContext
    InstrumentTrack.defaultLogContext = SequencerContext
    MIDISequence.defaultLogContext    = SequencerContext
    AudioManager.defaultLogContext    = SequencerContext
    CABarBeatTime.defaultLogContext   = SequencerContext
    TimeSignature.defaultLogContext   = SequencerContext
    TrackColor.defaultLogContext      = SequencerContext
    TempoTrack.defaultLogContext      = SequencerContext
    Metronome.defaultLogContext       = SequencerContext
    MIDIClock.defaultLogContext       = SequencerContext
    BarBeatTime.defaultLogContext     = SequencerContext

    MIDIPlayerScene.defaultLogContext     = SceneContext
    MIDINodeHistory.defaultLogContext     = SceneContext
    MIDIPlayerNode.defaultLogContext      = SceneContext
    MIDIPlayerFieldNode.defaultLogContext = SceneContext
    MIDINode.defaultLogContext            = SceneContext
    Placement.defaultLogContext           = SceneContext

    addConsoleLoggers()

    let defaultDirectory = defaultLogDirectory
    addDefaultFileLoggerForContext(.Console, directory: defaultDirectory)
    addDefaultFileLoggerForContext(MIDIFileContext, directory: defaultDirectory + "MIDI")
    addDefaultFileLoggerForContext(SF2FileContext, directory: defaultDirectory + "SoundFont")
    addDefaultFileLoggerForContext(SequencerContext, directory: defaultDirectory + "Sequencer")
    addDefaultFileLoggerForContext(SceneContext, directory: defaultDirectory + "Scene")

    logLevel = .Debug
    logContext = .Console

    logDebug("\n".join("main bundle: '\(NSBundle.mainBundle().bundlePath)'",
                       "default log directory: '\(defaultDirectory.path!)'"))

    initialized = true
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
extension InstrumentTrack: Loggable {}
extension MIDISequence: Loggable {}
extension AudioManager: Loggable {}
extension CABarBeatTime: Loggable {}
extension TimeSignature: Loggable {}
extension TrackColor: Loggable {}
extension TempoTrack: Loggable {}
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
extension MIDIEventMap: Loggable {}

extension MIDIPlayerScene: Loggable {}
extension MIDIPlayerNode: Loggable {}
extension MIDIPlayerFieldNode: Loggable {}
extension MIDINode: Loggable {}
extension Placement: Loggable {}
