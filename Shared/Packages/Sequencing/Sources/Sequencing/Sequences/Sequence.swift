//
//  Sequence.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/23/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import Foundation
import MIDI
import MoonDev
import SoundFont


// MARK: - Sequence

/// The `Sequence` class manages a collection of tracks and serves as the top level
/// object persisted by the `Document` class.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public final class Sequence: ObservableObject
{
  // MARK: Stored Properties

  @Published public var name: String = ""

  /// The collection of the sequence's tracks excluding the tempo track.
  public private(set) var instrumentTracks: [InstrumentTrack] = []

  /// The tempo track for the sequence. When reading/writing to/from a type 1 MIDI file,
  /// the tempo track always precedes the list of instrument tracks.
  public private(set) lazy var tempoTrack = TempoTrack(index: 0)

  /// A stack structure holding weak references to instrument tracks. The top of this
  /// stack provides the `currentTrack` property value for the sequence. When a track is
  /// selected, a reference to the track is pushed to this stack. When a track is deleted,
  /// the stack is popped, effectively updating the value of `currentTrack`.
  private var currentTrackStack: Stack<Weak<InstrumentTrack>> = []

  /// Holds the cancellable subscriptions to track related publishers.
  private var trackSubscriptions: [InstrumentTrack: Set<AnyCancellable>] = [:]

  /// Subject for publishing added tracks.
  private let trackAdditionSubject = PassthroughSubject<InstrumentTrack, Never>()

  /// Subject for publishing removed tracks.
  private let trackRemovalSubject = PassthroughSubject<InstrumentTrack, Never>()

  /// Subject for publishing track changes.
  private let trackChangeSubject = PassthroughSubject<Void, Never>()

  // MARK: Initialization

  /// The default initializer.
  public init() {}

  /// Initializing with MIDI file data. After the default
  /// initializer has been invoked passing `document`, the MIDI event data in `file` is
  /// used to generate the sequence's tempo and instrument tracks.
  public convenience init(file: MIDI.File)
  {
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
      tempoTrack = TempoTrack(index: 0, trackChunk: trackChunk)

      // Remove the first track chunk from the array of unprocessed track chunks.
      trackChunks = trackChunks.dropFirst()
    }

    // Iterate the unprocessed track chunks.
    for (index, trackChunk) in trackChunks.enumerated()
    {
      // Initialize a new track using the track chunk.
      guard let track = try? InstrumentTrack(index: index + 1, trackChunk: trackChunk)
      else
      {
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
  public var currentTrackIndex: Int?
  {
    get
    {
      guard let track = currentTrack,
            let index = instrumentTracks.firstIndex(of: track)
      else
      {
        return nil
      }
      return index
    }
    set { currentTrack = newValue == nil ? nil : instrumentTracks[newValue!] }
  }

  /// The sequence's currently selected instrument track. Most of the operations
  /// performed by the mixer and the MIDI node player operate on value of this property
  /// of the sequence currently in use. This is a derived property backed by the
  /// sequence's internal stack of instrument track references.
  public var currentTrack: InstrumentTrack?
  {
    get
    {
      // Pop any lingering references from the top of `currentTrackStack`.
      while !currentTrackStack.isEmpty, currentTrackStack.peek?.reference == nil
      {
        // Pop the `nil` reference out of the stack.
        currentTrackStack.pop()
      }

      // Return the reference at the top of `currentTrackStack`.
      return currentTrackStack.peek?.reference
    }

    set
    {
      switch newValue
      {
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
  public var tempo: Double
  {
    get { tempoTrack.tempo }
    set { tempoTrack.tempo = newValue }
  }

  /// The time signature information used by the sequence. This property wraps the property
  /// of `tempoTrack` with the same name.
  public var timeSignature: TimeSignature
  {
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
  private func trackDidUpdate()
  {
    // If the transport is currently playing.
    if Sequencer.shared.transport.isPlaying
    {
      // Set the `hashChanges` flag to `true` to postpone posting a notification.
      hasChanges = true
    }

    // Otherwise, post notification that the sequence has been updated.
    else
    {
      // Clear the `hasChanges` flag since a notification is being posted.
      hasChanges = false
    }
  }

  /// Handler for `didToggleRecording` notifications received from the current transport.
  private func toggleRecording(notification: Notification)
  {
    // Update the tempo track's recording flag.
    tempoTrack.isRecording = Sequencer.shared.transport.isRecording
  }

  /// Handler for `didReset` notifications received from the current transport. This method
  /// checks whether the `hasChanges` flag has been set. If it has then this method clears
  /// the flag and posts the `didUpdate` notification for the sequence.
  private func sequencerDidReset(_: Foundation.Notification)
  {
    // Check that the `hasChanges` flag has been set.
    guard hasChanges else { return }

    // Clear the flag since notification is being posted.
    hasChanges = false
  }

  // MARK: Track Management

  /// Swaps the position of the instrument tracks located at `idx1` and `idx2`.
  public func exchangeInstrumentTrack(at idx1: Int, with idx2: Int)
  {
    // Check that both indexes are valid.
    guard instrumentTracks.indices.contains([idx1, idx2]) else { return }

    // Perform the swap.
    instrumentTracks.swapAt(idx1, idx2)

    // Publish the change.
    trackChangeSubject.send()
  }

  /// Creates and adds a track to the sequence for the specified instrument. Posts a
  /// `didUpdate` notification for the sequence after the new track has been added.
  /// - Throws: Any error encountered creating the track with `instrument`.
  /// - TODO: Should the notification coalescing behavior for `didUpdate` notifications
  ///         be expanded to handle intializing a sequence with multiple tracks?
  public func insertTrack(instrument: Instrument) throws
  {
    // Create a new track for the sequence that uses the specified instrument.
    let track = try InstrumentTrack(index: instrumentTracks.count + 1,
                                    color: Track.Color[instrumentTracks.count],
                                    instrument: instrument)

    // Add the track to the sequence.
    add(track: track)
  }

  /// Appends `track` to the collection of instrument tracks, registers to receive
  /// notifications from `track`, posts a `didAddTrack` notification, and selects `track`
  /// as the current track when `currentTrack` is `nil`.
  public func add(track: InstrumentTrack)
  {
    // Check that the sequence has not already added the track.
    precondition(!instrumentTracks.contains(track))

    // Append `track` to the collection of instrument tracks.
    instrumentTracks.append(track)

    // Subscribe to track notifications.
    var subscriptions: Set<AnyCancellable> = []

    subscriptions.store
    {
      track.didUpdatePublisher.sink { self.trackDidUpdate() }
    }

    trackSubscriptions[track] = subscriptions

    // Publish the added track.
    trackAdditionSubject.send(track)

    // Update `currentTrack` when `nil`.
    if currentTrack == nil { currentTrack = track }
  }

  /// Removes the track at the specified position from `instrumentTracks`, removing any
  /// MIDI nodes belonging to the track from the MIDI node player, and posting
  /// `didRemoveTrack` and `didUpdate` notifications for the sequence.
  public func removeTrack(at index: Int)
  {
    // Get the instrument track, removing it from the collection.
    let track = instrumentTracks.remove(at: index)

    // Stop and remove all the track's MIDI nodes.
    track.nodeManager.stopNodes(remove: true)

    // Cancel notification subscriptions for the track.
    trackSubscriptions[track]?.forEach { $0.cancel() }

    // Publish the removed track.
    trackRemovalSubject.send(track)

    logi("track removed: \(track.name)")
  }
}

// MARK: - Publishers

@available(iOS 14.0, *)
extension Sequence
{
  public var trackAdditionPublisher: AnyPublisher<InstrumentTrack, Never>
  {
    trackAdditionSubject.eraseToAnyPublisher()
  }

  public var trackRemovalPublisher: AnyPublisher<InstrumentTrack, Never>
  {
    trackRemovalSubject.eraseToAnyPublisher()
  }

  public var trackChangePublisher: AnyPublisher<Void, Never>
  {
    trackChangeSubject.eraseToAnyPublisher()
  }
}

@available(iOS 14.0, *)
extension MIDI.File
{
  /// Intializing with the tracks in a sequence.
  public init(sequence: Sequence)
  {
    // Initialize `tracks` by mapping the tracks in the sequence to their generated chunks.
    let tracks = sequence.tracks.map { $0.chunk }

    // Initialize `header` to a chunk using default values and the number of tracks.
    let header = HeaderChunk(numberOfTracks: UInt16(tracks.count))

    self.init(tracks: tracks, header: header)
  }
}

// MARK: - Sequence + Mock

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension Sequence: Mock
{
  public static var mock: Sequence
  {
    let sequence = Sequence()
    for track in InstrumentTrack.mocks(3) { sequence.add(track: track) }
    logv("<\(#fileID) \(#function)> \(sequence)")
    return sequence
  }

  public static func mocks(_ count: Int) -> [Sequence] { (0 ..< count).map { _ in mock } }
}

// MARK: - Sequence + CustomStringConvertible

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension Sequence: CustomStringConvertible
{
  public var description: String
  {
    """
    [
      \(tracks.map(\.description).joined(separator: "\n  "))
    ]
    """
  }
}
