//
//  MIDINode.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/12/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit
import CoreMIDI
import MIDI

final class MIDINode: SKSpriteNode {

  /// Whether the node is moving along `path`.
  private(set) var isStationary: Bool = false

  /// Whether the node is being jogged by the transport.
  private(set) var isJogging: Bool

  /// Whether the node is slated to be removed.
  private(set) var isPendingRemoval: Bool = false { didSet { isHidden = isPendingRemoval } }

  /// Whether the node has sent a 'note on' event not yet stopped with a 'note off' event.
  private(set) var isPlaying: Bool = false

  /// The node's midi client.
  private var client = MIDIClientRef()

  /// The node's midi endpoint.
  private(set) var endPoint = MIDIEndpointRef()

  /// The bar beat time at which the node begins playing.
  var initTime: BarBeatTime

  /// The speed and direction the node begins with at `initTime`.
  var initialTrajectory: Trajectory

  /// Location pending for the node.
  private(set) var pendingPosition: CGPoint?

  /// The generator used to produce the midi data played each time the node touches a boundary.
  var generator: AnyMIDIGenerator {
    didSet {
      guard generator != oldValue else { return }
      playAction = Action(key: .play, node: self)
    }
  }

  /// Whether a note is ended via a note on event with velocity of 0 or with a note off event
  static let useVelocityForOff = true

  /// The unique identifier for the node that is preserved across file operations.
  let identifier: UUID

  /// Cached 'play' action.
  private lazy var playAction: Action = Action(key: .play, node: self)

  /// Cached 'fade out' action.
  private lazy var fadeOutAction: Action = Action(key: .fadeOut, node: self)

  /// Cached 'fade out and remove' action.
  private lazy var fadeOutAndRemoveAction: Action = Action(key: .fadeOutAndRemove, node: self)

  /// Cached 'fade in' action.
  private lazy var fadeInAction: Action = Action(key: .fadeIn, node: self)

  /// Cached 'move' action.
  private lazy var moveAction: Action = Action(key: .move, node: self)

  /// Updates the node's position from `pendingPosition` when `pendingPosition != nil`.
  func updatePosition() {
    guard let pending = pendingPosition else { return }
    position = pending
    pendingPosition = nil
  }

  /// Causes node to fade out of the scene. If `remove == true` then the node is also removed.
  func fadeOut(remove: Bool = false) { (remove ? fadeOutAndRemoveAction : fadeOutAction).run() }

  /// Causes the node to fade into the scene.
  func fadeIn() { fadeInAction.run() }

  /// Identifier for us in note on/off events.
  private lazy var senderID: UInt = UInt(bitPattern: ObjectIdentifier(self))

  /// Pushes a new 'note on' event through `generator` and sets `isPlaying` to `true`.
  private func sendNoteOn() {

    do {

      try generator.receiveNoteOn(endPoint: endPoint, identifier: senderID)
      isPlaying = true

    } catch {

      loge("\(error)")

    }

  }

  /// Pushes a new 'note off' event through `generator` and sets `isPlaying` to `false`.
  private func sendNoteOff() {

    do {

      try generator.receiveNoteOff(endPoint: endPoint, identifier: senderID)
      isPlaying = false

    } catch {

      loge("\(error)")
      fatalError("Failed to send the 'note off' event through `generator`.")

    }

  }

  /// Overridden to ensure `sendNoteOff` is invoked when the play action is removed.
  override func removeAction(forKey key: String) {
    if action(forKey: key) != nil && Action.Key.play.rawValue == key { sendNoteOff() }
    super.removeAction(forKey: key)
  }

  /// The object responsible for handling the node's midi connections and management.
  /// Setting this property to `nil` will remove it from it's parent node when such a node exists.
  private(set) weak var dispatch: MIDINodeDispatch?  {
    didSet { if dispatch == nil && parent != nil { removeFromParent() } }
  }

  /// Handles notification registration and reception.
  private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

