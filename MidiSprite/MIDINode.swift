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

class MIDINode: SKSpriteNode {

  enum TextureType: String, EnumerableType {
    case Brick, Cobblestone, Concrete, Crusty, DiamondPlate, Dirt, Fur,
         Mountains, OceanBasin, Parchment, Sand, Stucco
    var image: UIImage { return UIImage(named: "\(rawValue.lowercaseString)-button")! }
    var texture: SKTexture { return TextureType.atlas.textureNamed(rawValue.lowercaseString) }
    static let atlas = SKTextureAtlas(named: "balls")
    static let allCases: [TextureType] = [.Brick, .Cobblestone, .Concrete, .Crusty, .DiamondPlate, .Dirt, .Fur,
                                          .Mountains, .OceanBasin, .Parchment, .Sand, .Stucco]
  }

  static var templateNote = Note()
  static var templateTextureType = TextureType.Cobblestone

  var textureType: TextureType

  static var defaultSize = CGSize(square: 32)

  typealias Note = Instrument.Note

  var note: Note

  var track: InstrumentTrack

  struct Placement { let position: CGPoint; let vector: CGVector }

  var placement: Placement

  let id = nonce()

  enum Actions: String { case Play }

  /** play */
  func play() {
    if let _ = actionForKey(Actions.Play.rawValue) {
      do { try track.instrument.stopNoteForNode(self) } catch { logError(error) }
      removeActionForKey(Actions.Play.rawValue)
    }
    let halfDuration = note.duration * 0.5
    let scaleUp = SKAction.scaleTo(2, duration: halfDuration)
    let noteOn = SKAction.runBlock({
      [weak self] in

        do {
          try self?.track.instrument.playNoteForNode(self!)
        } catch {
          logError(error)
        }
    })
    let scaleDown = SKAction.scaleTo(1, duration: halfDuration)
    let noteOff = SKAction.runBlock({
      [weak self] in

        do {
          try self?.track.instrument.stopNoteForNode(self!)
        } catch {
          logError(error)
        }
    })
    let sequence = SKAction.sequence([SKAction.group([scaleUp, noteOn]), scaleDown, noteOff])
    runAction(sequence, withKey: Actions.Play.rawValue)
  }



  /**
  init:placement:instrument:note:

  - parameter t: TextureType
  - parameter p: Placement
  - parameter tr: InstrumentTrack
  - parameter n: Note
  */
  init(texture t: TextureType, placement p: Placement, track tr: InstrumentTrack, note n: Note) {
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
