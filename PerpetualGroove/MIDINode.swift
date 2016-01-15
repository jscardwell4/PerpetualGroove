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



// MARK:- MIDINode
final class MIDINode: SKSpriteNode {

  /// Holds the current state of the node
  private var state: State = []

  // MARK: Generating MIDI note events

  private var client = MIDIClientRef()
  private(set) var endPoint = MIDIEndpointRef()

  var generator: MIDIGenerator {
    didSet {
      guard generator != oldValue else { return }
      playAction = Action(key: .Play, node: self)
    }
  }

  /// Whether a note is ended via a note on event with velocity of 0 or with a  note off event
  static let useVelocityForOff = true

  typealias Identifier = UUID

  let identifier: Identifier

  private lazy var playAction:             Action = self.action(.Play)
  private lazy var horizontalPlayAction:   Action = self.action(.HorizontalPlay)
  private lazy var verticalPlayAction:     Action = self.action(.VerticalPlay)
  private lazy var fadeOutAction:          Action = self.action(.FadeOut)
  private lazy var fadeOutAndRemoveAction: Action = self.action(.FadeOutAndRemove)
  private lazy var fadeInAction:           Action = self.action(.FadeIn)

  /**
   action:

   - parameter key: Action.Key

    - returns: Action
  */
  private func action(key: Action.Key) -> Action { return Action(key: key, node: self) }

  /**
  runAction:

  - parameter action: Action
  */
  private func runAction(action: Action) { runAction(action.action, withKey: action.key) }

  /** play */
  func play() { runAction(playAction)  }

  /**
   playForEdge:

   - parameter edge: MIDIPlayerNode.Edge
  */
  func playForEdge(edge: MIDIPlayerNode.Edge) {
    runAction(playAction)
//    switch edge {
//      case .Top, .Bottom: runAction(verticalPlayAction)
//      case .Left, .Right: runAction(horizontalPlayAction)
//      case .None: runAction(playAction)
//    }
  }

  /** fadeOut */
  func fadeOut(remove remove: Bool = false) { runAction(remove ? fadeOutAndRemoveAction : fadeOutAction) }

  /** fadeIn */
  func fadeIn() { runAction(fadeInAction) }

  /** sendNoteOn */
  func sendNoteOn() {
    do {
      try generator.receiveNoteOn(endPoint, UInt64(ObjectIdentifier(self).uintValue))
      state ⊻= .Playing
    } catch { logError(error) }
  }

  /** sendNoteOff */
  func sendNoteOff() {
    guard state ∋ .Playing else { return }
    do {
      try generator.receiveNoteOff(endPoint, UInt64(ObjectIdentifier(self).uintValue))
      state ⊻= .Playing
    } catch { logError(error) }
  }

  /**
  removeAction:

  - parameter action: Action
  */
  private func removeAction(action: Action) { removeActionForKey(action.key) }

  /**
  removeActionForKey:

  - parameter key: String
  */
  override func removeActionForKey(key: String) {
    switch key {
      case Action.Key.Play.rawValue where actionForKey(key) != nil:
        sendNoteOff()
//      case Action.Key.Move.rawValue where actionForKey(key) != nil:
//        pushBreadcrumb()
      default: break
    }
    super.removeActionForKey(key)
  }

  /** didMove */
  private func didMove() {
//    guard let (minX, maxX, minY, maxY) = minMaxValues else { return }
//
//    trajectory.p = position
//
//    switch position.unpack {
//      case (minX, _), (maxX, _): trajectory.dx *= -1
//      case (_, minY), (_, maxY): trajectory.dy *= -1
//      default: break
//    }

    play()
    runAction(action(.Move))
  }

  private(set) weak var dispatch: MIDINodeDispatch?  {
    didSet { if dispatch == nil && parent != nil { removeFromParent() } }
  }

  var edges: MIDIPlayerNode.Edges = .All {
    didSet { physicsBody?.contactTestBitMask = edges.rawValue }
  }

  private var previousVelocity: CGVector?

  // MARK: Listening for Sequencer notifications

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.SceneContext
    return receptionist
  }()

  /**
  didBeginJogging:

  - parameter notification: NSNotification
  */
  private func didBeginJogging(notification: NSNotification) {
    guard state ∌ .Jogging else { fatalError("internal inconsistency, should not already have `Jogging` flag set") }
//    pushBreadcrumb() // Make sure the latest position gets added to history before jogging begins
    state ⊻= .Jogging
    removeActionForKey(Action.Key.Move.rawValue)
  }

  /**
  didJog:

  - parameter notification: NSNotification
  */
  private func didJog(notification: NSNotification) {
    guard state ∋ .Jogging else { fatalError("internal inconsistency, should have `Jogging` flag set") }
    guard let jogTime = notification.jogTime else {
      logError("notication does not contain jog tick value")
      return
    }
//    guard let snapshot = history.snapshotForTicks(jogTime.ticks) else {
//      logError("history does not contain snapshot for jog time '\(jogTime.rawValue)'")
//      return
//    }
//    animateToSnapshot(snapshot)
  }

  /**
  didEndJogging:

  - parameter notification: NSNotification
  */
  private func didEndJogging(notification: NSNotification) {
    guard state ∋ .Jogging else { fatalError("internal inconsistency, should have `Jogging` flag set") }
    state ⊻= .Jogging
    guard state ∌ .Paused else { return }
    runAction(action(.Move))
  }

  /**
  didStart:

  - parameter notification: NSNotification
  */
  private func didStart(notification: NSNotification) {
    guard state ∋ .Paused else { return }
    logDebug("unpausing")
    state ⊻= .Paused
    runAction(action(.Move))
  }

  /**
  didPause:

  - parameter notification: NSNotification
  */
  private func didPause(notification: NSNotification) {
    guard state ∌ .Paused else { return }
    logDebug("pausing")
//    pushBreadcrumb()
    state ⊻= .Paused
    removeActionForKey(Action.Key.Move.rawValue)
  }

  /**
   didReset:

   - parameter notification: NSNotification
  */
  private func didReset(notification: NSNotification) {
    fadeOut(remove: true)
  }

  // MARK: Snapshots

