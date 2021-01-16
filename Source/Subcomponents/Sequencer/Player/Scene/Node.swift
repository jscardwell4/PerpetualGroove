//
//  Node.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/12/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Combine
import CoreMIDI
import MIDI
import MoonDev
import SpriteKit
import UIKit

// MARK: - Node

public final class Node: SKSpriteNode
{
  public typealias Trajectory = NodeEvent.Trajectory

  /// Whether the node is moving along `path`.
  public private(set) var stationary: Bool = false

  /// Whether the node is being jogged by the transport.
  public private(set) var jogging: Bool

  /// Whether the node is slated to be removed.
  public private(set) var pendingRemoval: Bool = false
  {
    didSet { isHidden = pendingRemoval }
  }

  /// Whether the node has sent a 'note on' event not yet stopped with a 'note off' event.
  public private(set) var playing: Bool = false

  /// The node's midi client.
  private var client = MIDIClientRef()

  /// The node's midi endpoint.
  public private(set) var endPoint = MIDIEndpointRef()

  /// The bar beat time at which the node begins playing.
  public var initTime: BarBeatTime

  /// The speed and direction the node begins with at `initTime`.
  public var initialTrajectory: Trajectory

  /// Location pending for the node.
  public private(set) var pendingPosition: CGPoint?

  /// The generator used to produce the midi data played each time the node
  /// touches a boundary.
  public var generator: AnyGenerator
  {
    didSet
    {
      guard generator != oldValue else { return }
      playAction = Action(key: .play, node: self)
    }
  }

  /// Whether a note is ended via a note on event with velocity of 0 or note off event.
  public static let useVelocityForOff = true

  /// The unique identifier for the node that is preserved across file operations.
  public let identifier: UUID

  /// Cached 'play' action.
  private lazy var playAction = Action(key: .play, node: self)

  /// Cached 'fade out' action.
  private lazy var fadeOutAction = Action(key: .fadeOut, node: self)

  /// Cached 'fade out and remove' action.
  private lazy var fadeOutAndRemoveAction = Action(key: .fadeOutAndRemove, node: self)

  /// Cached 'fade in' action.
  private lazy var fadeInAction = Action(key: .fadeIn, node: self)

  /// Cached 'move' action.
  private lazy var moveAction = Action(key: .move, node: self)

  /// Updates the node's position from `pendingPosition` when `pendingPosition != nil`.
  public func updatePosition()
  {
    guard let pending = pendingPosition else { return }
    position = pending
    pendingPosition = nil
  }

  /// Causes node to fade out of the scene. If `remove == true` then the node
  /// is also removed.
  public func fadeOut(remove: Bool = false)
  {
    (remove ? fadeOutAndRemoveAction : fadeOutAction).run()
  }

  /// Causes the node to fade into the scene.
  public func fadeIn() { fadeInAction.run() }

  /// Identifier for use in note on/off events.
  private lazy var senderID = UInt(bitPattern: ObjectIdentifier(self))

  /// Pushes a new 'note on' event through `generator` and sets `isPlaying` to `true`.
  private func sendNoteOn()
  {
    do
    {
      try generator.receiveNoteOn(endPoint: endPoint,
                                  identifier: senderID,
                                  ticks: time.ticks)
      playing = true
    }
    catch
    {
      loge("\(error as NSObject)")
    }
  }

  /// Pushes a new 'note off' event through `generator` and sets `isPlaying` to `false`.
  private func sendNoteOff()
  {
    do
    {
      try generator.receiveNoteOff(endPoint: endPoint,
                                   identifier: senderID,
                                   ticks: time.ticks)
      playing = false
    }
    catch
    {
      loge("\(error as NSObject)")
      fatalError("Failed to send the 'note off' event through `generator`.")
    }
  }

  /// Overridden to ensure `sendNoteOff` is invoked when the play action is removed.
  override public func removeAction(forKey key: String)
  {
    if action(forKey: key) != nil, Action.Key.play.rawValue == key { sendNoteOff() }
    super.removeAction(forKey: key)
  }

  /// The object responsible for handling the node's midi connections and management.
  /// Setting this property to `nil` will remove it from it's parent node when such
  /// a node exists.
  private(set) weak var dispatch: NodeDispatch?
  {
    didSet { if dispatch == nil, parent != nil { removeFromParent() } }
  }

