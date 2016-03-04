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

  var initTime: BarBeatTime
  var initialTrajectory: Trajectory

  private(set) var pendingPosition: CGPoint?

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
  private lazy var moveAction:             Action = self.action(.Move)

  /**
   action:

   - parameter key: Action.Key

    - returns: Action
  */
  private func action(key: Action.Key) -> Action { return Action(key: key, node: self) }

  /** play */
  func play() { playAction.run()  }

  /** updatePosition */
  func updatePosition() {
    guard let position = pendingPosition else { return }
//    logDebug("position: \(position)")
    self.position = position
    pendingPosition = nil
  }

  /** fadeOut */
  func fadeOut(remove remove: Bool = false) { (remove ? fadeOutAndRemoveAction : fadeOutAction).run() }

  /** fadeIn */
  func fadeIn() { fadeInAction.run() }

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
  private func removeAction(action: Action) { removeActionForKey(action.key.key) }

  /**
  removeActionForKey:

  - parameter key: String
  */
  override func removeActionForKey(key: String) {
    switch key {
      case Action.Key.Play.rawValue where actionForKey(key) != nil:
        sendNoteOff()
      default: break
    }
    super.removeActionForKey(key)
  }

  /** didMove */
  private func didMove() {
    play()
    currentSegment = currentSegment.successor
    moveAction.run()
  }

  private(set) weak var dispatch: MIDINodeDispatch?  {
    didSet { if dispatch == nil && parent != nil { removeFromParent() } }
  }

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
    guard state ∌ .Jogging else {
      fatalError("internal inconsistency, should not already have `Jogging` flag set")
    }
    logDebug("position: \(position); path: \(path)")
    state ⊻= .Jogging
    removeActionForKey(Action.Key.Move.rawValue)
  }

  /**
  didJog:

  - parameter notification: NSNotification
  */
  private func didJog(notification: NSNotification) {
    guard state ∋ .Jogging else { fatalError("internal inconsistency, should have `Jogging` flag set") }

    guard let time = notification.jogTime else { fatalError("notification does not contain ticks") }

    logDebug("time: \(time)")

    if time < initTime && state ∌ .PendingRemoval {
      state ∪= .PendingRemoval
      hidden = true
    } else if time >= initTime {
      if  state ∋ .PendingRemoval { state.remove(.PendingRemoval); hidden = false }
      pendingPosition = path.locationForTime(time)
    }
  }

  /**
  didEndJogging:

  - parameter notification: NSNotification
  */
  private func didEndJogging(notification: NSNotification) {
    guard state ∋ .Jogging else {
      logError("internal inconsistency, should have `Jogging` flag set"); return
    }
    state ⊻= .Jogging
    guard state ∌ .PendingRemoval else { removeFromParent(); return }
    guard state ∌ .Paused else { return }
    currentSegment = path.segmentForTime(Sequencer.time.barBeatTime) ?? path.initialSegment
    moveAction.run()
  }

  /**
  didStart:

  - parameter notification: NSNotification
  */
  private func didStart(notification: NSNotification) {
    guard state ∋ .Paused else { return }
    logDebug("unpausing")
    state ⊻= .Paused
    moveAction.run()
  }

  /**
  didPause:

  - parameter notification: NSNotification
  */
  private func didPause(notification: NSNotification) {
    guard state ∌ .Paused else { return }
    logDebug("pausing")
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

  // MARK: Initialization

  static let texture = SKTexture(image: UIImage(named: "ball")!)
  private static let normalMap = MIDINode.texture.textureByGeneratingNormalMap()

  static let defaultSize: CGSize = MIDINode.texture.size() * 0.75
  static let playingSize: CGSize = MIDINode.texture.size()

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
    initTime = Sequencer.time.barBeatTime
    initialTrajectory = trajectory
    state = Sequencer.jogging ? [.Jogging] : []
    self.dispatch = dispatch
    self.generator = generator
    self.identifier = identifier

    guard let playerSize = MIDIPlayer.playerNode?.size else {
      fatalError("creating node with nil value for `MIDIPlayer.playerNode`")
    }
    path = MIDINodePath(trajectory: trajectory,
                        playerSize: playerSize,
                        time: Sequencer.transport.time.barBeatTime)
    currentSegment = path.initialSegment

    super.init(texture: MIDINode.texture,
               color: dispatch.color.value,
               size: MIDINode.texture.size() * 0.75)

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
    moveAction.run()
  }


  let path: MIDINodePath
  private var currentSegment: Segment

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

}

