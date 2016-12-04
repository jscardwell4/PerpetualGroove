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

final class MIDINode: SKSpriteNode {

  /// Holds the current state of the node
  fileprivate var state: State = []

  // MARK: Generating MIDI note events

  private var client = MIDIClientRef()
  private(set) var endPoint = MIDIEndpointRef()

  var initTime: BarBeatTime
  var initialTrajectory: Trajectory

  private(set) var pendingPosition: CGPoint?

  var generator: AnyMIDIGenerator {
    didSet {
      guard generator != oldValue else { return }
      playAction = Action(key: .Play, node: self)
    }
  }

  /// Whether a note is ended via a note on event with velocity of 0 or with a  note off event
  static let useVelocityForOff = true

  let identifier: UUID

  fileprivate lazy var playAction:             Action = self.action(.Play)
  fileprivate lazy var horizontalPlayAction:   Action = self.action(.HorizontalPlay)
  fileprivate lazy var verticalPlayAction:     Action = self.action(.VerticalPlay)
  fileprivate lazy var fadeOutAction:          Action = self.action(.FadeOut)
  fileprivate lazy var fadeOutAndRemoveAction: Action = self.action(.FadeOutAndRemove)
  fileprivate lazy var fadeInAction:           Action = self.action(.FadeIn)
  fileprivate lazy var moveAction:             Action = self.action(.Move)

  fileprivate func action(_ key: Action.Key) -> Action { return Action(key: key, node: self) }

  func play() { playAction.run()  }

  func updatePosition() {
    guard let position = pendingPosition else { return }
    self.position = position
    pendingPosition = nil
  }

  func fadeOut(remove: Bool = false) { (remove ? fadeOutAndRemoveAction : fadeOutAction).run() }

  func fadeIn() { fadeInAction.run() }

  func sendNoteOn() {
    do {
      try generator.receiveNoteOn(endPoint: endPoint,
                                  identifier: UInt64(UInt(bitPattern: ObjectIdentifier(self))))
      state.formSymmetricDifference(.Playing)
    } catch { Log.error(error) }
  }

  func sendNoteOff() {
    guard state ∋ .Playing else { return }
    do {
      try generator.receiveNoteOff(endPoint: endPoint,
                                   identifier: UInt64(UInt(bitPattern: ObjectIdentifier(self))))
      state.formSymmetricDifference(.Playing)
    } catch { Log.error(error) }
  }

  private func removeAction(_ action: Action) { removeAction(forKey: action.key.key) }

  override func removeAction(forKey key: String) {
    switch key {
      case Action.Key.Play.rawValue where self.action(forKey: key) != nil:
        sendNoteOff()
      default: break
    }
    super.removeAction(forKey: key)
  }

  fileprivate func didMove() {
    play()
    currentSegment = currentSegment.successor
    moveAction.run()
  }

  private(set) weak var dispatch: MIDINodeDispatch?  {
    didSet { if dispatch == nil && parent != nil { removeFromParent() } }
  }

