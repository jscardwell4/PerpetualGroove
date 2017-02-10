//
//  Sequence.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// The `Sequence` class manaages a collection of tracks and serves as the top level 
/// object persisted by the `GrooveDocument` class.
final class Sequence: Nameable, NotificationDispatching, CustomStringConvertible {

  /// An enumeration wrapping supported data sources for a sequence.
  enum Data {

    /// The source data is a type 1 MIDI file.
    case midi (MIDIFile)

    /// The source data is a JSON file.
    case groove (GrooveFile)

  }

  /// The sequence currently loaded by the sequencer.
  static var current: Sequence? { return Sequencer.sequence }

  /// The time of the last event in the sequence.
  var sequenceEnd: BarBeatTime {

    // Return the maximum `endOfTrack` value or `zero` if there are no tracks.
    return tracks.map({$0.endOfTrack}).max() ?? BarBeatTime.zero

  }

  /// The collection of the sequence's tracks excluding the tempo track.
  private(set) var instrumentTracks: [InstrumentTrack] = []

  /// Swaps the position of the instrument tracks located at `idx1` and `idx2`.
  func exchangeInstrumentTrack(at idx1: Int, with idx2: Int) {

    // Check that both indexes are valid.
    guard instrumentTracks.indices.contains([idx1, idx2]) else { return }

    // Perform the swap.
    swap(&instrumentTracks[idx1], &instrumentTracks[idx2])

    Log.verbose("posting 'DidUpdate'")

    // Post notification that the sequence has updated.
    postNotification(name: .didUpdate, object: self)

  }

  /// The position of the currently selected track within `instrumentTracks` or `nil` if
  /// `instrumentTracks` is empty.
  var currentTrackIndex: Int? {

    get {

      // Return the index value for the current track.
      return currentTrack?.index

    }

    set {

      // Check that the new index value is valid.
      guard let newValue = newValue, instrumentTracks.indices.contains(newValue) else {

        // Deselect the current track by nullifying `currentTrack`.
        currentTrack = nil

        return

      }

      // Update `currentTrack` using the new index value.
      currentTrack = instrumentTracks[newValue]

    }

  }

  /// A stack structure holding weak references to instrument tracks. The top of this
  /// stack provides the `currentTrack` property value for the sequence. When a track is
  /// selected, a reference to the track is pushed to this stack. When a track is deleted,
  /// the stack is popped, effectively updating the value of `currentTrack`.
  private var currentTrackStack: Stack<Weak<InstrumentTrack>> = []

  /// The sequence's currently selected instrument track. Most of the operations performed
  /// by the mixer and the MIDI node player operate on the current track. This is a derived
  /// property backed by the sequence's internal stack of instrument track references.
  var currentTrack: InstrumentTrack? {

    get {

      // Pop any lingering references from the top of `currentTrackStack`.
      while !currentTrackStack.isEmpty && currentTrackStack.peek?.reference == nil {

        // Pop the `nil` reference out of the stack.
        currentTrackStack.pop()

      }

      // Return the reference at the top of `currentTrackStack`.
      return currentTrackStack.peek?.reference

    }

    set {

      switch newValue {

      case let newTrack?
        where currentTrackStack.peek?.reference !== newTrack:
        // A new track has been selected, push it onto the stack of instrument tracks.

        currentTrackStack.push(Weak(newTrack))
//          newTrack.recording = true

      case nil where !currentTrackStack.isEmpty:
        // The current track has been deselected.

        currentTrackStack.pop()

      default:
        // The new value is either already in the stack or the new value is `nil` and the
        // the stack is already empty.

        break

      }

      // Post notification that the current track has been changed.
      postNotification(name: .didChangeTrack, object: self)

    }

  }

  /// The tempo track for the sequence. When reading/writing to/from a type 1 MIDI file,
  /// the tempo track always precedes the list of instrument tracks.
  private(set) var tempoTrack: TempoTrack!