//  typealias Snapshot = MIDINodeHistory.Snapshot

  /// Holds the nodes breadcrumbs to use in jogging calculations
//  private var history: MIDINodeHistory

  /// The breadcrumb currently referenced in jogging calculations
//  private var breadcrumb: MIDINodeHistory.Breadcrumb?

  /// Snapshot of the initial trajectory and velocity for the node
//  var initialSnapshot: Snapshot

  /// Snapshot of the current trajectory and velocity for the node
//  private var currentSnapshot: Snapshot

  /** Updates `currentSnapshot`, adding a new breadcrumb to `history` from the old value to the new value */
//  func pushBreadcrumb() {
//    guard state ∌ .Jogging else { logWarning("node has `Jogging` flag set, ignoring request to mark"); return }
//    let snapshot = Snapshot(ticks: Sequencer.time.ticks, position: position, velocity: trajectory.v)
//    guard snapshot.ticks > currentSnapshot.ticks else { return }
//    history.append(from: currentSnapshot, to: snapshot)
//    currentSnapshot = snapshot
//  }

  /**
   Animates the node to the location specified by the specified snapshot

   - parameter snapshot: Snapshot
   - parameter completion: (() -> Void)?
  */
//  private func animateToSnapshot(snapshot: Snapshot) {
//    let from = currentSnapshot.ticks, to = snapshot.ticks, 𝝙ticks = Double(max(from, to) - min(from, to))
//    runAction(SKAction.moveTo(snapshot.trajectory.p, duration: Sequencer.secondsPerTick * 𝝙ticks)) {
//      [weak self] in self?.currentSnapshot = snapshot; self?.trajectory = snapshot.trajectory
//    }
//  }

  // MARK: Initialization

  static let texture = SKTexture(image: UIImage(named: "ball")!)
  private static let normalMap = MIDINode.texture.textureByGeneratingNormalMap()

  /**
   initWithTrajectory:name:dispatch:generator:identifier:

   - parameter trajectory: Trajectory
   - parameter name: String
   - parameter dispatch: MIDINodeDispatch
   - parameter generator: MIDIGenerator
   - parameter identifier: Identifier = UUID()
  */
  init(trajectory: Trajectory,
       name: String,
       dispatch: MIDINodeDispatch,
       generator: MIDIGenerator,
       identifier: Identifier = UUID()) throws
  {
//    self.trajectory = trajectory
//    let snapshot = Snapshot(ticks: Sequencer.time.ticks, trajectory: trajectory)
//    initialSnapshot = snapshot
//    currentSnapshot = snapshot
    self.dispatch = dispatch
//    history = MIDINodeHistory(initialSnapshot: snapshot)
    self.generator = generator
    self.identifier = identifier

    guard let playerSize = MIDIPlayer.playerNode?.size else {
      fatalError("creating node with nil value for `MIDIPlayer.playerNode`")
    }
    path = MIDINodePath(trajectory: trajectory, playerSize: playerSize)
    super.init(texture: MIDINode.texture, color: dispatch.color.value, size: MIDINode.texture.size() * 0.75)

    let object = Sequencer.transport
    typealias Notification = Transport.Notification

    receptionist.observe(Notification.DidBeginJogging,
                    from: object,
                callback: weakMethod(self, MIDINode.didBeginJogging))
    receptionist.observe(Notification.DidJog,
                    from: object,
                callback: weakMethod(self, MIDINode.didJog))
    receptionist.observe(Notification.DidEndJogging,
                    from: object,
                callback: weakMethod(self, MIDINode.didEndJogging))
    receptionist.observe(Notification.DidStart,
                    from: object,
                callback: weakMethod(self, MIDINode.didStart))
    receptionist.observe(Notification.DidPause,
                    from: object,
                callback: weakMethod(self, MIDINode.didPause))
    receptionist.observe(Notification.DidReset,
                    from: object,
                callback: weakMethod(self, MIDINode.didReset))

    try MIDIClientCreateWithBlock(name, &client, nil) ➤ "Failed to create midi client"
    try MIDISourceCreate(client, "\(name)", &endPoint) ➤ "Failed to create end point for node \(name)"

    self.name = name
    colorBlendFactor = 1

    position = trajectory.p
    normalTexture = MIDINode.normalMap
    runAction(action(.Move))
  }


  let path: MIDINodePath