  // MARK: Listening for Sequencer notifications

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.SceneContext
    return receptionist
  }()

  private func didBeginJogging(_ notification: Notification) {
    guard state ∌ .Jogging else {
      fatalError("internal inconsistency, should not already have `Jogging` flag set")
    }
    Log.debug("position: \(position); path: \(path)")
    state.formSymmetricDifference(.Jogging)
    self.removeAction(forKey: Action.Key.Move.rawValue)
  }

  private func didJog(_ notification: Notification) {
    guard state ∋ .Jogging else { fatalError("internal inconsistency, should have `Jogging` flag set") }

    guard let time = notification.jogTime else { fatalError("notification does not contain ticks") }

    Log.debug("time: \(time)")

    if time < initTime && state ∌ .PendingRemoval {
      state.formUnion(.PendingRemoval)
      isHidden = true
    } else if time >= initTime {
      if  state ∋ .PendingRemoval { state.remove(.PendingRemoval); isHidden = false }
      pendingPosition = path.location(for: time)
    }
  }

  private func didEndJogging(_ notification: Notification) {
    guard state ∋ .Jogging else {
      Log.error("internal inconsistency, should have `Jogging` flag set"); return
    }
    state.formSymmetricDifference(.Jogging)
    guard state ∌ .PendingRemoval else { removeFromParent(); return }
    guard state ∌ .Paused else { return }
    currentSegment = path.segment(for: Sequencer.time.barBeatTime) ?? path.initialSegment
    moveAction.run()
  }

  private func didStart(_ notification: Notification) {
    guard state ∋ .Paused else { return }
    Log.debug("unpausing")
    state.formSymmetricDifference(.Paused)
    moveAction.run()
  }

  private func didPause(_ notification: Notification) {
    guard state ∌ .Paused else { return }
    Log.debug("pausing")
    state.formSymmetricDifference(.Paused)
    self.removeAction(forKey: Action.Key.Move.rawValue)
  }

  private func didReset(_ notification: Notification) {
    fadeOut(remove: true)
  }

  // MARK: Initialization

  static let texture = SKTexture(image: UIImage(named: "ball")!)
  fileprivate static let normalMap = MIDINode.texture.generatingNormalMap()

  static let defaultSize: CGSize = MIDINode.texture.size() * 0.75
  static let playingSize: CGSize = MIDINode.texture.size()

  init(trajectory: Trajectory,
       name: String,
       dispatch: MIDINodeDispatch,
       generator: AnyMIDIGenerator,
       identifier: UUID = UUID()) throws
  {
    initTime = Sequencer.time.barBeatTime
    initialTrajectory = trajectory
    state = Sequencer.jogging ? [.Jogging] : []
    self.dispatch = dispatch
    self.generator = generator
    self.identifier = identifier

    guard let playerSize = MIDINodePlayer.playerNode?.size else {
      fatalError("creating node with nil value for `MIDINodePlayer.playerNode`")
    }
    path = Path(trajectory: trajectory, playerSize: playerSize, time: Sequencer.transport.time.barBeatTime)
    currentSegment = path.initialSegment

    super.init(texture: MIDINode.texture,
               color: dispatch.color.value,
               size: MIDINode.texture.size() * 0.75)

    let transport = Sequencer.transport

    receptionist.observe(name: .didBeginJogging, from: transport,
                         callback: weakMethod(self, MIDINode.didBeginJogging))
    receptionist.observe(name: .didJog, from: transport,
                         callback: weakMethod(self, MIDINode.didJog))
    receptionist.observe(name: .didEndJogging, from: transport,
                         callback: weakMethod(self, MIDINode.didEndJogging))
    receptionist.observe(name: .didStart, from: transport,
                         callback: weakMethod(self, MIDINode.didStart))
    receptionist.observe(name: .didPause, from: transport,
                         callback: weakMethod(self, MIDINode.didPause))
    receptionist.observe(name: .didReset, from: transport,
                         callback: weakMethod(self, MIDINode.didReset))

    try MIDIClientCreateWithBlock(name as CFString, &client, nil) ➤ "Failed to create midi client"
    try MIDISourceCreate(client, "\(name)" as CFString, &endPoint) ➤ "Failed to create end point for node \(name)"

    self.name = name
    colorBlendFactor = 1
    position = trajectory.p
    normalTexture = MIDINode.normalMap
    moveAction.run()
  }


  let path: Path
  fileprivate var currentSegment: Path.Segment

  required init?(coder aDecoder: NSCoder) { fatalError("\(#function) has not been implemented") }
  
  deinit {
    if state ∋ .Playing { sendNoteOff() }
    do {
      Log.debug("disposing of MIDI client and end point")
      try MIDIEndpointDispose(endPoint) ➤ "Failed to dispose of end point"
      try MIDIClientDispose(client) ➤ "Failed to dispose of midi client"
    } catch { Log.error(error) }
  }

  private var minMaxValues: (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat)? {
    guard let playerSize = MIDINodePlayer.playerNode?.frame.size else { return nil }
    let offset = MIDINode.texture.size() * 0.375
    let (maxX, maxY) = (playerSize - offset).unpack
    let (minX, minY) = offset.unpack
    return (minX, maxX, minY, maxY)
  }

}

// MARK: State
extension MIDINode {

  struct State: OptionSet {
    let rawValue: Int
    static let Playing        = State(rawValue: 0b0001)
    static let Jogging        = State(rawValue: 0b0010)
    static let Paused         = State(rawValue: 0b0100)
    static let PendingRemoval = State(rawValue: 0b1000)

  }

}

extension MIDINode.State: CustomStringConvertible {

