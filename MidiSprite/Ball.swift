//
//  Ball.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/6/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

class Ball: SKSpriteNode {

  static let ballsAtlas = SKTextureAtlas(named: "balls")
  
  enum BallType: String {
    case Brick, Cobblestone, Concrete, Crusty, DiamondPlate, Dirt, Fur, Glass,
         Mountains, OceanBasin, Parchment, PlasticWrap, Sand, Stucco, Water

    /**
    ballTextureWithName:

    - parameter name: String

    - returns: SKTexture?
    */
    static func ballTextureWithName(name: String) -> SKTexture? {
      guard ballsAtlas.textureNames ∋ name else { return nil }
      return ballsAtlas.textureNamed(name)
    }

    var assetName: String { return rawValue.lowercaseString }
    var image: UIImage { return UIImage(named: assetName)! }

    var texture: SKTexture { return BallType.ballTextureWithName(assetName)! }
    static let all: [BallType] = [.Brick, .Cobblestone, .Concrete, .Crusty, .DiamondPlate, .Dirt, .Fur, .Glass,
                                  .Mountains, .OceanBasin, .Parchment, .PlasticWrap, .Sand, .Stucco, .Water]
  }

  var type: BallType
  var note: Instrument.Note
  var instrument: Instrument

  /**
  initWithBallType:

  - parameter ballType: BallType
  */
  init(ballType: BallType, vector: CGVector, instrument i: Instrument, note n: Instrument.Note) {
    type = ballType
    instrument = i
    note = n
    let texture = ballType.texture
    super.init(texture: texture, color: UIColor.clearColor(), size: CGSize(square: 32))
    physicsBody = SKPhysicsBody(circleOfRadius: size.width * 0.5)
    physicsBody?.affectedByGravity = false
    physicsBody?.usesPreciseCollisionDetection = true
    physicsBody?.velocity = vector
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
