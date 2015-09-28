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

  var initialPlacement: Placement

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

  var placement: Placement { didSet { position = placement.position; physicsBody.velocity = placement.vector } }


//  private var velocity: CGVector = .zero
  private var currentSnapshot: Snapshot {
    return Snapshot(ticks: time.time.ticks, position: position, velocity: physicsBody.velocity)
  }
  private var lastSnapshot: Snapshot
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
  jogBackward:_:

  - parameter from: MIDITimeStamp
  - parameter to: MIDITimeStamp
  */
  private func jogFrom(fromTicks: MIDITimeStamp, to toTicks: MIDITimeStamp, using crumb: MIDINodeHistory.Breadcrumb) {

//    guard to < from else { logError("cannot jog backward from \(from) to \(to)"); return }
//
//    if breadcrumb == nil { breadcrumb = history.breadcrumbForTicks(from, forward: false) }
//
//    if let breadcrumbStart = breadcrumb?.tickInterval.start where breadcrumbStart > to {
//      jogBackward(from, breadcrumbStart)
//      breadcrumb = history.breadcrumbForTicks(breadcrumbStart, forward: false)
//    }
//
//    // Get the relevant breadcrumb for jogging
//    guard let breadcrumb = breadcrumb else { fatalError("failed to retrieve breadcrumb for ticks = \(from)") }
//
//    guard let positionʹ = breadcrumb.positionForTicks(to) else { logError("failed to get position for ticks = \(to)"); return }
//    position = positionʹ
//
//    backgroundDispatch { [time = time.time] in
//      var string = "time: \(time)\n"
//      string += "from: \(from); to: \(to)\n"
//      string += "breadcrumb: \(breadcrumb)\n"
//      string += "positionʹ: \(positionʹ)"
//      logDebug(string)
//    }


  }

  /**
  jogForward:_:

  - parameter from: MIDITimeStamp
  - parameter to: MIDITimeStamp
  */
  private func jogForward(from: MIDITimeStamp, _ to: MIDITimeStamp) {
/*
    guard to > from else { logError("cannot jog forward from \(from) to \(to)"); return }

    // Get the relevant breadcrumb for jogging
    guard let breadcrumb = history.breadcrumbForTicks(to, forward: true) else { return }

    let 𝝙ticks  = breadcrumb.ticks - from,
        𝝙ticksʹ = breadcrumb.ticks - to

    let 𝝙position = position - breadcrumb.to

    let secondsPerTick = CGFloat(Sequencer.secondsPerBeat / Double(Sequencer.resolution))

    let 𝝙seconds  = secondsPerTick * CGFloat(𝝙ticks), // Seconds elapsed from breadcrumb to current position
        𝝙secondsʹ = secondsPerTick * CGFloat(𝝙ticksʹ) // Seconds elapsed from breadcrumb to target position

    let velocity = breadcrumb.velocity
    let 𝝙meters  = velocity * 𝝙seconds
    let 𝝙metersʹ = velocity * 𝝙secondsʹ

    let positionʹ = breadcrumb.to + (𝝙metersʹ * (𝝙position / 𝝙meters))

    position = positionʹ

    backgroundDispatch { [time = time.time] in
      var string = "time: \(time)\n"
      string += "from: \(from); to: \(to)\n"
      string += "breadcrumb: \(breadcrumb)\n"
      string += "𝝙ticks: \(𝝙ticks); 𝝙ticksʹ: \(𝝙ticksʹ)\n"
      string += "𝝙position: (\(𝝙position.x.rounded(3)), \(𝝙position.y.rounded(3)))\n"
      string += "secondsPerTick: \(secondsPerTick)\n"
      string += "𝝙seconds: \(𝝙seconds.rounded(3)); 𝝙secondsʹ: \(𝝙secondsʹ.rounded(3))\n"
      string += "velocity: (\(velocity.dx.rounded(3)), \(velocity.dy.rounded(3)))\n"
      string += "𝝙meters: (\(𝝙meters.dx.rounded(3)), \(𝝙meters.dy.rounded(3)))\n"
      string += "𝝙metersʹ: (\(𝝙metersʹ.dx.rounded(3)), \(𝝙metersʹ.dy.rounded(3)))\n"
      string += "positionʹ: (\(positionʹ.x.rounded(3)), \(positionʹ.y.rounded(3)))"
      logDebug(string)
    }
*/
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
    logDebug("ticks: \(time.time.ticks); postion: \(position.description(3))")
  }

  /**
  didJog:

  - parameter notification: NSNotification
  */
  private func didJog(notification: NSNotification) {
    placement = history.placementForTicks(time.ticks, fromTicks: Sequencer.jogStartTimeTicks)
//    if let breadcrumb = breadcrumb {
//
//    }
//
//    switch (Sequencer.jogStartTimeTicks, time.timeStamp) {
//      case let (start, end) where start > end:
//
//        jogFrom(start, to: end, using: history.breadcrumbForTicks(<#T##ticks: MIDITimeStamp##MIDITimeStamp#>, forward: <#T##Bool#>))
//      case let (from, to) where from < to:
//        jogForward(from, to)
//      default:
//        break
//    }
  }

  /**
  didEndJogging:

  - parameter notification: NSNotification
  */
  private func didEndJogging(notification: NSNotification) {
    guard state ∋ .Jogging else { fatalError("internal inconsistency, should have `Jogging` flag set") }
    physicsBody.dynamic = true
    physicsBody.velocity = placement.vector
    state ⊻= .Jogging
    lastSnapshot = currentSnapshot
    history.pruneAfter(lastSnapshot)

    logDebug("\n".join(
      "time: \(time.time.debugDescription)",
      "postion: \(position)",
      "history: \(history)"
    ))
  }

  private var notificationReceptionist: NotificationReceptionist!

  /** mark */
  func mark() {
    guard state ∌ .Jogging else { logWarning("node has `Jogging` flag set, ignoring request to mark"); return }
    let currentSnapshot = Snapshot(ticks: time.ticks,
                                   position: position,
                                   velocity: physicsBody!.velocity)
//    if history.isEmpty { history.append(from: history.initialSnapshot, to: lastSnapshot) }
    history.append(from: lastSnapshot, to: currentSnapshot)
    lastSnapshot = currentSnapshot
  }

  /**
  init:placement:instrument:note:

  - parameter t: TextureType
  - parameter p: Placement
  - parameter tr: Track
  - parameter n: Note
  */
  init(placement p: Placement, name n: String, track t: InstrumentTrack, note attrs: NoteAttributes) throws {

    initialPlacement = p
    placement = p
    note = attrs
    let snapshot = Snapshot(ticks: Sequencer.time.ticks,
                            position: p.position,
                            velocity: p.vector)
    lastSnapshot = snapshot
    history = MIDINodeHistory(initialSnapshot: snapshot)
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

    position = initialPlacement.position
//    physicsBody = SKPhysicsBody(circleOfRadius: size.width * 0.5)
    physicsBody.affectedByGravity = false
    physicsBody.usesPreciseCollisionDetection = true
    physicsBody.velocity = initialPlacement.vector
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