  var description: String {
    var result = "["
    var flagStrings: [String] = []
    if self ∋ .Playing         { flagStrings.append("Playing")         }
    if self ∋ .Jogging         { flagStrings.append("Jogging")         }
    if self ∋ .Paused          { flagStrings.append("Paused")          }
    if self ∋ .PendingRemoval  { flagStrings.append("PendingRemoval")  }
    result += ", ".join(flagStrings)
    result += "]"
    return result
  }

}

// MARK: Action
extension MIDINode {

  /// Type for representing MIDI-related node actions
  struct Action {

    enum Key: String, KeyType {
      case Move, Play, VerticalPlay, HorizontalPlay, FadeOut, FadeOutAndRemove, FadeIn
    }

    unowned let node: MIDINode
    let key: Key

    var action: SKAction {
      switch key {
        case .Move:
          let segment = node.currentSegment
          let location = segment.endLocation
          let position = node.position
          let duration = segment.timeToEndLocation(from: position)
          let move = SKAction.move(to: location, duration: duration)
          let callback = SKAction.run({[weak node] in node?.didMove()})
          return SKAction.sequence([move, callback])

        case .Play:
          let halfDuration = half(node.generator.duration.seconds)
          let scaleUp = SKAction.resize(toWidth: MIDINode.playingSize.width,
                                        height: MIDINode.playingSize.height,
                                        duration: halfDuration)
          let noteOn = SKAction.run({ self.node.sendNoteOn() })
          let scaleDown = SKAction.resize(toWidth: MIDINode.defaultSize.width,
                                          height: MIDINode.defaultSize.height,
                                          duration: halfDuration)
          let noteOff = SKAction.run({ self.node.sendNoteOff() })
          return SKAction.sequence([SKAction.group([scaleUp, noteOn]), scaleDown, noteOff])

        case .VerticalPlay:
          let noteOn = SKAction.run({ self.node.sendNoteOn() })
          let noteOff = SKAction.run({ self.node.sendNoteOff() })
          let squish = SKAction.scaleX(by: 1.5, y: 0.5, duration: 0.25)
          let unsquish = squish.reversed()
          let squishAndUnsquish = SKAction.sequence([squish, unsquish])
          return SKAction.sequence([SKAction.group([squishAndUnsquish, noteOn]), noteOff])

        case .HorizontalPlay:
          let noteOn = SKAction.run({ self.node.sendNoteOn() })
          let noteOff = SKAction.run({ self.node.sendNoteOff() })
          let squish = SKAction.scaleX(by: 0.5, y: 1.5, duration: 0.25)
          let unsquish = squish.reversed()
          let squishAndUnsquish = SKAction.sequence([squish, unsquish])
          return SKAction.sequence([SKAction.group([squishAndUnsquish, noteOn]), noteOff])

        case .FadeOut:
          let fade = SKAction.fadeOut(withDuration: 0.25)
          let pause = SKAction.run({ self.node.sendNoteOff(); self.node.isPaused = true })
          return SKAction.sequence([fade, pause])

        case .FadeOutAndRemove:
          let fade = SKAction.fadeOut(withDuration: 0.25)
          let remove = SKAction.removeFromParent()
          return SKAction.sequence([fade, remove])

        case .FadeIn:
          let fade = SKAction.fadeIn(withDuration: 0.25)
          let unpause = SKAction.run({ self.node.isPaused = false })
          return SKAction.sequence([fade, unpause])
      }
    }

    init(key: Key, node: MIDINode) { self.key = key; self.node = node }

    func run() { node.run(action, withKey: key.key) }

  }

}

extension MIDINode {

  final class Path {

    fileprivate var segments: SortedArray<BoxedSegment> = []

    let min: CGPoint, max: CGPoint

    let startTime: BarBeatTime
    let initialTrajectory: Trajectory

    var initialSegment: Segment {
      guard !segments.isEmpty else {
        fatalError("segments should always contain at least 1 segment")
      }
      return Segment(owner: segments[0])
    }

    init(trajectory: MIDINode.Trajectory, playerSize: CGSize, time: BarBeatTime = BarBeatTime.zero) {
      let offset = MIDINode.texture.size() * 0.375
      max = CGPoint((playerSize - offset).unpack)
      min = CGPoint(offset.unpack)
      startTime = time
      initialTrajectory = trajectory
      segments.append(BoxedSegment(trajectory: trajectory, time: time, path: self))
    }

