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
    case Brick, Cobblestone, Concrete, Crusty, DiamondPlate, Dirt, Fur, Glass, Mountains, OceanBasin, Parchment,
         PlasticWrap, Sand, Stucco, Water

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

    var texture: SKTexture { return BallType.ballTextureWithName(assetName)! }
  }

  let type: BallType

  /**
  initWithBallType:

  - parameter ballType: BallType
  */
  init(_ ballType: BallType, _ vector: CGVector) {
    type = ballType
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
    physicsBody?.categoryBitMask = 0

  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }

}