// MARK: State
extension MIDINode {
  struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    static let Playing        = State(rawValue: 0b0001)
    static let Jogging        = State(rawValue: 0b0010)
    static let Paused         = State(rawValue: 0b0100)
    static let PendingRemoval = State(rawValue: 0b1000)

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
}

// MARK: Action
extension MIDINode {
  /// Type for representing MIDI-related node actions
  struct Action {

    enum Key: String, KeyType { case Move, Play, VerticalPlay, HorizontalPlay, FadeOut, FadeOutAndRemove, FadeIn }

    unowned let node: MIDINode
    let key: Key

    var action: SKAction {
      switch key {
        case .Move:
          let segment = node.currentSegment
          let location = segment.endLocation
          let position = node.position
          let duration = segment.timeToEndLocationFromPoint(position)
          let move = SKAction.moveTo(location, duration: duration)
          let callback = SKAction.runBlock({[weak node] in node?.didMove()})
          return SKAction.sequence([move, callback])

        case .Play:
          let halfDuration = half(node.generator.duration.seconds)
          let scaleUp = SKAction.resizeToWidth(MIDINode.playingSize.width, height: MIDINode.playingSize.height, duration: halfDuration) //SKAction.scaleTo(2, duration: halfDuration)
          let noteOn = SKAction.runBlock({ self.node.sendNoteOn() })
          let scaleDown = SKAction.resizeToWidth(MIDINode.defaultSize.width, height: MIDINode.defaultSize.height, duration: halfDuration) //SKAction.scaleTo(1, duration: halfDuration)
          let noteOff = SKAction.runBlock({ self.node.sendNoteOff() })
          return SKAction.sequence([SKAction.group([scaleUp, noteOn]), scaleDown, noteOff])

        case .VerticalPlay:
          let noteOn = SKAction.runBlock({ self.node.sendNoteOn() })
          let noteOff = SKAction.runBlock({ self.node.sendNoteOff() })
          let squish = SKAction.scaleXBy(1.5, y: 0.5, duration: 0.25)
          let unsquish = squish.reversedAction()
          let squishAndUnsquish = SKAction.sequence([squish, unsquish])
          return SKAction.sequence([SKAction.group([squishAndUnsquish, noteOn]), noteOff])

        case .HorizontalPlay:
          let noteOn = SKAction.runBlock({ self.node.sendNoteOn() })
          let noteOff = SKAction.runBlock({ self.node.sendNoteOff() })
          let squish = SKAction.scaleXBy(0.5, y: 1.5, duration: 0.25)
          let unsquish = squish.reversedAction()
          let squishAndUnsquish = SKAction.sequence([squish, unsquish])
          return SKAction.sequence([SKAction.group([squishAndUnsquish, noteOn]), noteOff])

        case .FadeOut:
          let fade = SKAction.fadeOutWithDuration(0.25)
          let pause = SKAction.runBlock({ self.node.sendNoteOff(); self.node.paused = true })
          return SKAction.sequence([fade, pause])

        case .FadeOutAndRemove:
          let fade = SKAction.fadeOutWithDuration(0.25)
          let remove = SKAction.removeFromParent()
          return SKAction.sequence([fade, remove])

        case .FadeIn:
          let fade = SKAction.fadeInWithDuration(0.25)
          let unpause = SKAction.runBlock({ self.node.paused = false })
          return SKAction.sequence([fade, unpause])
      }
    }

    /**
     initWithKey:node:

     - parameter key: Key
     - parameter node: MIDINode
    */
    init(key: Key, node: MIDINode) { self.key = key; self.node = node }

    /** run */
    func run() { node.runAction(action, withKey: key.key) }

  }
}