  /// Handler for notifications indicating the node should begin jogging.
  private func didBeginJogging(_ notification: Notification) {

    guard !isJogging else {
      fatalError("Internal inconsistency, should not already have jogging flag set.")
    }

    logi("position: \(position); path: \(path)")

    isJogging = true
    removeAllActions()

  }

  /// Handler for notifications indicating the node has jogged to a new location.
  private func didJog(_ notification: Notification) {

    guard isJogging else { fatalError("Internal inconsistency, should have jogging flag set.") }

    guard let time = notification.jogTime else { fatalError("notification does not contain ticks") }

    logi("time: \(time)")

    switch time {

      case <--initTime where !isPendingRemoval:
        // Time has moved backward past the point of the node's initial start. Hide and flag for removal.

        isPendingRemoval = true

      case initTime|-> where isPendingRemoval:
        // Time has moved back within the bounds of the node's existence from an earlier time. Reveal, 
        // unset the flag for removal, and fall through to update the pending position.

        isPendingRemoval = false
        fallthrough

      case initTime|->:
        // Time has moved forward, update the pending position.

        guard let index = path.segmentIndex(for: time) else { pendingPosition = nil; break }
        pendingPosition = path[index].location(for: time)

      default:
        // Time has moved further backward and node is already hidden and flagged for removal.

        break

    }

  }

  /// Handler for notifications indicating the node has stopped jogging.
  private func didEndJogging(_ notification: Notification) {

    guard isJogging else {
      loge("Internal inconsistency, should have jogging flag set."); return
    }

    isJogging = false

    // Check whether the node should be removed.
    guard !isPendingRemoval else {
      removeFromParent()
      return
    }

    // Check whether the node has been paused.
    guard !isStationary else { return }

    // Update the current segment and resume movement of the node.
    guard let nextSegment = path.segmentIndex(for: Time.current?.barBeatTime ?? .zero) else {
      fatalError("Failed to get the index for the next segment")
    }

    currentSegment = nextSegment

    moveAction.run()

  }

  /// Hander for notifications indicating that the sequencer's transport has begun playback.
  private func didStart(_ notification: Notification) {

    // Check that the node is paused; otherwise, it should already be moving.
    guard isStationary else { return }

    logi("unpausing")

    // Update state and begin moving.
    isStationary = false
    moveAction.run()

  }

  /// Handler for notifications indicating that the sequencer's transport has paused playback.
  private func didPause(_ notification: Notification) {

    // Check that the node is not already paused.
    guard !isStationary else { return }

    logi("pausing")

    // Update state and stop moving.
    isStationary = true
    removeAllActions()

  }

  /// Handler for notifications indicating that the sequencer's transport has reset.
  private func didReset(_ notification: Notification) {

    // Fade out and remove.
    fadeOut(remove: true)

  }

  /// The texture used by all `MIDINode` instances.
  static let texture = SKTexture(image: UIImage(named: "ball")!)

  /// The normal map used by all `MIDINode` instances.
  private static let normalMap = MIDINode.texture.generatingNormalMap()

  /// The size of a node when it has no active notes.
  static let defaultSize: CGSize = MIDINode.texture.size() * 0.75

  /// The size of a node when it has at least one active note.
  static let playingSize: CGSize = MIDINode.texture.size()