  /// The number of beats per minute used by the sequence. This property wraps the property
  /// of `tempoTrack` with the same name.
  var tempo: Double {
    get { return tempoTrack.tempo }
    set { tempoTrack.tempo = newValue }
  }

  /// The time signature information used by the sequence. This property wraps the property
  /// of `tempoTrack` with the same name.
  var timeSignature: TimeSignature {
    get { return tempoTrack.timeSignature }
    set { tempoTrack.timeSignature = newValue }
  }

  /// The ollection of all tracks in the sequence. This amounts to `instrumentTracks` with
  /// `tempoTrack` inserted as the first element in the collection.
  var tracks: [Track] {

    // Check that `tempoTrack` is safe to unwrap.
    guard tempoTrack != nil else { return instrumentTracks }

    // Return an array composed of the tempo track and the instrument tracks.
    return [tempoTrack] + instrumentTracks

  }

  /// Handles registration/reception of track and transport notifications.
  private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

  /// Indicates whether the sequence has been updated. This flag is to coalesce sequence
  /// updates occuring while the transport is playing into a single notification posted
  /// when the transport resets.
  private var hasChanges = false

  /// Handler for track update notifications. If the transport is playing, this method
  /// sets the `hasChanges` flag; otherwise, this method posts a `didUpdate` notification.
  private func trackDidUpdate(_ notification: Foundation.Notification) {

    // If the transport is currently playing.
    if Transport.current.isPlaying {

      // Set the `hashChanges` flag to `true` to postpone posting a notification.
      hasChanges = true
    }

    // Otherwise, post notification that the sequence has been updated.
    else {

      // Clear the `hasChanges` flag since a notification is being posted.
      hasChanges = false

      Log.debug("posting 'DidUpdate'")

      // Post the `didUpdate` notification.
      postNotification(name: .didUpdate, object: self)

    }

  }

  /// Handler for `didToggleRecording` notifications received from the current transport.
  private func toggleRecording(_ notification: Foundation.Notification) {

    // Update the tempo track's recording flag.
    tempoTrack.recording = Transport.current.isRecording

  }

  /// Handler for `soloStatusDidChange` notifications of a track. Sets the `forceMute`
  /// property of each `instrumentTrack` according to whether the track has it's solo flag
  /// set and which track is responsible for posting the notification.
  private func trackSoloStatusDidChange(_ notification: Foundation.Notification) {

    // Get the instrument track that posted `notification`, ensuring that the track
    // is owned by the sequence.
    guard let track = notification.object as? InstrumentTrack,
      track.sequence === self
      else
    {
      return
    }

    // Create a set composed of the soloing tracks.
    let soloTracks = Set(instrumentTracks.filter({ $0.solo }))

    // Iterate the instrument tracks to update their `forceMute` value.
    for track in instrumentTracks {

      // Set the track's `forceMute` value according to whether the track is soloing.
      track.forceMute = track ∉ soloTracks

    }

  }

  /// Handler for `didReset` notifications received from the current transport. This method
  /// checks whether the `hasChanges` flag has been set. If it has then this method clears
  /// the flag and posts the `didUpdate` notification for the sequence.
  private func sequencerDidReset(_ notification: Foundation.Notification) {

    // Check that the `hasChanges` flag has been set.
    guard hasChanges else { return }

    // Clear the flag since notification is being posted.
    hasChanges = false

    Log.verbose("posting 'DidUpdate'")

    // Post notification that the sequence has been updated.
    postNotification(name: .didUpdate, object: self)

  }

  /// A weak reference to the document that owns the sequence. This is the document object
  /// responsible for persisting the sequence.
  private(set) weak var document: Document!