    func location(for time: BarBeatTime) -> CGPoint? {
      return boxedSegment(for: time)?.location(for: time)
    }


    fileprivate func advance(segment: BoxedSegment) -> BoxedSegment {
      // Redirect trajectory according to which boundary edge the new location touches
      let v: CGVector
      switch segment.endLocation.unpack {
        case (min.x, _), (max.x, _):
          v = CGVector(dx: segment.trajectory.dx * -1, dy: segment.trajectory.dy)
        case (_, min.y), (_, max.y):
          v = CGVector(dx: segment.trajectory.dx, dy: segment.trajectory.dy * -1)
        default:
          fatalError("next location should contact an edge of the player")
      }

      let nextTrajectory = MIDINode.Trajectory(vector: v, point: segment.endLocation)
      let nextSegment = BoxedSegment(trajectory: nextTrajectory, time: segment.endTime, path: self)
      segment._successor = nextSegment
      nextSegment._predecessor = segment
      return nextSegment
    }

    fileprivate func boxedSegment(for time: BarBeatTime) -> BoxedSegment? {
      guard time >= startTime else { return nil }

      if let segmentIndex = segments.index(where: {   $0.timeInterval.lowerBound <= time
                                                   && $0.timeInterval.upperBound >= time})
      {
        return segments[segmentIndex]
      }

      var segment = segments[segments.index(before: segments.endIndex)]

      guard segment.endTime <= time else {
        fatalError("segment's end time '\(segment.endTime)' is not less than or equal to time '\(time)', "
                 + "a matching segment should have been found")
      }

      while !segment.timeInterval.contains(time) {
        segment = advance(segment: segment)
        segments.append(segment)
      }

      guard segment.timeInterval.contains(time) else {
        fatalError("segment to return does not contain time specified")
      }

      return segment
    }

    func segment(for time: BarBeatTime) -> Segment?  {
      guard let segment = boxedSegment(for: time) else { return nil }
      return Segment(owner: segment)
    }

  }

}

extension MIDINode.Path: CustomStringConvertible, CustomDebugStringConvertible {

  private func makeDescription(debug: Bool = false) -> String {
    var result = "MIDINodePath {"
    if debug {
      result += "\n\t" + "\n\t".join(
        "min: \(min)",
        "max: \(max)",
        "startTime: \(startTime)",
        "initialTrajectory: \(initialTrajectory)",
        "segments: [\n\t\t\(",\n\t\t".join(segments.map({$0.description.indented(by: 2, preserveFirst: true, useTabs: true)})))\n\t]"
        ) + "\n"
    } else {
      result += "startTime: \(startTime); segments: \(segments.count)"
    }
    result += "}"
    return result
  }

  var description: String { return makeDescription() }
  var debugDescription: String { return makeDescription(debug: true) }
}

extension MIDINode.Path {

  struct Segment {

    fileprivate let owner: BoxedSegment

    var trajectory: MIDINode.Trajectory { return owner.trajectory }

    var timeInterval: CountableRange<BarBeatTime>   { return owner.timeInterval }
    var tickInterval: CountableRange<MIDITimeStamp> { return owner.tickInterval }

    var startTime: BarBeatTime { return owner.startTime }
    var endTime:   BarBeatTime { return owner.endTime }
    var totalTime: BarBeatTime { return owner.totalTime }

    var startTicks: MIDITimeStamp { return owner.startTicks }
    var endTicks:   MIDITimeStamp { return owner.endTicks }
    var totalTicks: MIDITimeStamp { return owner.totalTicks }

    var startLocation: CGPoint { return owner.startLocation }
    var endLocation: CGPoint { return owner.endLocation }
    var length: CGFloat { return owner.length }

    func location(for time: BarBeatTime) -> CGPoint? { return owner.location(for: time) }

    func timeToEndLocation(from point: CGPoint) -> TimeInterval {
      return owner.timeToEndLocation(from: point)
    }

    var predecessor: Segment? {
      guard let predecessor = owner.predecessor() else { return nil }
      return Segment(owner: predecessor)
    }

    var successor: Segment { return Segment(owner: owner.successor()) }

  }

}

extension MIDINode.Path.Segment: Comparable {

  static func ==(lhs: MIDINode.Path.Segment, rhs: MIDINode.Path.Segment) -> Bool {
    return lhs.owner == rhs.owner
  }

