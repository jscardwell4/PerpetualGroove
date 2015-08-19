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

  var track: InstrumentTrack

  struct Placement { let position: CGPoint; let vector: CGVector }

  var placement: Placement

  let id = nonce()

  // MARK: - Methods for playing/erasing the node

  enum Actions: String { case Play }

  /** play */
  func play() {
    let halfDuration = Double(note.duration * 0.5)
    let scaleUp = SKAction.scaleTo(2, duration: halfDuration)
    let noteOn = SKAction.runBlock({ [weak self] in do { try self?.track.addNoteForNode(self!) } catch { logError(error) } })
    let scaleDown = SKAction.scaleTo(1, duration: halfDuration)
    let sequence = SKAction.sequence([SKAction.group([scaleUp, noteOn]), scaleDown])
    runAction(sequence, withKey: Actions.Play.rawValue)
  }

  /** erase */
  private func erase() {

  }

  /** removeFromParent */
  override func removeFromParent() { erase(); super.removeFromParent() }

  // MARK: - Initialization

  /**
  init:placement:instrument:note:

  - parameter t: TextureType
  - parameter p: Placement
  - parameter tr: InstrumentTrack
  - parameter n: Note
  */
  init(placement p: Placement,
       track tr: InstrumentTrack,
       texture t: TextureType = currentTexture,
       note n: Note = currentNote)
  {
    textureType = t
    placement = p
    track = tr
    note = n
    super.init(texture: t.texture, color: .clearColor(), size: MIDINode.defaultSize)
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