//  private var trajectory: Trajectory

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  
  deinit {
    if state ∋ .Playing { sendNoteOff() }
    do {
      logDebug("disposing of MIDI client and end point")
      try MIDIEndpointDispose(endPoint) ➤ "Failed to dispose of end point"
      try MIDIClientDispose(client) ➤ "Failed to dispose of midi client"
    } catch { logError(error) }
  }

  private var minMaxValues: (minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat)? {
    guard let playerSize = MIDIPlayer.playerNode?.frame.size else { return nil }
    let offset = MIDINode.texture.size() * 0.375
    let (maxX, maxY) = (playerSize - offset).unpack
    let (minX, minY) = offset.unpack
    return (minX, maxX, minY, maxY)
  }

  /**
   nextLocation

    - returns: (CGPoint, NSTimeInterval)?
  */
  func nextLocation() -> (CGPoint, NSTimeInterval)? {
    guard let location = path.nextLocationForTime(Sequencer.transport.time.doubleValue, fromPoint: position) else {
      fatalError("failed to obtain next location from path")
    }
    return location
  }
}

// MARK: State
extension MIDINode {
  struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    static let Playing = State(rawValue: 0b001)
    static let Jogging = State(rawValue: 0b010)
    static let Paused  = State(rawValue: 0b100)

    var description: String {
      var result = "["
      var flagStrings: [String] = []
      if self ∋ .Playing { flagStrings.append("Playing") }
      if self ∋ .Jogging { flagStrings.append("Jogging") }
      if self ∋ .Paused  { flagStrings.append("Paused")  }
      result += ", ".join(flagStrings)
      result += "]"
      return result
    }
  }
}

// MARK: Action
extension MIDINode {
  /// Type for representing MIDI-related node actions
  struct Action {

    enum Key: String { case Move, Play, VerticalPlay, HorizontalPlay, FadeOut, FadeOutAndRemove, FadeIn }

    let key: String
    let action: SKAction

    /**
    init:duration:

    - parameter k: Key
    - parameter d: NSTimeInterval
    */
    init(key k: Key, node: MIDINode? = nil) {
      key = k.rawValue

      switch k {
        case .Move:
          guard let (location, duration) = node?.nextLocation() else {
            fatalError("the 'Move' action requires a location and duration")
          }
          let move = SKAction.moveTo(location, duration: duration)
          let callback = SKAction.runBlock({[weak node] in node?.didMove()})
          action = SKAction.sequence([move, callback])

        case .Play:
          let halfDuration = half(node?.generator.duration.seconds ?? 0)
          let scaleUp = SKAction.scaleTo(2, duration: halfDuration)
          let noteOn = SKAction.runBlock({ [weak node] in node?.sendNoteOn() })
          let scaleDown = SKAction.scaleTo(1, duration: halfDuration)
          let noteOff = SKAction.runBlock({ [weak node] in node?.sendNoteOff() })
          action = SKAction.sequence([SKAction.group([scaleUp, noteOn]), scaleDown, noteOff])

        case .VerticalPlay:
          let noteOn = SKAction.runBlock({ [weak node] in node?.sendNoteOn() })
          let noteOff = SKAction.runBlock({ [weak node] in node?.sendNoteOff() })
          let squish = SKAction.scaleXBy(1.5, y: 0.5, duration: 0.25)
          let unsquish = squish.reversedAction()
          let squishAndUnsquish = SKAction.sequence([squish, unsquish])
          action = SKAction.sequence([SKAction.group([squishAndUnsquish, noteOn]), noteOff])

        case .HorizontalPlay:
          let noteOn = SKAction.runBlock({ [weak node] in node?.sendNoteOn() })
          let noteOff = SKAction.runBlock({ [weak node] in node?.sendNoteOff() })
          let squish = SKAction.scaleXBy(0.5, y: 1.5, duration: 0.25)
          let unsquish = squish.reversedAction()
          let squishAndUnsquish = SKAction.sequence([squish, unsquish])
          action = SKAction.sequence([SKAction.group([squishAndUnsquish, noteOn]), noteOff])

        case .FadeOut:
          let fade = SKAction.fadeOutWithDuration(0.25)
          let pause = SKAction.runBlock({[weak node] in node?.sendNoteOff(); node?.paused = true })
          action = SKAction.sequence([fade, pause])

        case .FadeOutAndRemove:
          let fade = SKAction.fadeOutWithDuration(0.25)
          let remove = SKAction.removeFromParent()
          action = SKAction.sequence([fade, remove])

        case .FadeIn:
          let fade = SKAction.fadeInWithDuration(0.25)
          let unpause = SKAction.runBlock({[weak node] in node?.paused = false })
          action = SKAction.sequence([fade, unpause])
      }

    }

  }
}