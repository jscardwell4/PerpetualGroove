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

// MARK: MIDINoteGenerator protocol
protocol MIDINoteGenerator {
  var duration: Duration { get set }
  var velocity: Velocity { get set }
  var octave: Octave     { get set }
  var root: Note { get set }
  func sendNoteOn(outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws
  func sendNoteOff(outPort: MIDIPortRef, _ endPoint: MIDIEndpointRef) throws
  func receiveNoteOn(endPoint: MIDIEndpointRef, _ identifier: UInt64) throws
  func receiveNoteOff(endPoint: MIDIEndpointRef, _ identifier: UInt64) throws
}

// MARK:- MIDINode
final class MIDINode: SKSpriteNode {

  /// Holds the current state of the node
  private var state: State = []

  // MARK: Generating MIDI note events

  private var client = MIDIClientRef()
  private(set) var endPoint = MIDIEndpointRef()

  var noteGenerator: MIDINoteGenerator {
    didSet {
      guard oldValue.duration != noteGenerator.duration else { return }
      playAction = Action(key: .Play, node: self)
    }
  }

  /// Whether a note is ended via a note on event with velocity of 0 or with a  note off event
  static let useVelocityForOff = true

  typealias Identifier = UInt64

  /// Embedded in MIDI packets to allow a track with multiple nodes to identify the event's source
  private(set) lazy var identifier: Identifier = Identifier(ObjectIdentifier(self).uintValue)

  private lazy var playAction:             Action = Action(key: .Play,    node: self)
  private lazy var fadeOutAction:          Action = Action(key: .FadeOut, node: self)
  private lazy var fadeOutAndRemoveAction: Action = Action(key: .FadeOutAndRemove, node: self)
  private lazy var fadeInAction:           Action = Action(key: .FadeIn,  node: self)

  /**
  runAction:

  - parameter action: Action
  */
  private func runAction(action: Action) { runAction(action.action, withKey: action.key) }

  /** play */
  func play() { runAction(playAction)  }

  /** fadeOut */
  func fadeOut(remove remove: Bool = false) { runAction(remove ? fadeOutAndRemoveAction : fadeOutAction) }

  /** fadeIn */
  func fadeIn() { runAction(fadeInAction) }

  /** sendNoteOn */
  func sendNoteOn() {
    do {
      try noteGenerator.receiveNoteOn(endPoint, identifier)
      state ⊻= .Playing
    } catch { logError(error) }
  }