  static func <(lhs: MIDINode.Path.Segment, rhs: MIDINode.Path.Segment) -> Bool {
    return lhs.owner < rhs.owner
  }

}

extension MIDINode.Path.Segment: CustomStringConvertible {

  var description: String { return owner.description }

}

extension MIDINode.Path {

  fileprivate final class BoxedSegment {

    unowned let path: MIDINode.Path

    let trajectory: MIDINode.Trajectory

    let timeInterval: CountableRange<BarBeatTime>
    let tickInterval: CountableRange<MIDITimeStamp>

    var startTime: BarBeatTime { return timeInterval.lowerBound }
    var endTime:   BarBeatTime { return timeInterval.upperBound }
    var totalTime: BarBeatTime { return timeInterval.upperBound - timeInterval.lowerBound }

    var startTicks: MIDITimeStamp { return tickInterval.lowerBound }
    var endTicks:   MIDITimeStamp { return tickInterval.upperBound }
    var totalTicks: MIDITimeStamp { return endTicks > startTicks ? endTicks - startTicks : 0 }

    var startLocation: CGPoint { return trajectory.p }
    let endLocation: CGPoint
    let length: CGFloat

    weak var _predecessor: BoxedSegment?
    weak var _successor: BoxedSegment?

    func predecessor() -> BoxedSegment? { return _predecessor }

    func successor() -> BoxedSegment {
      guard _successor == nil else { return _successor! }
      return path.advance(segment: self)
    }

    func location(for time: BarBeatTime) -> CGPoint? {
      guard timeInterval.lowerBound <= time && timeInterval.upperBound >= time else { return nil }
      let 𝝙ticks = CGFloat(time.ticks - startTime.ticks)
      let ratio = 𝝙ticks / CGFloat(tickInterval.count)
      var result = trajectory.p
      result.x += ratio * (endLocation.x - result.x)
      result.y += ratio * (endLocation.y - result.y)
      return result
    }

    func timeToEndLocation(from point: CGPoint) -> TimeInterval {
      return trajectory.time(fromPoint: point, toPoint: endLocation)
    }

    init(trajectory: MIDINode.Trajectory, time: BarBeatTime, path: MIDINode.Path) {
      self.trajectory = trajectory
      self.path = path
      let endY: CGFloat

      switch trajectory.direction.vertical {
        case .none: endY = trajectory.p.y
        case .up:   endY = path.max.y
        case .down: endY = path.min.y
      }

      let pY: CGPoint? = {
        let p = trajectory.point(atY: endY)
        guard (path.min.x ... path.max.x).contains(p.x) else { return nil }
        return p
      }()

      let endX: CGFloat

      switch trajectory.direction.horizontal {
        case .none:  endX = trajectory.p.x
        case .left:  endX = path.min.x
        case .right: endX = path.max.x
      }

      let pX: CGPoint? = {
        let p = trajectory.point(atX: endX)
        guard (path.min.y ... path.max.y).contains(p.y) else { return nil }
        return p
      }()

      switch (pY, pX) {

        case (let p1?, let p2?) where trajectory.p.distanceTo(p1) < trajectory.p.distanceTo(p2):
          endLocation = p1

        case (_, let p?):
          endLocation = p

        case (let p?, _):
          endLocation = p

        default:
          fatalError("at least one of projected end points should be valid")

      }

      length = trajectory.p.distanceTo(endLocation)

      let 𝝙t = trajectory.time(fromPoint: trajectory.p, toPoint: endLocation)
      let endTime = BarBeatTime(seconds: time.seconds + 𝝙t)

      timeInterval = time ..< endTime
      tickInterval = timeInterval.lowerBound.ticks ..< timeInterval.upperBound.ticks
    }

  }

}

extension MIDINode.Path.BoxedSegment: Comparable {

  static func ==(lhs: MIDINode.Path.BoxedSegment, rhs: MIDINode.Path.BoxedSegment) -> Bool {
    return lhs.startTime == rhs.startTime
  }

  static func <(lhs: MIDINode.Path.BoxedSegment, rhs: MIDINode.Path.BoxedSegment) -> Bool {
    return lhs.startTime < rhs.startTime
  }

}

extension MIDINode.Path.BoxedSegment: CustomStringConvertible {

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

}

