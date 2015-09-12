//
//  MIDIFile.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime


/** Struct that holds the data for a complete MIDI file */
struct MIDIFile: CustomStringConvertible {

  enum Format: Byte2 { case Zero, One, Two }

  let tracks: [TrackChunk]

  private let header: HeaderChunk

  /**
  initWithFile:

  - parameter file: NSURL
  */
  init(file: NSURL) throws {
//    var value: UInt8 = 0
//    withUnsafeMutablePointer(&value) { valuePtr in file.absoluteString.withCString{ filePtr in
//        NodeCapturingMIDISequence.ExtendedFileAttributeName.withCString {
//          namePtr in getxattr(filePtr, namePtr, valuePtr, 1, 0, 0)
//        } } }
//    guard value == 1 else { throw Error.NotNodeCaptureFile }
    guard let fileData = NSData(contentsOfURL: file) else {
      throw MIDIFileError(type: .ReadFailure, reason: "Failed to get data from '\(file)'")
    }

    let totalBytes = fileData.length
    guard totalBytes > 13 else {
      throw MIDIFileError(type:.FileStructurallyUnsound, reason: "Not enough bytes in file '\(file)'")
    }

    // Get a pointer to the underlying memory buffer
    let bytes = UnsafeBufferPointer<Byte>(start: UnsafePointer<Byte>(fileData.bytes), count: totalBytes)

    let headerBytes = bytes[bytes.startIndex ..< bytes.startIndex.advancedBy(14)]
    let h = try HeaderChunk(bytes: headerBytes)

    var tracksRemaining = h.numberOfTracks
    var t: [TrackChunk] = []

    var currentIndex = bytes.startIndex.advancedBy(14)

    while tracksRemaining > 0 {
      guard currentIndex.distanceTo(bytes.endIndex) > 8 else {
        throw MIDIFileError(type: .FileStructurallyUnsound,
                            reason: "Not enough bytes for remaining track chunks (\(tracksRemaining))")
      }
      guard bytes[currentIndex ..< currentIndex.advancedBy(4)].elementsEqual("MTrk".utf8) else {
        throw MIDIFileError(type: .InvalidHeader, reason: "Expected chunk header with type 'MTrk'")
      }
      let chunkLength = Byte4(bytes[currentIndex.advancedBy(4) ..< currentIndex.advancedBy(8)])
      guard currentIndex.advancedBy(Int(chunkLength) + 8) <= bytes.endIndex else {
        throw MIDIFileError(type:.FileStructurallyUnsound, reason: "Not enough bytes in track chunk \(t.count)")
      }

      let trackBytes = bytes[currentIndex ..< currentIndex.advancedBy(Int(chunkLength) + 8)]

      t.append(try TrackChunk(bytes: trackBytes))
      currentIndex.advanceBy(Int(chunkLength) + 8)
      tracksRemaining--
    }

    header = h
    tracks = t
  }

  /**
  initWithFormat:division:tracks:

  - parameter format: Format
  - parameter division: Byte2
  - parameter tracks: [MIDITrackType]
  */
  init(format: Format, division: Byte2, tracks: [MIDITrackType]) {
    self.tracks = tracks.flatMap({$0.chunk})
    header = HeaderChunk(format: .One, numberOfTracks: Byte2(tracks.count), division: division)
  }

  var bytes: [Byte] {
    var bytes = header.bytes
    var trackData: [[Byte]] = []
    for track in tracks {
      var previousTime: CABarBeatTime = .start
      var trackBytes: [Byte] = []
      for event in track.events {
        let eventTime = event.time
        let eventTimeTicks = eventTime.tickValue
        let previousTimeTicks = previousTime.tickValue
        let delta = eventTimeTicks > previousTimeTicks ? eventTimeTicks - previousTimeTicks : 0
        previousTime = eventTime
        let deltaTime = VariableLengthQuantity(delta)
        let eventBytes = deltaTime.bytes + event.bytes
        trackBytes.appendContentsOf(eventBytes)
      }
      trackData.append(trackBytes)
    }

    for trackBytes in trackData {
      bytes.appendContentsOf(Array("MTrk".utf8))
      bytes.appendContentsOf(Byte4(trackBytes.count).bytes)
      bytes.appendContentsOf(trackBytes)
    }

    return bytes
  }

  var description: String {
    var result = "\(self.dynamicType.self) {\n\t"
    result += "\n\t".join(
      "header: \(header.description.indentedBy(4, true))",
      "tracks: {\n" + ",\n".join(tracks.map({$0.description.indentedBy(8)}))
    )
    result += "\n\t}\n}"
    return result
  }
}

