//
//  Sequence.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Common
import Foundation
import MIDI
import MoonKit

extension Sequencer {

  /// The `Sequence` class manages a collection of tracks and serves as the top level
  /// object persisted by the `GrooveDocument` class.
  public final class Sequence {
    // MARK: Stored Properties

    /// The collection of the sequence's tracks excluding the tempo track.
    public private(set) var instrumentTracks: [InstrumentTrack] = []

    /// The tempo track for the sequence. When reading/writing to/from a type 1 MIDI file,
    /// the tempo track always precedes the list of instrument tracks.
    public private(set) lazy var tempoTrack = TempoTrack(sequence: self)

    /// A stack structure holding weak references to instrument tracks. The top of this
    /// stack provides the `currentTrack` property value for the sequence. When a track is
    /// selected, a reference to the track is pushed to this stack. When a track is deleted,
    /// the stack is popped, effectively updating the value of `currentTrack`.
    private var currentTrackStack: Stack<Weak<InstrumentTrack>> = []

    /// Handles registration/reception of track and transport notifications.
    private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

    // MARK: Initialization

    /// The default initializer.
    public init() {}

    /// Initializing with MIDI file data. After the default
    /// initializer has been invoked passing `document`, the MIDI event data in `file` is
    /// used to generate the sequence's tempo and instrument tracks.
    public convenience init(file: File) {
      // Invoke the default initializer with the specified document.
      self.init()

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

    // MARK: Computed Properties

    /// The time of the last event in the sequence.
    public var sequenceEnd: BarBeatTime { tracks.map(\.endOfTrack).max() ?? .zero }

    /// The position of the currently selected track within `instrumentTracks`.
    public var currentTrackIndex: Int? {
      get { currentTrack?.index }
      set { currentTrack = newValue == nil ? nil : instrumentTracks[newValue!] }
    }

    /// The sequence's currently selected instrument track. Most of the operations
    /// performed by the mixer and the MIDI node player operate on value of this property
    /// of the sequence currently in use. This is a derived property backed by the
    /// sequence's internal stack of instrument track references.
    public var currentTrack: InstrumentTrack? {
      get {
        // Pop any lingering references from the top of `currentTrackStack`.
        while !currentTrackStack.isEmpty, currentTrackStack.peek?.reference == nil {
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

        case nil where !currentTrackStack.isEmpty:
          // The current track has been deselected.

          currentTrackStack.pop()

        default:
          // The new value is either already in the stack or the new value is `nil` and the
          // the stack is already empty.

          break
        }
      }
    }

    /// The number of beats per minute used by the sequence. This property wraps the property
    /// of `tempoTrack` with the same name.
    public var tempo: Double {
      get { tempoTrack.tempo }
      set { tempoTrack.tempo = newValue }
    }

    /// The time signature information used by the sequence. This property wraps the property
    /// of `tempoTrack` with the same name.
    public var timeSignature: TimeSignature {
      get { tempoTrack.timeSignature }
      set { tempoTrack.timeSignature = newValue }
    }

    /// The collection of all tracks in the sequence. This amounts to `instrumentTracks` with
    /// `tempoTrack` inserted as the first element in the collection.
    public var tracks: [Track] { [tempoTrack] + instrumentTracks }

    // MARK: Receiving Notifications

    /// Indicates whether the sequence has been updated. This flag is to coalesce sequence
    /// updates occuring while the transport is playing into a single notification posted
    /// when the transport resets.
    private var hasChanges = false

    /// Handler for track update notifications. If the transport is playing, this method
    /// sets the `hasChanges` flag; otherwise, this method posts a `didUpdate` notification.
    private func trackDidUpdate(_ notification: Foundation.Notification) {
      // If the transport is currently playing.
      if Sequencer.shared.transport.isPlaying {
        // Set the `hashChanges` flag to `true` to postpone posting a notification.
        hasChanges = true
      }

      // Otherwise, post notification that the sequence has been updated.
      else {
        // Clear the `hasChanges` flag since a notification is being posted.
        hasChanges = false

        logi("posting 'DidUpdate'")

        // Post the `didUpdate` notification.
        postNotification(name: .didUpdate, object: self)
      }
    }

    /// Handler for `didToggleRecording` notifications received from the current transport.
    private func toggleRecording(_ notification: Foundation.Notification) {
      // Update the tempo track's recording flag.
      tempoTrack.isRecording = Sequencer.shared.transport.isRecording
    }

    /// Handler for `soloStatusDidChange` notifications of a track. Sets the `forceMute`
    /// property of each `instrumentTrack` according to whether the track has it's solo flag
    /// set and which track is responsible for posting the notification.
    private func trackSoloStatusDidChange(_ notification: Foundation.Notification) {
      // Get the instrument track that posted `notification`, ensuring that the track
      // is owned by the sequence.
      guard let track = notification.object as? InstrumentTrack,
            track.sequence === self
      else {
        return
      }

      // Create a set composed of the soloing tracks.
      let soloTracks = Set(instrumentTracks.filter { $0.solo })

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

      logv("posting 'DidUpdate'")

      // Post notification that the sequence has been updated.
      postNotification(name: .didUpdate, object: self)
    }

    // MARK: Track Management

    /// Swaps the position of the instrument tracks located at `idx1` and `idx2`.
    public func exchangeInstrumentTrack(at idx1: Int, with idx2: Int) {
      // Check that both indexes are valid.
      guard instrumentTracks.indices.contains([idx1, idx2]) else { return }

      // Perform the swap.
      instrumentTracks.swapAt(idx1, idx2)

      logv("posting 'DidUpdate'")

      // Post notification that the sequence has updated.
      postNotification(name: .didUpdate, object: self)
    }

    /// Creates and adds a track to the sequence for the specified instrument. Posts a
    /// `didUpdate` notification for the sequence after the new track has been added.
    /// - Throws: Any error encountered creating the track with `instrument`.
    /// - TODO: Should the notification coalescing behavior for `didUpdate` notifications
    ///         be expanded to handle intializing a sequence with multiple tracks?
    public func insertTrack(instrument: Instrument) throws {
      // Create a new track for the sequence that uses the specified instrument.
      let track = try InstrumentTrack(sequence: self, instrument: instrument)

      // Add the track to the sequence.
      add(track: track)

      logv("posting 'DidUpdate'")

      // Post notification that the sequence has been updated.
      postNotification(name: .didUpdate, object: self)
    }

    /// Appends `track` to the collection of instrument tracks, registers to receive
    /// notifications from `track`, posts a `didAddTrack` notification, and selects `track`
    /// as the current track when `currentTrack` is `nil`.
    public func add(track: InstrumentTrack) {
      // Check that the sequence has not already added the track.
      precondition(!instrumentTracks.contains(track))

      // Append `track` to the collection of instrument tracks.
      instrumentTracks.append(track)

      // Register to receive `didUpdate` notifications from the track.
      receptionist.observe(name: .didUpdate, from: track,
                           callback: weakCapture(of: self, block: Sequence.trackDidUpdate))

      // Register to receive `soloStatusDidChange` notifications from the track.
      receptionist.observe(name: .soloStatusDidChange, from: track,
                           callback: weakCapture(of: self, block: Sequence.trackSoloStatusDidChange))

      logi("track added: \(track.name)")

      // Post notification that the track was added to the sequence.
      postNotification(name: .didAddTrack, object: self,
                       userInfo: ["addedTrackIndex": instrumentTracks.count - 1])

      // Update `currentTrack` when `nil`.
      if currentTrack == nil { currentTrack = track }
    }

    /// Removes the track at the specified position from `instrumentTracks`, removing any
    /// MIDI nodes belonging to the track from the MIDI node player, and posting
    /// `didRemoveTrack` and `didUpdate` notifications for the sequence.
    public func removeTrack(at index: Int) {
      // Get the instrument track, removing it from the collection.
      let track = instrumentTracks.remove(at: index)

      // Stop and remove all the track's MIDI nodes.
      track.nodeManager.stopNodes(remove: true)

      // Stop receiving notifications from the track.
      receptionist.stopObserving(object: track)

      logi("track removed: \(track.name)")

      // Post notification that the track has been removed from the sequence.
      postNotification(name: .didRemoveTrack, object: self,
                       userInfo: ["removedTrackIndex": index, "removedTrack": track])

      logi("posting 'DidUpdate'")

      // Post notification that the sequence has been updated.
      postNotification(name: .didUpdate, object: self)
    }
  }

}

// MARK: NotificationDispatching

extension Sequencer.Sequence: NotificationDispatching {
  /// An enumeration of the names given to notifications posted by a sequence.
  public enum NotificationName: String, LosslessStringConvertible {
    /// Posted when a track is added to a sequence.
    case didAddTrack