  /// Handler for notifications indicating the node should begin jogging.
  private func didBeginJogging(notification: Notification)
  {
    precondition(!jogging)

    logi("position: \(self.position); path: \(self.path)")

    jogging = true
    removeAllActions()
  }

  /// Handler for notifications indicating the node has jogged to a new location.
  private func didJog(notification: Notification)
  {
    precondition(jogging)

    guard let time = notification.jogTime
    else
    {
      fatalError("notification does not contain ticks")
    }

    logi("time: \(time)")

    switch time
    {
      case <--initTime where !pendingRemoval:
        // Time has moved backward past the point of the node's initial start.
        // Hide and flag for removal.

        pendingRemoval = true

      case initTime|-> where pendingRemoval:
        // Time has moved back within the bounds of the node's existence from an
        // earlier time. Reveal, unset the flag for removal, and fall through to
        // update the pending position.

        pendingRemoval = false
        fallthrough

      case initTime|->:
        // Time has moved forward, update the pending position.

        guard let index = path.segmentIndex(for: time)
        else
        {
          pendingPosition = nil
          break
        }

        pendingPosition = path[index].location(for: time)

      default:
        // Time has moved further backward and node is already hidden and flagged
        // for removal.

        break
    }
  }

  /// Handler for notifications indicating the node has stopped jogging.
  private func didEndJogging(notification: Notification)
  {
    guard jogging
    else
    {
      logw("Internal inconsistency, should have jogging flag set."); return
    }

    jogging = false

    // Check whether the node should be removed.
    guard !pendingRemoval
    else
    {
      removeFromParent()
      return
    }

    // Check whether the node has been paused.
    guard !stationary else { return }

    // Update the current segment and resume movement of the node.
    guard let nextSegment = path.segmentIndex(for: time.barBeatTime)
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
    guard stationary else { return }

    // Update state and begin moving.
    stationary = false
    moveAction.run()
  }

  /// Handler for notifications indicating that the sequencer's transport has paused.
  private func didPause(notification: Notification)
  {
    // Check that the node is not already paused.
    guard !stationary else { return }

    // Update state and stop moving.
    stationary = true
    removeAllActions()
  }

  /// Handler for notifications indicating that the sequencer's transport has reset.
  private func didReset(notification: Notification) { fadeOut(remove: true) }

  /// The texture used by all `Node` instances.
  public static let texture = SKTexture(image: UIImage(named: "ball")!)

  /// The normal map used by all `Node` instances.
  private static let normalMap = Node.texture.generatingNormalMap()

  /// The size of a node when it has no active notes.
  public static let defaultSize: CGSize = Node.texture.size() * 0.75

  /// The size of a node when it has at least one active note.
  public static let playingSize: CGSize = Node.texture.size()

  /// Subscription for `.transportDidBeginJogging` notifications.
  private var transportDidBeginJoggingSubscription: Cancellable?

  /// Subscription for `.transportDidJog` notifications.
  private var transportDidJogSubscription: Cancellable?

  /// Subscription for `.transportDidEndJogging` notifications.
  private var transportDidEndJoggingSubscription: Cancellable?

  /// Subscription for `.transportDidStart` notifications.
  private var transportDidStartSubscription: Cancellable?

  /// Subscription for `.transportDidPause` notifications.
  private var transportDidPauseSubscription: Cancellable?

  /// Subscription for `.transportDidReset` notifications.
  private var transportDidResetSubscription: Cancellable?