  /// Default initializer for creating an instance of `MIDINode`.
  /// - Parameter trajectory: The initial trajectory for the node.
  /// - Parameter name: The unique name for the node.
  /// - Parameter dispatch: The object responsible for the node.
  /// - Parameter identifier: A `UUID` used to uniquely identify this node across application invocations.
  init(trajectory: Trajectory,
       name: String,
       dispatch: MIDINodeDispatch,
       generator: AnyMIDIGenerator,
       identifier: UUID = UUID()) throws
  {

    initTime = Time.current?.barBeatTime ?? .zero
    initialTrajectory = trajectory
    isJogging = Transport.current.isJogging
    self.dispatch = dispatch
    self.generator = generator
    self.identifier = identifier

    // Get the size of the player which is needed for calculating trajectories
    guard let playerSize = MIDINodePlayer.playerNode?.size else {
      fatalError("creating node with nil value for `MIDINodePlayer.playerNode`")
    }

    // Generate the path and grab the initial segment.
    path = Path(trajectory: trajectory, playerSize: playerSize, time: initTime)

    // Invoke `super` now that properties have been initialized.
    super.init(texture: MIDINode.texture, color: dispatch.color.value, size: MIDINode.texture.size() * 0.75)

    // Register receptionist for transport notifications.
    receptionist.observe(name: .didBeginJogging, from: Transport.current,
                         callback: weakCapture(of: self, block:MIDINode.didBeginJogging))
    receptionist.observe(name: .didJog, from: Transport.current,
                         callback: weakCapture(of: self, block:MIDINode.didJog))
    receptionist.observe(name: .didEndJogging, from: Transport.current,
                         callback: weakCapture(of: self, block:MIDINode.didEndJogging))
    receptionist.observe(name: .didStart, from: Transport.current,
                         callback: weakCapture(of: self, block:MIDINode.didStart))
    receptionist.observe(name: .didPause, from: Transport.current,
                         callback: weakCapture(of: self, block:MIDINode.didPause))
    receptionist.observe(name: .didReset, from: Transport.current,
                         callback: weakCapture(of: self, block:MIDINode.didReset))

    // Create midi client and source.
    try MIDIClientCreateWithBlock(name as CFString, &client, nil) ➤ "Failed to create midi client."
    try MIDISourceCreate(client, "\(name)" as CFString, &endPoint) ➤ "Failed to create end point for node."

    // Finish configuring the node.
    self.name = name
    colorBlendFactor = 1
    position = trajectory.position
    normalTexture = MIDINode.normalMap

    // Start the node's movement.
    moveAction.run()

  }

  /// The path controlling the movement of the node.
  let path: Path

  /// The index of the current segment of `path` upon which the node is travelling.
  private var currentSegment: Int = 0

  /// Initializing from a coder is not supported.
  required init?(coder aDecoder: NSCoder) { fatalError("\(#function) has not been implemented") }

  /// Sends 'note off' event if needed and disposed of midi resources.
  deinit {

    if isPlaying { sendNoteOff() }

    do {

      logi("disposing of MIDI client and end point")
      try MIDIEndpointDispose(endPoint) ➤ "Failed to dispose of end point"
      try MIDIClientDispose(client) ➤ "Failed to dispose of midi client"

    } catch {

      loge("\(error)")

    }

  }

  /// Type for representing MIDI-related node actions
  private struct Action {

    /// Enumeration of the available actions.
    enum Key: String {

      /// Move the node along its current segment to that segment's end location, at which point the
      /// node runs `play`, the node's segment is updated and the action is repeated.
      case move

      /// Send the node's 'note on' event, scale up for half the note's duration, scale back down for
      /// half the note's duration and send the node's 'note off' event.
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
    unowned let node: MIDINode