    /// Posted when a track is removed from a sequence.
    case didRemoveTrack

    /// Posted when a sequence changes which track is the current track.
    case didChangeTrack

    /// Posted when a sequence has modified persisted data.
    case didUpdate

    public var description: String { return rawValue }

    public init?(_ description: String) { self.init(rawValue: description) }
  }
}

public extension Notification {
  /// The postion in the sequence's collection of instrument tracks from which a track
  /// has been removed or `nil` when the notification is not a `didRemoveTrack` notificaiton
  /// posted by a sequence. The removed track is made available via `removedTrack`.
  var removedTrackIndex: Int? { userInfo?["removedTrackIndex"] as? Int }

  /// The postion in the sequence's collection of instrument tracks containing a newly
  /// added track or `nil` when the notification is a `didAddTrack` notification posted
  /// by a sequence.
  var addedTrackIndex: Int? { userInfo?["addedTrackIndex"] as? Int }

  /// The instrument track removed by a sequence or `nil` when the notification is not a
  /// `didRemoveTrack` notification posted by a sequence.
  var removedTrack: InstrumentTrack? { userInfo?["removedTrack"] as? InstrumentTrack }
}

public extension MIDI.File {
  /// Intializing with the tracks in a sequence.
  init(sequence: Sequencer.Sequence) {
    // Initialize `tracks` by mapping the tracks in the sequence to their generated chunks.
    let tracks = sequence.tracks.map { $0.chunk }

    // Initialize `header` to a chunk using default values and the number of tracks.
    let header = HeaderChunk(numberOfTracks: UInt16(tracks.count))

    self.init(tracks: tracks, header: header)
  }
}