  /// Initializing with a document. This is thet default intializer for `Sequence`.
  /// - TODO: Review transport notification observations. Should both of the sequencer's 
  ///         transports be observed or just the primary?
  init(document: Document) {

    // Initialize `document` with the specified document.
    self.document = document

    // Get the current transport.
    let transport = Transport.current

    // Register to receive the transport's `didToggleRecording` notifications.
    receptionist.observe(name: .didToggleRecording, from: transport,
                callback: weakMethod(self, Sequence.toggleRecording))

    // Register to receive the transport's `didReset` notifications.
    receptionist.observe(name: .didReset, from: transport,
                callback: weakMethod(self, Sequence.sequencerDidReset))

    // Initialize `tempoTrack` by creating a new track for the sequence.
    tempoTrack = TempoTrack(sequence: self)

  }

  /// Initializing with MIDI file data belonging to a document. After the default 
  /// initializer has been invoked passing `document`, the MIDI event data in `file` is
  /// used to generate the sequence's tempo and instrument tracks.
  convenience init(file: MIDIFile, document: Document) {

    // Invoke the default initializer with the specified document.
    self.init(document: document)

    // Get the file's track chunks. The array is converted into a slice so the variable
    // can be updated should the first track be consumed before the collection is iterated.
    var trackChunks = ArraySlice(file.tracks)

    // If the first track chunk contains only tempo-related events replace the empty
    // tempo track created in the default initializer with a tempo track intialized
    // using the first track chunk.
    if let trackChunk = trackChunks.first,
      trackChunk.events.first(where: { !TempoTrack.isTempoTrackEvent($0) }) == nil
    {

      // Initialize the tempo track using the first track chunk.
      tempoTrack = TempoTrack(sequence: self, trackChunk: trackChunk)

      // Remove the first track chunk from the array of unprocessed track chunks.
      trackChunks = trackChunks.dropFirst()

    }

    // Iterate the unprocessed track chunks.
    for trackChunk in trackChunks {

      // Initialize a new track using the track chunk.
      guard let track = try? InstrumentTrack(sequence: self, trackChunk: trackChunk) else {
        continue
      }

      // Add the track to the sequence.
      add(track: track)

    }

  }

  /// Initializing with JSON fiie data belonging to a document. After the default
  /// initializer has been invoked passing `document`, the sequence's tempo and instrument
  /// tracks are generated using data obtained from `file`.
  convenience init(file: GrooveFile, document: Document) {

    // Invoke the default initializer with the specified document.
    self.init(document: document)

    // Create an array for accumulating tempo events.
    var tempoEvents: [MIDIEvent] = []

    // Iterate through the tempo changes contained by `file`.
    for (key: rawTime, value: bpmValue) in file.tempoChanges.value {

      // Convert the key-value pair into `BarBeatTime` and `Double` values.
      guard let time = BarBeatTime(rawValue: rawTime),
            let bpm = Double(bpmValue)
        else
      {
        continue
      }

      // Create a meta event using the converted values.
      let tempoEvent = MIDIEvent.MetaEvent(data: .tempo(bpm: bpm), time: time)

      // Append a MIDI event wrapping `tempoEvent` to the array of tempo events.
      tempoEvents.append(.meta(tempoEvent))

    }

    // Append the tempo events extracted from `file` to the tempo track created in
    // the default initializer.
    tempoTrack.add(events: tempoEvents)

    // Iterate through the file's instrument track data.
    for trackData in file.tracks {

      // Initialize a new track using `trackData`.
      guard let track = try? InstrumentTrack(sequence: self, grooveTrack: trackData) else {
        continue
      }

      // Add the track to the sequence.
      add(track: track)

    }

  }

  /// Creates and adds a track to the sequence for the specified instrument. Posts a
  /// `didUpdate` notification for the sequence after the new track has been added.
  /// - Throws: Any error encountered creating the track with `instrument`.
  /// - TODO: Should the notification coalescing behavior for `didUpdate` notifications
  ///         be expanded to handle intializing a sequence with multiple tracks?
  func insertTrack(instrument: Instrument) throws {

    // Create a new track for the sequence that uses the specified instrument.
    let track = try InstrumentTrack(sequence: self, instrument: instrument)

    // Add the track to the sequence.
    add(track: track)

    Log.verbose("posting 'DidUpdate'")

    // Post notification that the sequence has been updated.
    postNotification(name: .didUpdate, object: self)

  }