extension MIDINode {


  struct Trajectory {

    /// The constant used to adjust the velocity units when calculating times
    static let modifier: Ratio = 1∶1000

    /// The slope of the trajectory (`dy` / `dx`)
    var m: CGFloat { return dy / dx }

    /// The velocity in units along the lines of those used by `SpriteKit`.
    var v: CGVector { return CGVector(dx: dx, dy: dy) }

    /// The initial point
    var p: CGPoint { return CGPoint(x: x, y: y) }

    /// The direction specified by the trajectory
    var direction: Direction {
      get { return Direction(vector: v) }
      set {
        guard direction != newValue else { return }

        switch (direction.vertical, newValue.vertical) {

          case (.up, .down), (.down, .up):
            dy *= -1

          case (_, .none):
            dy = 0

          default:
            break

        }

        switch (direction.horizontal, newValue.horizontal) {

          case (.left, .right), (.right, .left):
            dx *= -1

          case (_, .none):
            dx = 0

          default:
            break

        }

      }

    }

    func rotatedTo(angle: CGFloat) -> Trajectory {
      var result = self
      result.angle = angle
      return result
    }

    mutating func formRotatedTo(angle: CGFloat) { self.angle = angle }

    /// The horizontal velocity in units along the lines of those used by `SpriteKit`.
    var dx: CGFloat

    /// The vertical velocity in units along the lines of those used by `SpriteKit`.
    var dy: CGFloat

    /// The initial position along the x axis
    var x: CGFloat

    /// The initial position along the y axis
    var y: CGFloat

    var angle: CGFloat {
      get { return v.angle }
      set { (dx, dy) = *v.rotateTo(newValue) }
    }

    /// Default initializer
    init(vector: CGVector, point: CGPoint) {
      dx = vector.dx
      dy = vector.dy
      x = point.x
      y = point.y }

    
     /// The point along the trajectory with the specified x value
     ///
     ///    y = m (x - x<sub>1</sub>) + y<sub>1</sub>
    func point(atX x: CGFloat) -> CGPoint {
      let result = CGPoint(x: x, y: m * (x - p.x) + p.y)
      Log.verbose("self = \(self)\nx = \(x)\nresult = \(result)")
      return result
    }


    /// The point along the trajectory with the specified y value
    ///
    ///    x = (y - y<sub>1</sub> + mx<sub>1</sub>) / m
    func point(atY y: CGFloat) -> CGPoint {
      let result = CGPoint(x: (y - p.y + m * p.x) / m, y: y)
      Log.verbose("self = \(self)\ny = \(y)\nresult = \(result)")
      return result
    }

    
    /// Elapsed time in seconds between the two points along the trajectory with the respective x values specified.
    func time(fromX x1: CGFloat, toX x2: CGFloat) -> TimeInterval {
      return time(fromPoint: point(atX: x1), toPoint: point(atX: x2))
    }

    
    /// Elapsed time in seconds between the two points along the trajectory with the respective y values specified.
    func time(fromY y1: CGFloat, toY y2: CGFloat) -> TimeInterval {
      return time(fromPoint: point(atY: y1), toPoint: point(atY: y2))
    }

    /// Elapsed time in seconds between the specified points
    func time(fromPoint p1: CGPoint, toPoint p2: CGPoint) -> TimeInterval {
      let result = abs(TimeInterval(p1.distanceTo(p2) / m)) * TimeInterval(Trajectory.modifier.fraction)
      guard result.isFinite else { fatalError("wtf") }
      Log.verbose("self = \(self)\np1 = \(p1)\np2 = \(p2)\nresult = \(result)")
      return result
    }

    /// Whether the specified point lies along the trajectory (approximated by rounding to three decimal places).
    func contains(point: CGPoint) -> Bool {
      let lhs = abs((point.y - p.y).rounded(3))
      let rhs = abs((m * (point.x - p.x)).rounded(3))
      let result = lhs == rhs
      Log.verbose("self = \(self)\npoint = \(point)\nresult = \(result)")
      return result
    }

    static var zero: Trajectory { return Trajectory(vector: CGVector.zero, point: CGPoint.zero) }

    /// Trajectory value for representing a 'null' or 'invalid' trajectory
    static var null: Trajectory { return Trajectory(vector: CGVector.zero, point: CGPoint.null) }

  }

}