  /** sendNoteOff */
  func sendNoteOff() {
    guard state ∋ .Playing else { return }
    do {
      try noteGenerator.receiveNoteOff(endPoint, identifier)
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
    if actionForKey(key) != nil && Action.Key.Play.rawValue == key { sendNoteOff() }
    super.removeActionForKey(key)
  }

  private weak var track: InstrumentTrack?  {
    didSet { if track == nil && parent != nil { removeFromParent() } }
  }

  override var physicsBody: SKPhysicsBody! {
    get {
      guard let body = super.physicsBody else {
        let body = SKPhysicsBody(circleOfRadius: size.width * 0.5)
        body.affectedByGravity = false
        body.usesPreciseCollisionDetection = true
        body.linearDamping = 0.0
        body.angularDamping = 0.0
        body.friction = 0.0
        body.restitution = 1.0
        body.contactTestBitMask = MIDIPlayerNode.Edges.All.rawValue
        body.categoryBitMask = 0
        body.collisionBitMask = MIDIPlayerNode.Edges.All.rawValue
        super.physicsBody = body
        return body
      }
      return body
    }
    set {
      guard let body = newValue else { return }
      super.physicsBody = body
    }
  }

  var edges: MIDIPlayerNode.Edges = .All {
    didSet { physicsBody.contactTestBitMask = edges.rawValue }
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
    guard state ∌ .Jogging else { fatalError("internal inconsistency, should not already have `Jogging` flag set") }
    pushBreadcrumb() // Make sure the latest position gets added to history before jogging begins
    state ⊻= .Jogging
    physicsBody.dynamic = false
  }

  /**
  didJog:

  - parameter notification: NSNotification
  */
  private func didJog(notification: NSNotification) {
    guard state ∋ .Jogging else { fatalError("internal inconsistency, should have `Jogging` flag set") }
    guard let jogTime = (notification.userInfo?[Sequencer.Notification.Key.JogTime.rawValue] as? NSValue)?.barBeatTimeValue else {
      logError("notication does not contain jog tick value")
      return
    }
    animateToSnapshot(history.snapshotForTicks(jogTime.ticks))
  }

  /**
  didEndJogging:

  - parameter notification: NSNotification
  */
  private func didEndJogging(notification: NSNotification) {
    guard state ∋ .Jogging else { fatalError("internal inconsistency, should have `Jogging` flag set") }
    state ⊻= .Jogging
    guard state ∌ .Paused else { return }
    physicsBody.dynamic = true
    physicsBody.velocity = currentSnapshot.velocity
  }

  /**
  didStart:

  - parameter notification: NSNotification
  */
  private func didStart(notification: NSNotification) {
    guard state ∋ .Paused else { return }
    logDebug("unpausing")
    physicsBody.dynamic = true
    physicsBody.velocity = currentSnapshot.velocity
    state ⊻= .Paused
  }

  /**
  didPause:

  - parameter notification: NSNotification
  */
  private func didPause(notification: NSNotification) {
    guard state ∌ .Paused else { return }
    logDebug("pausing")
    pushBreadcrumb()
    physicsBody.dynamic = false
    state ⊻= .Paused
  }

  // MARK: Snapshots

  typealias Snapshot = MIDINodeHistory.Snapshot

  /// Holds the nodes breadcrumbs to use in jogging calculations
  private var history: MIDINodeHistory

  /// The breadcrumb currently referenced in jogging calculations
  private var breadcrumb: MIDINodeHistory.Breadcrumb?

  /// Snapshot of the initial placement and velocity for the node
  var initialSnapshot: Snapshot

  /// Snapshot of the current placement and velocity for the node
  private var currentSnapshot: Snapshot

  /** Updates `currentSnapshot`, adding a new breadcrumb to `history` from the old value to the new value */
  func pushBreadcrumb() {
    guard state ∌ .Jogging else { logWarning("node has `Jogging` flag set, ignoring request to mark"); return }
    let snapshot = Snapshot(ticks: Sequencer.time.ticks, position: position, velocity: physicsBody.velocity)
    guard snapshot.ticks > currentSnapshot.ticks else { return }
    history.append(from: currentSnapshot, to: snapshot)
    currentSnapshot = snapshot
  }

  /**
  Animates the node to the location specified by the specified snapshot

  - parameter snapshot: Snapshot
  */
  private func animateToSnapshot(snapshot: Snapshot) {
    let from = currentSnapshot.ticks, to = snapshot.ticks, 𝝙ticks = Double(max(from, to) - min(from, to))
    let 𝝙seconds = Sequencer.secondsPerTick * 𝝙ticks
    runAction(SKAction.moveTo(snapshot.position, duration: 𝝙seconds))
    currentSnapshot = snapshot
  }

  // MARK: Initialization

  private static var textureCache: [TrackColor:(texture: SKTexture, normalMap: SKTexture)] = [:]
  private static func texturesForColor(color: TrackColor) -> (texture: SKTexture, normalMap: SKTexture) {
    if let tuple = textureCache[color] { return tuple }
    else {
      let texture = SKTexture(image: UIImage(named: "ball")!.imageWithColor(color.value))
      let normalMap = texture.textureByGeneratingNormalMap()
      let tuple = (texture, normalMap)
      textureCache[color] = tuple
      return tuple
    }
  }

  /**
  init:placement:instrument:note:

  - parameter t: TextureType
  - parameter p: Placement
  - parameter tr: Track
  - parameter n: Note
  */
  init(placement: Placement,
       name: String,
       track: InstrumentTrack,
       note: MIDINoteGenerator) throws
  {

    let snapshot = Snapshot(ticks: Sequencer.time.ticks, placement: placement)
    initialSnapshot = snapshot
    currentSnapshot = snapshot
    self.track = track
    history = MIDINodeHistory(initialSnapshot: snapshot)
    noteGenerator = note
    let (texture, normalMap) = MIDINode.texturesForColor(track.color)

    super.init(texture: texture, color: track.color.value, size: texture.size() * 0.75)

    let object = Sequencer.self
    typealias Notification = Sequencer.Notification

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

    try MIDIClientCreateWithBlock(name, &client, nil) ➤ "Failed to create midi client"
    try MIDISourceCreate(client, "\(name)", &endPoint) ➤ "Failed to create end point for node \(name)"

    self.name = name
    colorBlendFactor = 0

    position = placement.position
    physicsBody.velocity = placement.vector
    normalTexture = normalMap
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  
  deinit {
    do {
      logDebug("disposing of MIDI client and end point")
      try MIDIEndpointDispose(endPoint) ➤ "Failed to dispose of end point"
      try MIDIClientDispose(client) ➤ "Failed to dispose of midi client"
    } catch { logError(error) }
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

    enum Key: String { case Play, FadeOut, FadeOutAndRemove, FadeIn }

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
        case .Play:
          let halfDuration = half(node?.noteGenerator.duration.seconds ?? 0)
          let scaleUp = SKAction.scaleTo(2, duration: halfDuration)
          let noteOn = SKAction.runBlock({ [weak node] in node?.sendNoteOn() })
          let scaleDown = SKAction.scaleTo(1, duration: halfDuration)
          let noteOff = SKAction.runBlock({ [weak node] in node?.sendNoteOff() })
          action = SKAction.sequence([SKAction.group([scaleUp, noteOn]), scaleDown, noteOff])

        case .FadeOut:
          let fade = SKAction.fadeOutWithDuration(0.25)
          let pause = SKAction.runBlock({[weak node] in node?.physicsBody.resting = true})
          action = SKAction.sequence([fade, pause])

        case .FadeOutAndRemove:
          let fade = SKAction.fadeOutWithDuration(0.25)
          let remove = SKAction.removeFromParent()
          action = SKAction.sequence([fade, remove])

        case .FadeIn:
          let fade = SKAction.fadeInWithDuration(0.25)
          let unpause = SKAction.runBlock({[weak node] in node?.physicsBody.resting = false})
          action = SKAction.sequence([fade, unpause])
      }

    }

  }
}