  /// Default initializer for creating an instance of `Node`.
  ///
  /// - Parameters:
  ///   - trajectory: The initial trajectory for the node.
  ///   - name: The unique name for the node.
  ///   - dispatch: The object responsible for the node.
  ///   - identifier: A `UUID` used to uniquely identify this node across invocations.
  public init(trajectory: Trajectory,
              name: String,
              dispatch: NodeDispatch,
              generator: AnyGenerator,
              identifier: UUID = UUID()) throws
  {
    initTime = time.barBeatTime
    initialTrajectory = trajectory
    jogging = sequencer.transport.jogging

    self.dispatch = dispatch
    self.generator = generator
    self.identifier = identifier

    // Get the size of the player which is needed for calculating trajectories
    guard let playerSize = player.playerNode?.size
    else
    {
      fatalError("creating node with nil value for `player.playerNode`")
    }

    // Generate the path and grab the initial segment.
    path = Path(trajectory: trajectory, playerSize: playerSize, time: initTime)

    // Invoke `super` now that properties have been initialized.
    super.init(texture: Node.texture,
               color: dispatch.color.value,
               size: Node.texture.size() * 0.75)

    // Subscribe to transport notifications from the currently assigned transport.
    transportDidBeginJoggingSubscription = NotificationCenter.default
      .publisher(for: .transportDidBeginJogging, object: sequencer.transport)
      .sink { self.didBeginJogging(notification: $0) }

    transportDidJogSubscription = NotificationCenter.default
      .publisher(for: .transportDidJog, object: sequencer.transport)
      .sink { self.didJog(notification: $0) }

    transportDidEndJoggingSubscription = NotificationCenter.default
      .publisher(for: .transportDidEndJogging, object: sequencer.transport)
      .sink { self.didEndJogging(notification: $0) }

    transportDidStartSubscription = NotificationCenter.default
      .publisher(for: .transportDidStart, object: sequencer.transport)
      .sink { self.didStart(notification: $0) }

    transportDidPauseSubscription = NotificationCenter.default
      .publisher(for: .transportDidPause, object: sequencer.transport)
      .sink { self.didPause(notification: $0) }

    transportDidResetSubscription = NotificationCenter.default
      .publisher(for: .transportDidReset, object: sequencer.transport)
      .sink { self.didReset(notification: $0) }

    // Create midi client and source.
    try require(MIDIClientCreateWithBlock(name as CFString, &client, nil),
                "Failed to create midi client.")
    try require(MIDISourceCreate(client, "\(name)" as CFString, &endPoint),
                "Failed to create end point for node.")

    // Finish configuring the node.
    self.name = name
    colorBlendFactor = 1
    position = trajectory.position
    normalTexture = Node.normalMap

    // Start the node's movement.
    moveAction.run()
  }

  /// The path controlling the movement of the node.
  public let path: Path

  /// The index of the current segment of `path` upon which the node is travelling.
  private var currentSegment: Int = 0

  /// Initializing from a coder is not supported.
  @available(*, unavailable) public required init?(coder _: NSCoder)
  {
    fatalError("\(#function) has not been implemented")
  }