  /// Appends `track` to the collection of instrument tracks, registers to receive
  /// notifications from `track`, posts a `didAddTrack` notification, and selects `track`
  /// as the current track when `currentTrack` is `nil`.
  private func add(track: InstrumentTrack) {

    // Check that the sequence has not already added the track.
    guard !instrumentTracks.contains(track) else { return }

    // Append `track` to the collection of instrument tracks.
    instrumentTracks.append(track)

    // Register to receive `didUpdate` notifications from the track.
    receptionist.observe(name: .didUpdate, from: track,
                         callback: weakMethod(self, Sequence.trackDidUpdate))

    // Register to receive `soloStatusDidChange` notifications from the track.
    receptionist.observe(name: .soloStatusDidChange, from: track,
                         callback: weakMethod(self, Sequence.trackSoloStatusDidChange))

    Log.debug("track added: \(track.name)")

    // Post notification that the track was added to the sequence.
    postNotification(name: .didAddTrack, object: self,
                     userInfo: ["addedTrackIndex": instrumentTracks.count - 1])

    // Update `currentTrack` when `nil`.
    if currentTrack == nil { currentTrack = track }

  }

  /// Removes the track at the specified position from `instrumentTracks`, removing any 
  /// MIDI nodes belonging to the track from the MIDI node player, and posting 
  /// `didRemoveTrack` and `didUpdate` notifications for the sequence.
  func removeTrack(at index: Int) {

    // Get the instrument track, removing it from the collection.
    let track = instrumentTracks.remove(at: index)

    // Stop and remove all the track's MIDI nodes.
    track.nodeManager.stopNodes(remove: true)

    // Stop receiving notifications from the track.
    receptionist.stopObserving(object: track)

    Log.debug("track removed: \(track.name)")

    // Post notification that the track has been removed from the sequence.
    postNotification(name: .didRemoveTrack, object: self,
                     userInfo: ["removedTrackIndex": index, "removedTrack": track])

    Log.debug("posting 'DidUpdate'")

    // Post notification that the sequence has been updated.
    postNotification(name: .didUpdate, object: self)

  }

  /// The name of the sequence. This property propagates the localized name of the
  /// sequence's document.
  var name: String? { return document?.localizedName }

  var description: String {

    var result = "\ntracks:\n"

    let trackDescriptions = tracks.map({ $0.description.indented(by: 1, useTabs: true) })

    result.append(trackDescriptions.joined(separator: "\n\n"))

    return result
  }

  /// An enumeration of the names given to notifications posted by a sequence.
  enum NotificationName: String, LosslessStringConvertible {

    /// Posted when a track is added to a sequence.
    case didAddTrack

    /// Posted when a track is removed from a sequence.
    case didRemoveTrack

    /// Posted when a sequence changes which track is the current track.
    case didChangeTrack

    /// Posted when a sequence has modified persisted data.
    case didUpdate

    var description: String { return rawValue }

    init?(_ description: String) { self.init(rawValue: description) }

  }

}

extension Notification {

  /// The postion in the sequence's collection of instrument tracks from which a track
  /// has been removed or `nil` when the notification is not a `didRemoveTrack` notificaiton
  /// posted by a sequence. The removed track is made available via `removedTrack`.
  var removedTrackIndex: Int? { return userInfo?["removedTrackIndex"] as? Int }

  /// The postion in the sequence's collection of instrument tracks containing a newly
  /// added track or `nil` when the notification is a `didAddTrack` notification posted
  /// by a sequence.
  var addedTrackIndex: Int? { return userInfo?["addedTrackIndex"] as? Int }

  /// The instrument track removed by a sequence or `nil` when the notification is not a
  /// `didRemoveTrack` notification posted by a sequence.
  var removedTrack: InstrumentTrack? { return userInfo?["removedTrack"] as? InstrumentTrack }

}
