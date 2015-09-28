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
import struct AudioToolbox.CABarBeatTime

final class MIDINode: SKSpriteNode {

  typealias Snapshot = MIDINodeHistory.Snapshot
  
  var note: NoteAttributes

  var initialSnapshot: Snapshot

  static let useVelocityForOff = true

  struct State: OptionSetType {
    let rawValue: Int
    static let Playing = State(rawValue: 0b01)
    static let Jogging = State(rawValue: 0b10)
  }

  private var state: State = []

  enum Actions: String { case Play }

  /** play */
  func play() {
    let halfDuration = note.duration.seconds
    let scaleUp = SKAction.scaleTo(2, duration: halfDuration)
    let noteOn = SKAction.runBlock({ [weak self] in self?.sendNoteOn() })
    let scaleDown = SKAction.scaleTo(1, duration: halfDuration)
    let noteOff = SKAction.runBlock({ [weak self] in self?.sendNoteOff() })
    let sequence = SKAction.sequence([SKAction.group([scaleUp, noteOn]), scaleDown, noteOff])
    runAction(sequence, withKey: Actions.Play.rawValue)
  }

  typealias Identifier = UInt64

  private var _sourceID: Identifier = 0
  var sourceID: Identifier { return _sourceID }

  /** sendNoteOn */
  func sendNoteOn() {
    var packetList = MIDIPacketList()
    let packet = MIDIPacketListInit(&packetList)
    let size = sizeof(UInt32.self) + sizeof(MIDIPacket.self)
    let data: [Byte] = [0x90 | note.channel, note.note.MIDIValue, note.velocity.MIDIValue] + _sourceID.bytes
    let timeStamp = time.ticks
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
                ? [0x90 | note.channel, note.note.MIDIValue, 0] + _sourceID.bytes
                : [0x80 | note.channel, note.note.MIDIValue, 0] + _sourceID.bytes
    let timeStamp = time.ticks
    MIDIPacketListAdd(&packetList, size, packet, timeStamp, 11, data)
    do {
      try withUnsafePointer(&packetList) { MIDIReceived(endPoint, $0) } ➤ "Unable to send note off event"
      state ⊻= .Playing
    } catch { logError(error) }
  }

  /**
  removeActionForKey:

  - parameter key: String
  */
  override func removeActionForKey(key: String) {
    if actionForKey(key) != nil && Actions.Play.rawValue == key { sendNoteOff() }
    super.removeActionForKey(key)
  }

  private var client = MIDIClientRef()
  private let time = Sequencer.time
  private(set) var endPoint = MIDIEndpointRef()

  private var currentSnapshot: Snapshot
  private var history: MIDINodeHistory
  private var breadcrumb: MIDINodeHistory.Breadcrumb?

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


  /**
  didBeginJogging:

  - parameter notification: NSNotification
  */
  private func didBeginJogging(notification: NSNotification) {

    // Make sure we are not already jogging
    guard state ∌ .Jogging else { fatalError("internal inconsistency, should not already have `Jogging` flag set") }

    mark() // Make sure the latest position gets added to history before jogging begins
    state ⊻= .Jogging

    physicsBody.dynamic = false
  }

  /**
  didJog:

  - parameter notification: NSNotification
  */
  private func didJog(notification: NSNotification) {
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
    physicsBody.dynamic = true
    physicsBody.velocity = currentSnapshot.velocity
    state ⊻= .Jogging
    history.pruneAfter(currentSnapshot)
  }

  /**
  animateToSnapshot:

  - parameter snapshot: Snapshot
  */
  private func animateToSnapshot(snapshot: Snapshot) {
    let from = currentSnapshot.ticks, to = snapshot.ticks, 𝝙ticks = Double(max(from, to) - min(from, to))
    let 𝝙seconds = Sequencer.secondsPerTick * 𝝙ticks
    runAction(SKAction.moveTo(snapshot.position, duration: 𝝙seconds))
    currentSnapshot = snapshot
  }

  private var notificationReceptionist: NotificationReceptionist!

  /** mark */
  func mark() {
    guard state ∌ .Jogging else { logWarning("node has `Jogging` flag set, ignoring request to mark"); return }
    let snapshot = Snapshot(ticks: time.ticks, position: position, velocity: physicsBody.velocity)
    guard snapshot.ticks > currentSnapshot.ticks else { return }
    history.append(from: currentSnapshot, to: snapshot)
    currentSnapshot = snapshot
  }

  /**
  init:placement:instrument:note:

  - parameter t: TextureType
  - parameter p: Placement
  - parameter tr: Track
  - parameter n: Note
  */
  init(placement p: Placement, name n: String, track t: InstrumentTrack, note attrs: NoteAttributes) throws {

    let snapshot = Snapshot(ticks: Sequencer.time.ticks, placement: p)
    initialSnapshot = snapshot
    currentSnapshot = snapshot
    history = MIDINodeHistory(initialSnapshot: snapshot)
    note = attrs
    let image = UIImage(named: "ball")!
    super.init(texture: SKTexture(image: image), color: t.color.value, size: image.size * 0.75)

    let queue = NSOperationQueue.mainQueue()
    notificationReceptionist = NotificationReceptionist(callbacks:
      [
        Sequencer.Notification.DidBeginJogging.value : (Sequencer.self, queue, didBeginJogging),
        Sequencer.Notification.DidJog.value          : (Sequencer.self, queue, didJog),
        Sequencer.Notification.DidEndJogging.value   : (Sequencer.self, queue, didEndJogging)
      ]
    )

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

  deinit {
    do {
      try MIDIEndpointDispose(endPoint) ➤ "Failed to dispose of end point"
      try MIDIClientDispose(client) ➤ "Failed to dispose of midi client"
    } catch { logError(error) }
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}
