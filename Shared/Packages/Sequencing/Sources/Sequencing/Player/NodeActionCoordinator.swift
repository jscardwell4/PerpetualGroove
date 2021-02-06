//
//  NodeActionCoordinator.swift
//  Sequencing
//
//  Created by Jason Cardwell on 2/5/21.
//
import Combine
import Foundation
import MoonDev
import SpriteKit
import CoreMIDI
import MIDI
import Common

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
final class NodeActionCoordinator: ObservableObject
{
  unowned var node: MIDINode!

  var transport: Transport
  {
    willSet { subscriptions.removeAll() }
    didSet { if subscriptions.isEmpty || transport !== oldValue { updateSubscriptions() } }
  }

  /// The node's midi client.
  private var client = MIDIClientRef()

  /// The node's midi endpoint.
  let endPoint = MIDIEndpointRef()

  /// The bar beat time at which the node begins playing.
  private var initTime: BarBeatTime

  /// The speed and direction the node begins with at `initTime`.
  private var initialTrajectory: Trajectory

  /// Location pending for the node.
  private var pendingPosition: CGPoint?

  /// The unique identifier for the node that is preserved across file operations.
  let identifier: UUID

  /// Identifier for use in note on/off events.
  private lazy var senderID = UInt(bitPattern: ObjectIdentifier(self))

  /// Whether a note is ended via a note on event with velocity of 0 or note off event.
  static let useVelocityForOff = true

  /// The generator used to produce the midi data played each time the node
  /// touches a boundary.
  private(set) var generator: AnyGenerator
  {
    didSet
    {
      guard generator != oldValue else { return }
      playAction = NodeAction(key: .play, coordinator: self)
    }
  }

  /// Whether the node is currently moving about the screen.
  @Published private(set) var isStationary: Bool = false

  /// Whether the node is being jogged by the transport.
  @Published private(set) var isJogging: Bool

  /// Whether the node is scheduled for removal.
  private(set) var isPendingRemoval: Bool = false
  {
    didSet { if isPendingRemoval ^ oldValue { node?.isHidden = isPendingRemoval } }
  }

  /// Whether the node has sent a 'note on' event not yet stopped with a 'note off' event.
  @Published private(set) var isPlaying: Bool = false

  /// The path controlling the movement of the node.
  let flightPath: FlightPath

  /// The index of the current segment of `path` upon which the node is travelling.
  var currentSegment: Int = 0

  /// Pushes a new 'note on' event through `generator` and sets `isPlaying` to `true`.
  func sendNoteOn()
  {
    do
    {
      try generator.receiveNoteOn(endPoint: endPoint,
                                  identifier: senderID,
                                  ticks: Sequencer.shared.time.ticks)
      isPlaying = true
    }
    catch
    {
      loge("\(error as NSObject)")
    }
  }

  /// Pushes a new 'note off' event through `generator` and sets `isPlaying` to `false`.
  func sendNoteOff()
  {
    do
    {
      try generator.receiveNoteOff(endPoint: endPoint,
                                   identifier: senderID,
                                   ticks: Sequencer.shared.time.ticks)
      isPlaying = false
    }
    catch
    {
      loge("\(error as NSObject)")
      fatalError("Failed to send the 'note off' event through `generator`.")
    }
  }

  func didRemoveAction(for key: String)
  {
    if key == NodeAction.Key.fadeOutAndRemove.rawValue { sendNoteOff()}
  }

  func move() { moveAction.run() }

  /// Updates the node's position from `pendingPosition` when `pendingPosition != nil`.
  func updatePosition(_ timeInterval: TimeInterval)
  {
    guard let pending = pendingPosition else { return }
    node?.position = pending
    pendingPosition = nil
  }

  /// Causes node to fade out of the scene. If `remove == true` then the node
  /// is also removed.
  func fadeOut(remove: Bool = false)
  {
    (remove ? fadeOutAndRemoveAction : fadeOutAction).run()
  }

  /// Causes the node to fade into the scene.
  func fadeIn() { fadeInAction.run() }

  /// Handler for notifications indicating the node should begin jogging.
  private func didBeginJogging(notification: Notification)
  {
    precondition(!isJogging)

    logi("position: \(node!.position); path: \(flightPath)")

    isJogging = true
    node?.removeAllActions()
  }

