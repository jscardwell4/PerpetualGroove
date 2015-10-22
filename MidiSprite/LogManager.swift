//
//  LogManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

final class LogManager: MoonKit.LogManager {

  private static var initialized = false

  static let MIDIFileContext  = LogContext(rawValue: 0b0010_0000)
  static let SF2FileContext   = LogContext(rawValue: 0b0100_0000)
  static let SequencerContext = LogContext(rawValue: 0b1000_0000)

  static func initialize() {
    guard !initialized else { return }

    MIDIDocumentManager.logContext = MIDIFileContext
    MIDIDocument.logContext = MIDIFileContext
    MIDIFile.logContext = MIDIFileContext
    SF2File.logContext = SF2FileContext
    Sequencer.logContext = SequencerContext

    addConsoleLoggers()

    let defaultDirectory = defaultLogDirectory
    addDefaultFileLoggerForContext(.Console, directory: defaultDirectory)

    let midiFileDirectory = defaultLogDirectory + "MIDI"
    addDefaultFileLoggerForContext(MIDIFileContext, directory: midiFileDirectory)

    let sf2FileDirectory  = defaultLogDirectory + "SF2"
    addDefaultFileLoggerForContext(SF2FileContext, directory: sf2FileDirectory)

    let sequencerDirectory = defaultLogDirectory + "Sequencer"
    addDefaultFileLoggerForContext(SequencerContext, directory: sequencerDirectory)

    logLevel = .Debug
    logContext = .Console

    logDebug(
      "\n".join(
        "main bundle: '\(NSBundle.mainBundle().bundlePath)'",
        "default log directory: '\(defaultDirectory.path!)'",
        "midi file log directory: '\(midiFileDirectory.path!)'",
        "sound font file log directory: '\(sf2FileDirectory.path!)'",
        "sequencer log directory: '\(sequencerDirectory.path!)'"
      )
    )

    initialized = true
  }

}

extension SF2File: Loggable {}
extension Sequencer: Loggable {}
extension MIDIDocumentManager: Loggable {}
extension MIDIFile: Loggable {}
extension MIDIDocument: Loggable {}