  /// Sends 'note off' event if needed and disposed of midi resources.
  deinit
  {
    if playing { sendNoteOff() }

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

extension Node
{
  /// Type for representing MIDI-related node actions
  private struct Action
  {
    /// Enumeration of the available actions.
    enum Key: String
    {
      /// Move the node along its current segment to that segment's end location,
      /// at which point the node runs `play`, the node's segment is updated and
      /// the action is repeated.
      case move

      /// Send the node's 'note on' event, scale up for half the note's duration,
      /// scale back down for half the note's duration and send the node's
      /// 'note off' event.
      case play

      /// Fade out the node.
      case fadeOut

      /// Fade out the node and remove it from it's parent node.
      case fadeOutAndRemove

      /// Fade in the node.
      case fadeIn
    }

    /// Specifies what kind of action is run.
    let key: Key

    /// The node upon which the action runs.
    unowned let node: Node

    /// The `SKAction` object generator for the action.
    var action: SKAction
    {
      switch key
      {
        case .move:

          // Get the current segment on the path.
          let segment = node.path[node.currentSegment]

          // Get the duration, which is the time it will take to travel the
          // current segment.
          let duration = segment.trajectory.time(from: node.position,
                                                 to: segment.endLocation)

          // Create the action to move the node to the end of the current segment.
          let move = SKAction.move(to: segment.endLocation, duration: duration)

          // Create the play action.
          let play = node.playAction.action

          // Create the action that updates the current segment and continues movement.
          let updateAndRepeat = SKAction.run
          {
            [unowned node] in

            node.currentSegment = node.currentSegment &+ 1
            node.moveAction.run()
          }

          // Group actions to play and repeat.
          let playUpdateAndRepeat = SKAction.group([play, updateAndRepeat])

          // Return as a sequence.
          return SKAction.sequence([move, playUpdateAndRepeat])

        case .play:

          // Calculate half of the action's duration.
          let halfDuration = node.generator.duration
            .seconds(withBPM: sequencer.tempo) * 0.5

          // Scale up to playing size for half the action.
          let scaleUp = SKAction.resize(toWidth: Node.playingSize.width,
                                        height: Node.playingSize.height,
                                        duration: halfDuration)

          // Send the 'note on' event.
          let noteOn = SKAction.run { [unowned node] in node.sendNoteOn() }

          // Scale down to default size for half the action.
          let scaleDown = SKAction.resize(toWidth: Node.defaultSize.width,
                                          height: Node.defaultSize.height,
                                          duration: halfDuration)

          // Send the 'note off' event
          let noteOff = SKAction.run { [unowned node] in node.sendNoteOff() }

          // Group the 'note on' and scale up actions.
          let scaleUpAndNoteOn = SKAction.group([scaleUp, noteOn])

          // Return as a sequence.
          return SKAction.sequence([scaleUpAndNoteOn, scaleDown, noteOff])

        case .fadeOut:

          // Fade the node.
          let fade = SKAction.fadeOut(withDuration: 0.25)

          // Send 'note off' event and pause the node.
          let pause = SKAction.run
          {
            [unowned node] in node.sendNoteOff(); node.isPaused = true
          }

          // Return as a sequence.
          return SKAction.sequence([fade, pause])

        case .fadeOutAndRemove:

          // Fade the node.
          let fade = SKAction.fadeOut(withDuration: 0.25)

          // Remove the node from it's parent.
          let remove = SKAction.removeFromParent()

          // Return as a sequence.
          return SKAction.sequence([fade, remove])

        case .fadeIn:

          // Fade the node.
          let fade = SKAction.fadeIn(withDuration: 0.25)

          // Unpause the node.
          let unpause = SKAction.run { [unowned node] in node.isPaused = false }

          // Return as a sequence
          return SKAction.sequence([fade, unpause])
      }
    }

    /// Runs `action` on `node` keyed by `key.rawValue`
    func run() { node.run(action, withKey: key.rawValue) }
  }
}

public extension Node
{
  /// Type for generating consecutive line segments.
  final class Path: CustomStringConvertible, CustomDebugStringConvertible
  {
    /// Bounding box for the path's segments.
    private let bounds: CGRect

    /// The in-order segments from which the path is composed.
    private var segments: SortedArray<Segment>

    /// Returns the `position` segment in the path.
    public subscript(position: Int) -> Segment { return segments[position] }

    /// Time associated with the path's starting end point.
    public var startTime: BarBeatTime { return segments[0].startTime }

    /// Velocity and angle specifying the first vector from the path's starting end point.
    public var initialTrajectory: Trajectory { return segments[0].trajectory }

    /// The first segment in the path.
    public var initialSegment: Segment { return segments[0] }

    /// Default initializer for `Path`.
    /// - Parameter trajectory: The path's initial trajectory.
    /// - Parameter playerSize: The size of the rectangle bounding the path.
    /// - Parameter time: The start time for the path. Default is `BarBeatTime.zero`.
    public init(trajectory: Trajectory, playerSize: CGSize, time: BarBeatTime = .zero)
    {
      // Calculate bounds by insetting a rect with origin zero and a size of `playerSize`.
      bounds = UIEdgeInsets(*(Node.texture.size() * 0.375))
        .inset(CGRect(size: playerSize))

      // Create the initial segment.
      segments = [Segment(trajectory: trajectory, time: time, bounds: bounds)]
    }

    /// Returns the index of the segment with a `timeInterval` that contains `time`
    /// unless `time < startTime`, in which case `nil` is returned. If an existing
    /// segment is found for `time` it's index will be returned; otherwise, new
    /// segments will be created successively until a segment is created that contains
    /// `time` and its index is returned.
    public func segmentIndex(for time: BarBeatTime) -> Int?
    {
      // Check that the time does not predate the path's start time.
      guard time >= startTime else { return nil }

      if let index = segments.firstIndex(where: { $0.timeInterval.contains(time) })
      {
        return index
      }

      var segment = segments[segments.index(before: segments.endIndex)]

      guard segment.endTime <= time
      else
      {
        fatalError("segment's end time ≰ to time but matching segment not found")
      }

      // Iteratively create segments until one is created whose `timeInterval`
      // contains `time`.
      while !segment.timeInterval.contains(time)
      {
        segment = advance(segment: segment)
        segments.append(segment)
      }

      guard segment.timeInterval.contains(time)
      else
      {
        fatalError("segment to return does not contain time specified")
      }

      return segments.index(before: segments.endIndex)
    }

    /// Returns a new segment that continues the path by connecting to the end
    /// location of `segment`.
    private func advance(segment: Segment) -> Segment
    {
      // Redirect trajectory according to which boundary edge the new location touches
      var velocity = segment.trajectory.velocity

      switch segment.endLocation.unpack
      {
        case (bounds.minX, _),
             (bounds.maxX, _):
          // Touched a horizontal boundary.

          velocity.dx = -velocity.dx

        case (_, bounds.minY),
             (_, bounds.maxY):
          // Touched a vertical boundary.

          velocity.dy = -velocity.dy

        default:
          fatalError("next location should contact an edge of the player")
      }

      // Create a trajectory with the calculated vector rooted at `segment.endLocation`.
      let nextTrajectory = Trajectory(velocity: velocity, position: segment.endLocation)

      // Create a segment with the new trajectory with a start time equal to
      // `segment.endTime`.
      let nextSegment = Segment(trajectory: nextTrajectory,
                                time: segment.endTime,
                                bounds: bounds)

      return nextSegment
    }

    /// Returns a brief description of the path.
    public var description: String
    {
      "Node.Path { startTime: \(startTime); segments: \(segments.count) }"
    }

    /// Returns an exhaustive description of the path.
    public var debugDescription: String
    {
      var result = "Node.Path {\n\t"

      result += [
        "bounds: \(bounds)",
        "startTime: \(startTime)",
        "initialTrajectory: \(initialTrajectory)",
        "segments: [\n\t\t",
      ].joined(separator: "\n\t")

      result += segments.map { $0.description.indented(by: 2,
                                                       preserveFirst: true,
                                                       useTabs: true) }
        .joined(separator: ",\n\t\t")

      result += "\n\t]\n}"

      return result
    }
  }
}

public extension Node.Path
{
  /// A struct representing a line segment within a path.
  struct Segment: Comparable, CustomStringConvertible
  {
    /// The position, angle and velocity describing the segment.
    public let trajectory: Node.Trajectory

    /// The start and stop time of the segment expressed as a bar-beat time interval.
    public let timeInterval: Range<BarBeatTime>

    /// The start and stop time of the segment expressed as a tick interval.
    public let tickInterval: Range<MIDITimeStamp>

    /// The total elapsed time at the start of the segment.
    public var startTime: BarBeatTime { timeInterval.lowerBound }

    /// The total elapsed time at the end of the segment.
    public var endTime: BarBeatTime { timeInterval.upperBound }

    /// The elapsed time from start to end.
    public var totalTime: BarBeatTime { timeInterval.upperBound - timeInterval.lowerBound }

    /// The total elapsed ticks at the start of the segment.
    public var startTicks: MIDITimeStamp { tickInterval.lowerBound }

    /// The total elapsed ticks at the end of the segment.
    public var endTicks: MIDITimeStamp { tickInterval.upperBound }

    /// The number of elapsed ticks from start to end.
    public var totalTicks: MIDITimeStamp
    {
      endTicks > startTicks ? endTicks - startTicks : 0
    }

    /// The starting point of the segment.
    public var startLocation: CGPoint { trajectory.position }

    /// The ending point of the segment.
    public let endLocation: CGPoint

    /// The length of the segment in points.
    public let length: CGFloat

    /// Returns the point along the segment with the associated `time` or `nil`.
    public func location(for time: BarBeatTime) -> CGPoint?
    {
      // Check that the segment has a location for `time`.
      guard timeInterval.contains(time) else { return nil }

      // Calculate the total ticks from start to `time`.
      let 𝝙ticks = CGFloat(time.ticks - startTime.ticks)

      // Calculate what fraction of the total ticks from start to end `𝝙ticks` represents.
      let ratio = 𝝙ticks / CGFloat(tickInterval.count)

      // Calculate the change in x and y from start to end
      let (𝝙x, 𝝙y) = *(endLocation - startLocation)

      // Start with the segment's starting position
      var result = startLocation

      // Add the fractional x and y values
      result.x += ratio * 𝝙x
      result.y += ratio * 𝝙y

      return result
    }

    /// Default initializer for a new segment.
    ///
    /// - Parameter trajectory: The segment's postion, velocity and angle.
    /// - Parameter time: The total elapsed time at the start of the segment.
    /// - Parameter bounds: The bounding rectangle for the segment.
    public init(trajectory: Node.Trajectory, time: BarBeatTime, bounds: CGRect)
    {
      self.trajectory = trajectory

      // Determine the y value at the end of the segment.
      let endY: CGFloat

      switch trajectory.direction.vertical
      {
        case .none:
          // No vertical movement so the y value is the same as at the start of
          // the segment.
          endY = trajectory.position.y

        case .up:
          // Moving up so the y value is that of the maximum point.

          endY = bounds.maxY

        case .down:
          // Moving down so the y value is that of the minimum point.

          endY = bounds.minY
      }

      // Calculate the y-projected end location, which will be the segment point
      // where y is `endY` or `nil` if the point lies outside of the bounding box.
      let pY: CGPoint? = {
        let (x, y) = *trajectory.position
        let p = CGPoint(x: (endY - y + trajectory.slope * x) / trajectory.slope, y: endY)
        guard (bounds.minX ... bounds.maxX).contains(p.x) else { return nil }
        return p
      }()

      // Determine the x value at the end of the segment.
      let endX: CGFloat

      switch trajectory.direction.horizontal
      {
        case .none:
          // No horizontal movement so the x value is the same as at the start of
          // the segment.

          endX = trajectory.position.x

        case .left:
          // Moving left so the x value is that of the minimum point.

          endX = bounds.minX

        case .right:
          // Moving right so the x value is that of the maximum point.

          endX = bounds.maxX
      }

      // Calculate the x-projected end location, which will be the segment point
      // where x is `endX` or `nil` if the point lies outside of the bounding box.
      let pX: CGPoint? = {
        let (x, y) = *trajectory.position
        let p = CGPoint(x: endX, y: trajectory.slope * (endX - x) + y)
        guard (bounds.minY ... bounds.maxY).contains(p.y) else { return nil }
        return p
      }()

      // Determine the value for `endLocation` using the two projected points.
      switch (pY, pX)
      {
        case let (pY?, pX?)
              where trajectory.position.distanceTo(pY) < trajectory.position.distanceTo(pX):
          // Neither projection is nil, the y projection is closer so end there.

          endLocation = pY

        case let (_, pX?):
          // The y projection is nil or the x projection is no further away so end
          // at `pX`.
          endLocation = pX

        case let (pY?, _):
          // The x projection is nil so end at `pY`.
          endLocation = pY

        default:
          fatalError("at least one of projected end points should be valid")
      }

      // Calculate the length of the segment in points.
      length = trajectory.position.distanceTo(endLocation)

      // Calculate the change in time from start to end in seconds.
      let 𝝙t = trajectory.time(from: trajectory.position, to: endLocation)

      // Set the time and tick intervals.
      let lowerBound = time
      let upperBound = BarBeatTime(seconds: time.seconds + 𝝙t)
      assert(lowerBound <= upperBound)

      timeInterval = lowerBound ..< upperBound
      tickInterval = timeInterval.lowerBound.ticks ..< timeInterval.upperBound.ticks
    }

    /// For the purpose of ordering, only the times are considered.
    public static func == (lhs: Segment, rhs: Segment) -> Bool
    {
      lhs.startTime == rhs.startTime
    }

    /// For the purpose of ordering, only the times are considered.
    public static func < (lhs: Segment, rhs: Segment) -> Bool
    {
      lhs.startTime < rhs.startTime
    }

    /// Detailed description of the segment's data.
    public var description: String
    {
      """
      Segment {
        trajectory: \(trajectory)
        endLocation: \(endLocation)
        timeInterval: \(timeInterval)
        totalTime: \(endTime - startTime)
        tickInterval: \(tickInterval)
        totalTicks: \(totalTicks)
        length: \(length)
      }
      """
    }
  }
}