  /// Handler for notifications indicating the node has jogged to a new location.
  private func didJog(notification: Notification)
  {
    precondition(isJogging)

    guard let time = notification.jogTime
    else
    {
      fatalError("notification does not contain ticks")
    }

    logi("time: \(time)")

    switch time
    {
      case <--initTime where !isPendingRemoval:
        // Time has moved backward past the point of the node's initial start.
        // Hide and flag for removal.

        isPendingRemoval = true

      case initTime|-> where isPendingRemoval:
        // Time has moved back within the bounds of the node's existence from an
        // earlier time. Reveal, unset the flag for removal, and fall through to
        // update the pending position.

        isPendingRemoval = false
        fallthrough

      case initTime|->:
        // Time has moved forward, update the pending position.

        guard let index = flightPath.segmentIndex(for: time)
        else
        {
          pendingPosition = nil
          break
        }

        pendingPosition = flightPath[index].location(for: time)

      default:
        // Time has moved further backward and node is already hidden and flagged
        // for removal.

        break
    }
  }

  /// Handler for notifications indicating the node has stopped jogging.
  private func didEndJogging(notification: Notification)
  {
    guard isJogging
    else
    {
      logw("Internal inconsistency, should have jogging flag set."); return
    }

    isJogging = false

    // Check whether the node should be removed.
    guard !isPendingRemoval
    else
    {
      node?.removeFromParent()
      return
    }

    // Check whether the node has been paused.
    guard !isStationary else { return }

    // Update the current segment and resume movement of the node.
    guard let nextSegment = flightPath.segmentIndex(for: Sequencer.shared.time.barBeatTime)
    else
    {
      fatalError("Failed to get the index for the next segment")
    }

    currentSegment = nextSegment

    moveAction.run()
  }

  /// Hander for notifications indicating that the sequencer's transport has begun.
  private func didStart(notification: Notification)
  {
    // Check that the node is paused; otherwise, it should already be moving.
    guard isStationary else { return }

    // Update state and begin moving.
    isStationary = false
    moveAction.run()
  }

  /// Handler for notifications indicating that the sequencer's transport has paused.
  private func didPause(notification: Notification)
  {
    // Check that the node is not already paused.
    guard !isStationary else { return }

    // Update state and stop moving.
    isStationary = true
    node?.removeAllActions()
  }

  /// Handler for notifications indicating that the sequencer's transport has reset.
  private func didReset(notification: Notification) { fadeOut(remove: true) }

  /// Cached 'play' action.
  private lazy var playAction = NodeAction(key: .play, coordinator: self)

  /// Cached 'fade out' action.
  private lazy var fadeOutAction = NodeAction(key: .fadeOut, coordinator: self)

  /// Cached 'fade out and remove' action.
  private lazy var fadeOutAndRemoveAction = NodeAction(key: .fadeOutAndRemove, coordinator: self)

  /// Cached 'fade in' action.
  private lazy var fadeInAction = NodeAction(key: .fadeIn, coordinator: self)

  /// Cached 'move' action.
  private lazy var moveAction = NodeAction(key: .move, coordinator: self)

  private var subscriptions: Set<AnyCancellable> = []

  init(name: String,
       trajectory: Trajectory,
       generator: AnyGenerator,
       identifier: UUID,
       initTime: BarBeatTime,
       transport: Transport,
       playerSize: CGSize) throws
  {
    self.transport = transport
    self.initTime = initTime
    initialTrajectory = trajectory
    self.generator = generator
    self.identifier = identifier
    isJogging = transport.isJogging

    // Generate the path and grab the initial segment.
    flightPath = FlightPath(trajectory: trajectory, playerSize: playerSize, time: initTime)

    // Create midi client and source.
    try require(MIDIClientCreateWithBlock(name as CFString, &client, nil),
                "Failed to create midi client.")
    try require(MIDISourceCreate(client, "\(name)" as CFString, &endPoint),
                "Failed to create end point for node.")

    updateSubscriptions()

    
  }

  private func updateSubscriptions()
  {
    subscriptions.store
    {
      transport.$isJogging
        .receive(on: RunLoop.main)
        .assign(to: \.isJogging, on: self)
    }
  }

  /// Sends 'note off' event if needed and disposed of midi resources.
  deinit
  {
    if isPlaying { sendNoteOff() }

    do
    {
      logi("disposing of MIDI client and end point")
      try require(MIDIEndpointDispose(endPoint), "Failed to dispose of end point")
      try require(MIDIClientDispose(client), "Failed to dispose of midi client")
    }
    catch
    {
      loge("\(error as NSObject)")
    }
  }
}
