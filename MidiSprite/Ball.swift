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

  static let ballTextures = SKTextureAtlas(named: "ball")
  
  enum BallType {
    case Concrete, Crusty, Ocean, Sand, Water

    static let ConcreteTexture = Ball.ballTextures.textureNamed("ball_concrete")
    static let CrustyTexture   = Ball.ballTextures.textureNamed("ball_crusty")
    static let OceanTexture    = Ball.ballTextures.textureNamed("ball_ocean")
    static let SandTexture     = Ball.ballTextures.textureNamed("ball_sand")
    static let WaterTexture    = Ball.ballTextures.textureNamed("ball_water")

    var texture: SKTexture {
      switch self {
        case .Concrete: return BallType.ConcreteTexture
        case .Crusty:   return BallType.CrustyTexture
        case .Ocean:    return BallType.OceanTexture
        case .Sand:     return BallType.SandTexture
        case .Water:    return BallType.WaterTexture
      }
    }
  }

  let type: BallType

  /**
  initWithBallType:

  - parameter ballType: BallType
  */
  init(_ ballType: BallType, _ vector: CGVector) {
    type = ballType
    let texture = ballType.texture
    super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
    physicsBody = SKPhysicsBody(circleOfRadius: size.width * 0.5)
    physicsBody?.affectedByGravity = false
    physicsBody?.usesPreciseCollisionDetection = true
    physicsBody?.velocity = vector
    physicsBody?.linearDamping = 0.0
    physicsBody?.angularDamping = 0.0
    physicsBody?.friction = 0.0
    physicsBody?.restitution = 1.0
    physicsBody?.categoryBitMask = 0
//    physicsBody?.applyForce(vector)
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }

}