    /// The `SKAction` object generator for the action.
    var action: SKAction {

      switch key {

        case .move:

          // Get the current segment on the path.
          let segment = node.path[node.currentSegment]

          // Get the duration, which is the time it will take to travel the current segment.
          let duration = segment.trajectory.time(from: node.position, to: segment.endLocation)

          // Create the action to move the node to the end of the current segment.
          let move = SKAction.move(to: segment.endLocation, duration: duration)

          // Create the play action.
          let play = node.playAction.action

          // Create the action that updates the current segment and continues movement.
          let updateAndRepeat = SKAction.run {
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
          let halfDuration = node.generator.duration.seconds(withBPM: Sequencer.tempo) * 0.5

          // Scale up to playing size for half the action.
          let scaleUp = SKAction.resize(toWidth: MIDINode.playingSize.width,
                                        height: MIDINode.playingSize.height,
                                        duration: halfDuration)

          // Send the 'note on' event.
          let noteOn = SKAction.run({[unowned node] in node.sendNoteOn() })

          // Scale down to default size for half the action.
          let scaleDown = SKAction.resize(toWidth: MIDINode.defaultSize.width,
                                          height: MIDINode.defaultSize.height,
                                          duration: halfDuration)

          // Send the 'note off' event
          let noteOff = SKAction.run({[unowned node] in node.sendNoteOff() })

          // Group the 'note on' and scale up actions.
          let scaleUpAndNoteOn = SKAction.group([scaleUp, noteOn])

          // Return as a sequence.
          return SKAction.sequence([scaleUpAndNoteOn, scaleDown, noteOff])

        case .fadeOut:

          // Fade the node.
          let fade = SKAction.fadeOut(withDuration: 0.25)

          // Send 'note off' event and pause the node.
          let pause = SKAction.run({[unowned node] in node.sendNoteOff(); node.isPaused = true })

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
          let unpause = SKAction.run({[unowned node] in node.isPaused = false })

          // Return as a sequence
          return SKAction.sequence([fade, unpause])

      }

    }

    /// Runs `action` on `node` keyed by `key.rawValue`
    func run() { node.run(action, withKey: key.rawValue) }

  } // MIDINode.Action

  /// Type for generating consecutive line segments.
  final class Path: CustomStringConvertible, CustomDebugStringConvertible {

    /// Bounding box for the path's segments.
    private let bounds: CGRect

    /// The in-order segments from which the path is composed.
    private var segments: SortedArray<Segment>

    /// Returns the `position` segment in the path.
    subscript(position: Int) -> Segment { return segments[position] }

    /// Time associated with the path's starting end point.
    var startTime: BarBeatTime { return segments[0].startTime }

    /// Velocity and angle specifying the first vector from the path's starting end point.
    var initialTrajectory: Trajectory { return segments[0].trajectory }

    /// The first segment in the path.
    var initialSegment: Segment { return segments[0] }

    /// Default initializer for `Path`.
    /// - Parameter trajectory: The path's initial trajectory.
    /// - Parameter playerSize: The size of the rectangle bounding the path.
    /// - Parameter time: The start time for the path. Default is `BarBeatTime.zero`.
    init(trajectory: Trajectory, playerSize: CGSize, time: BarBeatTime = .zero) {

      // Calculate bounds by insetting a rect with origin zero and a size of `playerSize`.
      bounds = UIEdgeInsets(*(MIDINode.texture.size() * 0.375)).inset(CGRect(size: playerSize))

      // Create the initial segment.
      segments = [Segment(trajectory: trajectory, time: time, bounds: bounds)]
      
    }

    /// Returns the index of the segment with a `timeInterval` that contains `time` unless
    /// `time < startTime`, in which case `nil` is returned. If an existing segment is found 
    /// for `time` it's index will be returned; otherwise, new segments will be created successively
    /// until a segment is created that contains `time` and its index is returned.
    func segmentIndex(for time: BarBeatTime) -> Int? {

      // Check that the time does not predate the path's start time.
      guard time >= startTime else { return nil }

      if let index = segments.firstIndex(where: { $0.timeInterval.contains(time) }) {
        return index
      }

      var segment = segments[segments.index(before: segments.endIndex)]

      guard segment.endTime <= time else {
        fatalError("segment's end time ≰ to time, a matching segment should have been found")
      }

      // Iteratively create segments until one is created whose `timeInterval` contains `time`.
      while !segment.timeInterval.contains(time) {
        segment = advance(segment: segment)
        segments.append(segment)
      }

      guard segment.timeInterval.contains(time) else {
        fatalError("segment to return does not contain time specified")
      }
      
      return segments.index(before: segments.endIndex)

    }

