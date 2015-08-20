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
import struct AudioToolbox.MIDINoteMessage

final class MIDINode: SKSpriteNode {

  // MARK: - Type to specify the node's texture
  enum TextureType: String, EnumerableType {
    case Brick, Cobblestone, Concrete, Crusty, DiamondPlate, Dirt, Fur,
         Mountains, OceanBasin, Parchment, Sand, Stucco
    var image: UIImage { return UIImage(named: "\(rawValue.lowercaseString)-button")! }
    var texture: SKTexture { return TextureType.atlas.textureNamed(rawValue.lowercaseString) }
    static let atlas = SKTextureAtlas(named: "balls")
    static let allCases: [TextureType] = [.Brick, .Cobblestone, .Concrete, .Crusty, .DiamondPlate, .Dirt, .Fur,
                                          .Mountains, .OceanBasin, .Parchment, .Sand, .Stucco]
  }

  // MARK: - Properties used to initialize a new `MIDINode`
  static var currentNote = Note(channel: 0, note: 60, velocity: 64, releaseVelocity: 54, duration: 0.25)
  static var currentTexture = TextureType.Cobblestone

  // MARK: - Properties relating to the node's appearance

  var textureType: TextureType

  static var defaultSize = CGSize(square: 32)

  // MARK: -  Properties affecting what is played by the node

  typealias Note = MIDINoteMessage

  var note: Note

  struct Placement { let position: CGPoint; let vector: CGVector }

  var placement: Placement

  let id = nonce()

  // MARK: - Methods for playing/erasing the node

  enum Actions: String { case Play }

  /** play */
  func play() {
    let halfDuration = Double(note.duration * 0.5)
    let scaleUp = SKAction.scaleTo(2, duration: halfDuration)
    let noteOn = SKAction.runBlock({ [weak self] in self?.sendNoteOn() })
    let scaleDown = SKAction.scaleTo(1, duration: halfDuration)
    let noteOff = SKAction.runBlock({ [weak self] in self?.sendNoteOff() })
    let sequence = SKAction.sequence([SKAction.group([scaleUp, noteOn]), scaleDown, noteOff])
    runAction(sequence, withKey: Actions.Play.rawValue)
  }

  /** erase */
  private func erase() {

  }

  private func sendNoteOn() {
    var packetList = MIDIPacketList()
    let packet = MIDIPacketListInit(&packetList)
    packet.memory.timeStamp = TrackManager.currentTime
    packet.memory.data.0 = 0b10010000 | note.channel
    packet.memory.data.1 = note.note
    packet.memory.data.2 = note.velocity
    packet.memory.length = 3
    do { try withUnsafePointer(&packetList) {MIDISend(outPort, destination, $0) } ➤ "Unable to send note on event" }
    catch { logError(error) }
  }

  /** sendNoteOn */
  private func sendNoteOff() {
    var packetList = MIDIPacketList()
    let packet = MIDIPacketListInit(&packetList)
    packet.memory.timeStamp = TrackManager.currentTime
    packet.memory.data.0 = 0b10000000 | note.channel
    packet.memory.data.1 = note.note
    packet.memory.data.2 = note.velocity
    packet.memory.length = 3
    do { try withUnsafePointer(&packetList) {MIDISend(outPort, destination, $0) } ➤ "Unable to send note on event" }
    catch { logError(error) }
  }

  /** removeFromParent */
  override func removeFromParent() { erase(); super.removeFromParent() }

  private var client = MIDIClientRef()
  private var outPort = MIDIPortRef()
  private let destination: MIDIEndpointRef


  // MARK: - Initialization

  /**
  init:placement:instrument:note:

  - parameter t: TextureType
  - parameter p: Placement
  - parameter tr: Track
  - parameter n: Note
  */
  init(_ p: Placement, _ name: String) throws {
    placement = p
    textureType = MIDINode.currentTexture
    destination = TrackManager.currentTrack.inPort
    note = MIDINode.currentNote
    super.init(texture: MIDINode.currentTexture.texture,
               color: TrackManager.currentTrack.color.value,
               size: MIDINode.defaultSize)

    try MIDIClientCreateWithBlock(name, &client, nil) ➤ "Failed to create midi client"
    try MIDIOutputPortCreate(client, "Output", &outPort) ➤ "Failed to create out port"

    self.name = name
    colorBlendFactor = 1

    position = placement.position
    physicsBody = SKPhysicsBody(circleOfRadius: size.width * 0.5)
    physicsBody?.affectedByGravity = false
    physicsBody?.usesPreciseCollisionDetection = true
    physicsBody?.velocity = placement.vector
    physicsBody?.linearDamping = 0.0
    physicsBody?.angularDamping = 0.0
    physicsBody?.friction = 0.0
    physicsBody?.restitution = 1.0
    physicsBody?.contactTestBitMask = 0xFFFFFFFF
    physicsBody?.categoryBitMask = 0
    physicsBody?.collisionBitMask = 1
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}
