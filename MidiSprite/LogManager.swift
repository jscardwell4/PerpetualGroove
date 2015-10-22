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

  static let MIDIFileContext  = LogContext(rawValue: 0b0000_0010_0000)
  static let SF2FileContext   = LogContext(rawValue: 0b0000_0100_0000)
  static let SequencerContext = LogContext(rawValue: 0b0000_1000_0000)
  static let SceneContext     = LogContext(rawValue: 0b0001_0000_0000)

  static func initialize() {
    guard !initialized else { return }



    MIDIDocumentManager.logContext     = MIDIFileContext
    MIDIDocument.logContext            = MIDIFileContext
    MIDIFile.logContext                = MIDIFileContext
    MIDIFileHeaderChunk.logContext     = MIDIFileContext
    MIDIFileTrackChunk.logContext      = MIDIFileContext
    MetaEvent.logContext               = MIDIFileContext
    ChannelEvent.logContext            = MIDIFileContext
    VariableLengthQuantity.logContext  = MIDIFileContext
    MIDINodeEvent.logContext           = MIDIFileContext
    MIDITrackEventContainer.logContext = MIDIFileContext

    SF2File.logContext    = SF2FileContext
    Instrument.logContext = SF2FileContext
    SoundSet.logContext   = SF2FileContext
    INFOChunk.logContext  = SF2FileContext
    SDTAChunk.logContext  = SF2FileContext
    PDTAChunk.logContext  = SF2FileContext

    Sequencer.logContext       = SequencerContext
    InstrumentTrack.logContext = SequencerContext
    MIDISequence.logContext    = SequencerContext
    AudioManager.logContext    = SequencerContext
    CABarBeatTime.logContext   = SequencerContext
    TimeSignature.logContext   = SequencerContext
    TrackColor.logContext      = SequencerContext
    TempoTrack.logContext      = SequencerContext
    Metronome.logContext       = SequencerContext
    MIDIClock.logContext       = SequencerContext
    BarBeatTime.logContext     = SequencerContext

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
extension MIDITrackEventContainer: Loggable {}