    /// Returns a new segment that continues the path by connecting to the end location of `segment`.
    private func advance(segment: Segment) -> Segment {

      // Redirect trajectory according to which boundary edge the new location touches
      var velocity = segment.trajectory.velocity

      switch segment.endLocation.unpack {

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

      // Create a segment with the new trajectory with a start time equal to `segment.endTime`.
      let nextSegment = Segment(trajectory: nextTrajectory, time: segment.endTime, bounds: bounds)

      return nextSegment

    }

    /// Returns a brief description of the path.
    var description: String {
      return "MIDINode.Path { startTime: \(startTime); segments: \(segments.count) }"
    }

    /// Returns an exhaustive description of the path.
    var debugDescription: String {

      var result = "MIDINode.Path {\n\t"

      result += [
        "bounds: \(bounds)",
        "startTime: \(startTime)",
        "initialTrajectory: \(initialTrajectory)",
        "segments: [\n\t\t"
        ].joined(separator: "\n\t")

      result += segments.map({$0.description.indented(by: 2, preserveFirst: true, useTabs: true)})
        .joined(separator: ",\n\t\t")

      result += "\n\t]\n}"

      return result

    }

    /// A struct representing a line segment within a path.
    struct Segment: Comparable, CustomStringConvertible {

      /// The position, angle and velocity describing the segment.
      let trajectory: Trajectory

      /// The start and stop time of the segment expressed as a bar-beat time interval.
      let timeInterval: Range<BarBeatTime>

      /// The start and stop time of the segment expressed as a tick interval.
      let tickInterval: Range<MIDITimeStamp>

      /// The total elapsed time at the start of the segment.
      var startTime: BarBeatTime { return timeInterval.lowerBound }

      /// The total elapsed time at the end of the segment.
      var endTime: BarBeatTime { return timeInterval.upperBound }

      /// The elapsed time from start to end.
      var totalTime: BarBeatTime { return timeInterval.upperBound - timeInterval.lowerBound }

      /// The total elapsed ticks at the start of the segment.
      var startTicks: MIDITimeStamp { return tickInterval.lowerBound }

      /// The total elapsed ticks at the end of the segment.
      var endTicks: MIDITimeStamp { return tickInterval.upperBound }

      /// The number of elapsed ticks from start to end.
      var totalTicks: MIDITimeStamp { return endTicks > startTicks ? endTicks - startTicks : 0 }

      /// The starting point of the segment.
      var startLocation: CGPoint { return trajectory.position }

      /// The ending point of the segment.
      let endLocation: CGPoint

      /// The length of the segment in points.
      let length: CGFloat

      /// Returns the point along the segment with the associated `time` or `nil`.
      func location(for time: BarBeatTime) -> CGPoint? {

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
      /// - Parameter trajectory: The segment's postion, velocity and angle.
      /// - Parameter time: The total elapsed time at the start of the segment.
      /// - Parameter bounds: The bounding rectangle for the segment.
      init(trajectory: Trajectory, time: BarBeatTime, bounds: CGRect) {

        self.trajectory = trajectory

        // Determine the y value at the end of the segment.
        let endY: CGFloat

        switch trajectory.direction.vertical {

          case .none:
            // No vertical movement so the y value is the same as at the start of the segment.
            endY = trajectory.position.y

          case .up:
            // Moving up so the y value is that of the maximum point.

            endY = bounds.maxY

          case .down:
            // Moving down so the y value is that of the minimum point.

            endY = bounds.minY

        }

        // Calculate the y-projected end location, which will be the segment point where y is `endY`
        // or `nil` if the point lies outside of the bounding box.
        let pY: CGPoint? = {
          let (x, y) = *trajectory.position
          let p = CGPoint(x: (endY - y + trajectory.slope * x) / trajectory.slope, y: endY)
          guard (bounds.minX ... bounds.maxX).contains(p.x) else { return nil }
          return p
        }()

        // Determine the x value at the end of the segment.
        let endX: CGFloat

        switch trajectory.direction.horizontal {

          case .none:
            // No horizontal movement so the x value is the same as at the start of the segment.

            endX = trajectory.position.x

          case .left:
            // Moving left so the x value is that of the minimum point.

            endX = bounds.minX

          case .right:
            // Moving right so the x value is that of the maximum point.

            endX = bounds.maxX
        }

        // Calculate the x-projected end location, which will be the segment point where x is `endX`
        // or `nil` if the point lies outside of the bounding box.
        let pX: CGPoint? = {
          let (x, y) = *trajectory.position
          let p = CGPoint(x: endX, y: trajectory.slope * (endX - x) + y)
          guard (bounds.minY ... bounds.maxY).contains(p.y) else { return nil }
          return p
        }()

        // Determine the value for `endLocation` using the two projected points.
        switch (pY, pX) {

          case (let pY?, let pX?)
            where trajectory.position.distanceTo(pY) < trajectory.position.distanceTo(pX):
            // Neither projection is nil, the y projection is closer so end there.

            endLocation = pY

          case (_, let pX?):
            // The y projection is nil or the x projection is no further away so end at `pX`.
            endLocation = pX

          case (let pY?, _):
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
      static func ==(lhs: Segment, rhs: Segment) -> Bool { return lhs.startTime == rhs.startTime }

      /// For the purpose of ordering, only the times are considered.
      static func <(lhs: Segment, rhs: Segment) -> Bool { return lhs.startTime < rhs.startTime }

      /// Detailed description of the segment's data.
      var description: String {
        return "Segment {\n\t" + "\n\t".join(
          "trajectory: \(trajectory)",
          "endLocation: \(endLocation)",
          "timeInterval: \(timeInterval)",
          "totalTime: \(endTime - startTime)",
          "tickInterval: \(tickInterval)",
          "totalTicks: \(totalTicks)",
          "length: \(length)"
          ) + "\n}"
      }

    } // MIDINode.Path.Segment

  } // MIDINode.Path

  /// Type for expressing velocity and angle from a point.
  struct Trajectory: Hashable, ByteArrayConvertible, LosslessJSONValueConvertible, CustomStringConvertible {

    /// The constant used to adjust the velocity units when calculating times
    static let modifier: Fraction = 1÷1000

    /// The slope of the trajectory (`dy` / `dx`)
    var slope: CGFloat { return velocity.dy / velocity.dx }

    /// The velocity in units along the lines of those used by `SpriteKit`.
    var velocity: CGVector

    /// The initial point
    var position: CGPoint

    /// Initialize with known property values.
    init(velocity: CGVector, position: CGPoint) {
      self.velocity = velocity
      self.position = position
    }

    /// The direction specified by the trajectory
    var direction: Direction {

      get { return Direction(vector: velocity) }

      set {

        guard direction != newValue else { return }

        // Update the vertical component of `velocity`.
        switch (direction.vertical, newValue.vertical) {

          case (.up, .down),
               (.down, .up):
            // Changed direction of vertical movement, flip the sign of `velocity.dy`.

            velocity.dy.negate()

          case (_, .none):
            // No longer moving vertically, set `velocity.dy` to 0.

            velocity.dy = 0

          default:
            // No change to vertical movement.

            break

        }

        // Update the vertical component of `velocity`.
        switch (direction.horizontal, newValue.horizontal) {

          case (.left, .right),
               (.right, .left):
            // Changed direction of horizontal movement, flip the sign of `velocity.dx`.

            velocity.dx.negate()

          case (_, .none):
            // No longer moving horizontally, set `velocity.dx` to 0.

            velocity.dx = 0

          default:
            // No change to horizontal movement.

            break

        }

      }

    }

    /// Returns the trajectory angle value `angle`.
    func withAngle(_ angle: CGFloat) -> Trajectory {
      var result = self
      result.angle = angle
      return result
    }

   /// The angle of the trajectory.
    var angle: CGFloat { get { return velocity.angle } set { velocity.angle = newValue } }

    /// Elapsed time in seconds between the specified points
    func time(from p1: CGPoint, to p2: CGPoint) -> TimeInterval {

      let result = abs(TimeInterval(p1.distanceTo(p2) / slope)) * TimeInterval(Trajectory.modifier)

      guard result.isFinite else { fatalError("Invalid time: \(result)") }

      return result

    }

    /// The 'zero' trajectory.
    static var zero: Trajectory { return Trajectory(velocity: .zero, position: .zero) }

    /// Trajectory value for representing a 'null' or 'invalid' trajectory
    static var null: Trajectory { return Trajectory(velocity: CGVector.zero, position: CGPoint.null) }

    func hash(into hasher: inout Hasher) {
      velocity.dx.hash(into: &hasher)
      velocity.dy.hash(into: &hasher)
      position.x.hash(into: &hasher)
      position.y.hash(into: &hasher)
    }

    /// Returns `true` iff the two trajectories have equal `velocity` and `position` values.
    static func ==(lhs: Trajectory, rhs: Trajectory) -> Bool {
      return lhs.velocity == rhs.velocity && lhs.position == rhs.position
    }

    /// The array of ascii character bytes as described in `init(_ bytes:)`.
    var bytes: [UInt8] {
      return Array("{\(NSCoder.string(for: position)), \(NSCoder.string(for: velocity))}".utf8)
    }

    /// Initializing with an array of bytes. The bytes should decode into ascii character '{', followed by
    /// ascii characters for the string representation of `position`, followed by ascii characters ', ',
    /// followed by the string representation of `velocity`, and ending with ascii character '}'. The string
    /// representations are as returned by `NSStringFromCGPoint` and `NSStringFromCGVector` respectively.
    init(bytes: [UInt8]) {

      let string = String(bytes: bytes)

      let float = "-?[0-9]+(?:\\.[0-9]+)?"
      let value = "\\{\(float), \(float)\\}"

      guard let match = (~/"\\{(\(value)), (\(value))\\}").firstMatch(in: string, anchored: true),
            let positionCapture = match.captures[1],
            let velocityCapture = match.captures[2]
        else
      {
        self = .null
        return
      }

      guard let position = CGPoint(String(positionCapture.substring)),
            let velocity = CGVector(String(velocityCapture.substring))
        else
      {
        self = .null
        return
      }

      self.position = position
      self.velocity = velocity

    }

    /// The json object for the trajectory.
    var jsonValue: JSONValue { return ["position": position, "velocity": velocity] }

    /// Initializing with a json object containing keys 'position' and 'velocity' with appropriate values.
    init?(_ jsonValue: JSONValue?) {

      guard let dict = ObjectJSONValue(jsonValue),
            let position = CGPoint(dict["position"]),
            let velocity = CGVector(dict["velocity"])
        else
      {
        return nil
      }
      
      self.position = position
      self.velocity = velocity

    }

    var description: String { return "{ velocity: \(velocity); position: \(position) }" }

    /// Type for specifiying the direction of a `Trajectory`.
    enum Direction: Equatable, CustomStringConvertible {

      /// Enumeration describing the possible vertical movement of a trajectory.
      enum VerticalMovement: String, Equatable { case none, up, down  }

      /// Enumeration describing the possible horizontal movement of a trajectory.
      enum HorizontalMovement: String, Equatable { case none, left, right }

      case none
      case vertical   (VerticalMovement)
      case horizontal (HorizontalMovement)
      case diagonal   (VerticalMovement, HorizontalMovement)

      /// Initialize with a vector representing the slope of a line segment.
      init(vector: CGVector) {
        switch *vector {
          case (0, 0):       self = .none
          case (0, <--0):    self = .vertical(.down)
          case (0, _):       self = .vertical(.up)
          case (<--0, 0):    self = .horizontal(.left)
          case (_, 0):       self = .horizontal(.right)
          case (<--0, <--0): self = .diagonal(.down, .left)
          case (<--0, _):    self = .diagonal(.up, .left)
          case (_, <--0):    self = .diagonal(.down, .right)
          case (_, _):       self = .diagonal(.up, .right)
        }
      }

      /// Initialize with the end points of a line segment.
      init(start: CGPoint, end: CGPoint) {
        switch (*start, *end) {
          case let ((x1, y1), (x2, y2)) where x1 == x2 && y1 == y2: self = .none
          case let ((x1, y1), (x2, y2)) where x1 == x2 && y1 < y2:  self = .vertical(.up)
          case let ((x1,  _), (x2,  _)) where x1 == x2:             self = .vertical(.down)
          case let ((x1, y1), (x2, y2)) where x1 < x2 && y1 == y2:  self = .horizontal(.right)
          case let (( _, y1), ( _, y2)) where y1 == y2:             self = .horizontal(.left)
          case let ((x1, y1), (x2, y2)) where x1 < x2 && y1 < y2:   self = .diagonal(.up, .right)
          case let ((x1, y1), (x2, y2)) where x1 < x2 && y1 > y2:   self = .diagonal(.down, .right)
          case let (( _, y1), ( _, y2)) where y1 < y2:              self = .diagonal(.up, .left)
          case let (( _, y1), ( _, y2)) where y1 > y2:              self = .diagonal(.down, .left)
          default:                                                  self = .none
        }
      }

      /// The vertical movement in the trajectory.
      var vertical: VerticalMovement {
        get {
          switch self {
            case .vertical(let movement):    return movement
            case .diagonal(let movement, _): return movement
            default:                         return .none
          }
        }
        set {
          guard vertical != newValue else { return }
          switch self {
            case .horizontal(let horizontal):  self = .diagonal(newValue, horizontal)
            case .vertical(_):                 self = .vertical(newValue)
            case .diagonal(_, let horizontal): self = .diagonal(newValue, horizontal)
            case .none:                        self = .vertical(newValue)
          }
        }
      }

      /// The horizontal movement in the trajectory.
      var horizontal: HorizontalMovement {
        get {
          switch self {
            case .horizontal(let movement):  return movement
            case .diagonal(_, let movement): return movement
            default:                         return .none
          }
        }
        set {
          guard horizontal != newValue else { return }
          switch self {
            case .vertical(let vertical):    self = .diagonal(vertical, newValue)
            case .horizontal(_):             self = .horizontal(newValue)
            case .diagonal(let vertical, _): self = .diagonal(vertical, newValue)
            case .none:                      self = .horizontal(newValue)
          }
        }
      }

      /// The direction generated by reversing the vertical and horizontal movement.
      var reversed: Direction {
        switch self {
          case .vertical(.up):           return .vertical(.down)
          case .vertical(.down):         return .vertical(.up)
          case .horizontal(.left):       return .horizontal(.right)
          case .horizontal(.right):      return .horizontal(.left)
          case .diagonal(.up, .left):    return .diagonal(.down, .right)
          case .diagonal(.down, .left):  return .diagonal(.up, .right)
          case .diagonal(.up, .right):   return .diagonal(.down, .left)
          case .diagonal(.down, .right): return .diagonal(.up, .left)
          default:                       return .none
        }
      }

      var description: String {
        switch self {
          case .vertical(let v):        return v.rawValue
          case .horizontal(let h):      return h.rawValue
          case .diagonal(let v, let h): return "\(v.rawValue)-\(h.rawValue)"
          case .none:                   return "none"
        }
      }

      /// Returns true iff the vertical and horizontal movement of `lhs` are equal to those of `rhs`.
      static func ==(lhs: Direction, rhs: Direction) -> Bool {
        return lhs.vertical == rhs.vertical && lhs.horizontal == rhs.horizontal
      }

    } // MIDINode.Trajectory.Direction

  } // MIDINode.Trajectory

}
