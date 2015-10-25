//
//  MIDINode.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/12/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit
import CoreMIDI

final class MIDINode: SKSpriteNode {


// MARK: - Monitoring node state

  struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    static let Playing = State(rawValue: 0b001)
    static let Jogging = State(rawValue: 0b010)
    static let Paused  = State(rawValue: 0b100)

    var description: String {
      var result = "MIDINode.State { "
      var flagStrings: [String] = []
      if self ∋ .Playing { flagStrings.append("Playing") }
      if self ∋ .Jogging { flagStrings.append("Jogging") }
      if self ∋ .Paused  { flagStrings.append("Paused")  }
      result += ", ".join(flagStrings)
      result += " }"
      return result
    }
  }

  /// Holds the current state of the node
  private var state: State = []

  // MARK: - Generating MIDI note events

  private var client = MIDIClientRef()
  private(set) var endPoint = MIDIEndpointRef()

  /// Holds the octave, pitch, velocity and duration to use when generating MIDI events
  var note: NoteAttributes {
    didSet {
      guard oldValue.duration != note.duration else { return }
      playAction = Action(key: .Play, node: self)
    }
  }

  /// Whether a note is ended via a note on event with velocity of 0 or with a  note off event
  static let useVelocityForOff = true

  typealias Identifier = UInt64
  private var _sourceID: Identifier = 0

  /// Embedded in MIDI packets to allow a track with multiple nodes to identify the event's source
  var sourceID: Identifier { return _sourceID }

  /// Type for representing MIDI-related node actions
  struct Action {

    enum Key: String { case Play, FadeOut, FadeIn }

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
          let halfDuration = half(node?.note.duration.seconds ?? 0)
          let scaleUp = SKAction.scaleTo(2, duration: halfDuration)
          let noteOn = SKAction.runBlock({ [weak node] in node?.sendNoteOn() })
          let scaleDown = SKAction.scaleTo(1, duration: halfDuration)
          let noteOff = SKAction.runBlock({ [weak node] in node?.sendNoteOff() })
          action = SKAction.sequence([SKAction.group([scaleUp, noteOn]), scaleDown, noteOff])

        case .FadeOut:
          let fade = SKAction.fadeOutWithDuration(0.25)
          let pause = SKAction.runBlock({[weak node] in node?.physicsBody.resting = true})
          action = SKAction.sequence([fade, pause])

        case .FadeIn:
          let fade = SKAction.fadeInWithDuration(0.25)
          let unpause = SKAction.runBlock({[weak node] in node?.physicsBody.resting = false})
          action = SKAction.sequence([fade, unpause])
      }

    }

  }

  private lazy var playAction:    Action = Action(key: .Play,    node: self)
  private lazy var fadeOutAction: Action = Action(key: .FadeOut, node: self)
  private lazy var fadeInAction:  Action = Action(key: .FadeIn,  node: self)

  /**
  runAction:

  - parameter action: Action
  */
  private func runAction(action: Action) { runAction(action.action, withKey: action.key) }

  /** play */
  func play() { runAction(playAction)  }

  /** fadeOut */
  func fadeOut() { runAction(fadeOutAction) }

  /** fadeIn */
  func fadeIn() { runAction(fadeInAction) }

  /** sendNoteOn */
  func sendNoteOn() {
    var packetList = MIDIPacketList()
    let packet = MIDIPacketListInit(&packetList)
    let size = sizeof(UInt32.self) + sizeof(MIDIPacket.self)
    let data: [Byte] = [0x90 | note.channel, note.note.midi, note.velocity.midi] + _sourceID.bytes
    logVerbose("data: \(String(hexBytes: data))")
    let timeStamp = BarBeatTime.ticks
    MIDIPacketListAdd(&packetList, size, packet, timeStamp, 11, data)
    do {
      try withUnsafePointer(&packetList) { MIDIReceived(endPoint, $0) } ➤ "Unable to send note on event"
      state ⊻= .Playing
    } catch { logError(error) }
  }

  /** sendNoteOff */
  func sendNoteOff() {
    guard state ∋ .Playing else { return }
    var packetList = MIDIPacketList()
    let packet = MIDIPacketListInit(&packetList)
    let size = sizeof(UInt32.self) + sizeof(MIDIPacket.self)
    let data: [UInt8] = MIDINode.useVelocityForOff
                ? [0x90 | note.channel, note.note.midi, 0] + _sourceID.bytes
                : [0x80 | note.channel, note.note.midi, 0] + _sourceID.bytes
    logVerbose("data: \(String(hexBytes: data))")
    let timeStamp = BarBeatTime.ticks
    MIDIPacketListAdd(&packetList, size, packet, timeStamp, 11, data)
    do {
      try withUnsafePointer(&packetList) { MIDIReceived(endPoint, $0) } ➤ "Unable to send note off event"
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

  private weak var track: InstrumentTrack?  { didSet { if track == nil && parent != nil { removeFromParent() } } }

  override var physicsBody: SKPhysicsBody! {
    get {
      guard let body = super.physicsBody else {
        let body = SKPhysicsBody(circleOfRadius: size.width * 0.5)
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

  // MARK: - Listening for Sequencer notifications

  private let receptionist = NotificationReceptionist()

  /**
  didBeginJogging:

  - parameter notification: NSNotification
  */
  private func didBeginJogging(notification: NSNotification) {

    logVerbose("<\(_sourceID)>")

    // Make sure we are not already jogging
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
    logVerbose("<\(_sourceID)>")
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
    logVerbose("<\(_sourceID)>")

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
    logVerbose("<\(_sourceID)>")
    guard state ∋ .Paused else { return }
    physicsBody.dynamic = true
    physicsBody.velocity = currentSnapshot.velocity
    state ⊻= .Paused
  }

  /**
  didPause:

  - parameter notification: NSNotification
  */
  private func didPause(notification: NSNotification) {
    logVerbose("<\(_sourceID)>")
    guard state ∌ .Paused else { return }
    pushBreadcrumb()
    physicsBody.dynamic = false
    state ⊻= .Paused
  }

  // MARK: - Snapshots

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
    let snapshot = Snapshot(ticks: BarBeatTime.ticks, position: position, velocity: physicsBody.velocity)
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

  // MARK: - Initialization

  /**
  init:placement:instrument:note:

  - parameter t: TextureType
  - parameter p: Placement
  - parameter tr: Track
  - parameter n: Note
  */
  init(placement p: Placement, name n: String, track t: InstrumentTrack, note attrs: NoteAttributes) throws {

    let snapshot = Snapshot(ticks: BarBeatTime.ticks, placement: p)
    initialSnapshot = snapshot
    currentSnapshot = snapshot
    track = t
    history = MIDINodeHistory(initialSnapshot: snapshot)
    note = attrs
    let image = UIImage(named: "ball")!
    super.init(texture: SKTexture(image: image), color: t.color.value, size: image.size * 0.75)

    let queue = NSOperationQueue.mainQueue()
    let object = Sequencer.self
    typealias Notification = Sequencer.Notification
    receptionist.logContext = LogManager.SceneContext
    receptionist.observe(Notification.DidBeginJogging, from: object, queue: queue) { [weak self] in self?.didBeginJogging($0) }
    receptionist.observe(Notification.DidJog,          from: object, queue: queue) { [weak self] in self?.didJog($0) }
    receptionist.observe(Notification.DidEndJogging,   from: object, queue: queue) { [weak self] in self?.didEndJogging($0) }
    receptionist.observe(Notification.DidStart,        from: object, queue: queue) { [weak self] in self?.didStart($0) }
    receptionist.observe(Notification.DidPause,        from: object, queue: queue) { [weak self] in self?.didPause($0) }

    _sourceID = Identifier(ObjectIdentifier(self).uintValue)

    try MIDIClientCreateWithBlock(n, &client, nil) ➤ "Failed to create midi client"
    try MIDISourceCreate(client, "\(n)", &endPoint) ➤ "Failed to create end point for node \(n)"

    name = n
    colorBlendFactor = 1

    position = p.position
    physicsBody.affectedByGravity = false
    physicsBody.usesPreciseCollisionDetection = true
    physicsBody.velocity = p.vector
    physicsBody.linearDamping = 0.0
    physicsBody.angularDamping = 0.0
    physicsBody.friction = 0.0
    physicsBody.restitution = 1.0
    physicsBody.contactTestBitMask = 0xFFFFFFFF
    physicsBody.categoryBitMask = 0
    physicsBody.collisionBitMask = 1
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  
  deinit {
    do {
      try MIDIEndpointDispose(endPoint) ➤ "Failed to dispose of end point"
      try MIDIClientDispose(client) ➤ "Failed to dispose of midi client"
    } catch { logError(error) }
  }

}