extension MIDINode.Trajectory: Hashable {

  var hashValue: Int { return dx.hashValue ^ dy.hashValue ^ x.hashValue ^ y.hashValue }

  static func ==(lhs: MIDINode.Trajectory, rhs: MIDINode.Trajectory) -> Bool {
    return lhs.dx == rhs.dx && lhs.dy == rhs.dy && lhs.x == rhs.x && lhs.y == rhs.y
  }

}

extension MIDINode.Trajectory {

  /// Type for specifiying the direction of a `Trajectory`.
  enum Direction: Equatable, CustomStringConvertible {

    enum VerticalMovement:   String, Equatable { case none, up,   down  }
    enum HorizontalMovement: String, Equatable { case none, left, right }

    case none
    case vertical (VerticalMovement)
    case horizontal (HorizontalMovement)
    case diagonal (VerticalMovement, HorizontalMovement)

    init(vector: CGVector) {
      switch (vector.dx, vector.dy) {
        case (0, 0):                                                        self = .none
        case (0, let dy) where dy.sign == .minus:                           self = .vertical(.down)
        case (0, _):                                                        self = .vertical(.up)
        case (let dx, 0) where dx.sign == .minus:                           self = .horizontal(.left)
        case (_, 0):                                                        self = .horizontal(.right)
        case (let dx, let dy) where dx.sign == .minus && dy.sign == .minus: self = .diagonal(.down, .left)
        case (let dx, _) where dx.sign == .minus:                           self = .diagonal(.up, .left)
        case (_, let dy) where dy.sign == .minus:                           self = .diagonal(.down, .right)
        case (_, _):                                                        self = .diagonal(.up, .right)
      }
    }

    init(start: CGPoint, end: CGPoint) {
      switch (start.unpack, end.unpack) {
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
          case .horizontal(let h):  self = .diagonal(newValue, h)
          case .vertical(_):        self = .vertical(newValue)
          case .diagonal(_, let h): self = .diagonal(newValue, h)
          case .none:               self = .vertical(newValue)
        }
      }
    }

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
          case .vertical(let v):    self = .diagonal(v, newValue)
          case .horizontal(_):      self = .horizontal(newValue)
          case .diagonal(let v, _): self = .diagonal(v, newValue)
          case .none:               self = .horizontal(newValue)
        }
      }
    }

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
        case .diagonal(let v, let h): return "-".join(v.rawValue, h.rawValue)
        case .none:                   return "none"
      }
    }
    
    static func ==(lhs: Direction, rhs: Direction) -> Bool {
      return lhs.vertical == rhs.vertical && lhs.horizontal == rhs.horizontal
    }
  }

}

extension MIDINode.Trajectory: ByteArrayConvertible {

  /// A string representation of the Trajectory as an array of bytes.
  var bytes: [Byte] { return Array("{\(NSStringFromCGPoint(p)), \(NSStringFromCGVector(v))}".utf8) }

  /// Initializing with an array of bytes.
  init(_ bytes: [Byte]) {
    let string = String(bytes)
    let float = "-?[0-9]+(?:\\.[0-9]+)?"
    let value = "\\{\(float), \(float)\\}"

    guard
      let match = (~/"\\{(\(value)), (\(value))\\}").firstMatch(in: string, anchored: true),
      let positionCapture = match.captures[1],
      let vectorCapture = match.captures[2]
      else
    {
      self = .null
      return
    }

    guard
      let point = CGPoint(positionCapture.string),
      let vector = CGVector(vectorCapture.string)
      else
    {
      self = .null
      return
    }

    x = point.x; y = point.y
    dx = vector.dx; dy = vector.dy
  }

}

extension MIDINode.Trajectory: LosslessJSONValueConvertible {

  /// The json object for the trajectory
  var jsonValue: JSONValue { return ["p": p, "v": v] }

  /// Initializing with a json value.
  init?(_ jsonValue: JSONValue?) {
    guard
      let dict = ObjectJSONValue(jsonValue),
      let p = CGPoint(dict["p"]),
      let v = CGVector(dict["v"])
      else
    {
      return nil
    }
    
    self.init(vector: v, point: p)
  }

}

extension MIDINode.Trajectory: CustomStringConvertible {

  var description: String { return "{ x: \(x); y: \(y); dx: \(dx); dy: \(dy); direction: \(direction) }" }

}
