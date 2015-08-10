//
//  ButtonNode.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/6/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

public class ButtonNode: ControlNode {

  public struct TexturePair {
    public let defaultTexture: SKTexture
    public let pressedTexture: SKTexture
    public init(defaultTexture d: SKTexture, pressedTexture p: SKTexture) { defaultTexture = d; pressedTexture = p }
  }

  public enum Textures {
    case Default (TexturePair)
    case Dim (TexturePair)
  }

  private let minimumPressDuration = 0.1

  private var pressed = false { didSet { guard pressed != oldValue else { return }; updateTexture() } }

  /** updateTexture */
  func updateTexture() {
    let action: SKAction?
    switch (pressed, dim) {
      case (true, true):   action = pressedDimAction
      case (true, false):  action = pressedAction
      case (false, true):  action = unpressedDimAction
      case (false, false): action = unpressedAction
    }
    if action != nil { sprite.runAction(action!) }
  }

  public var color: UIColor { get { return sprite.color } set { sprite.color = newValue } }

  public var colorBlendFactor: CGFloat { get { return sprite.colorBlendFactor } set { sprite.colorBlendFactor = newValue } }

  private var pressedAction: SKAction? {
    guard let texture = defaultTextures?.pressedTexture else { return nil }
    return SKAction.setTexture(texture)
  }

  private var unpressedAction: SKAction? {
    guard let texture = defaultTextures?.defaultTexture else { return nil }
    return SKAction.setTexture(texture)
  }

  private var pressedDimAction: SKAction? {
    guard let texture = dimTextures?.pressedTexture else { return pressedAction }
    return SKAction.setTexture(texture)
  }

  private var unpressedDimAction: SKAction? {
    guard let texture = dimTextures?.defaultTexture else { return unpressedAction }
    return SKAction.setTexture(texture)
  }

  public var defaultTextures: TexturePair? {
    didSet {
      guard let textures = defaultTextures else { return }
      SKTexture.preloadTextures([textures.defaultTexture, textures.pressedTexture], withCompletionHandler: {})
    }
  }

  public var dimTextures: TexturePair? {
    didSet {
      guard let textures = dimTextures else { return }
      SKTexture.preloadTextures([textures.defaultTexture, textures.pressedTexture], withCompletionHandler: {})
    }
  }

//  public var defaultTexture: SKTexture? { didSet { defaultTexture?.preloadWithCompletionHandler({}) } }
//  public var pressedTexture: SKTexture? { didSet { pressedTexture?.preloadWithCompletionHandler({}) } }

//  public var defaultDimTexture: SKTexture? { didSet { defaultDimTexture?.preloadWithCompletionHandler({}) } }
//  public var pressedDimTexture: SKTexture? { didSet { pressedDimTexture?.preloadWithCompletionHandler({}) } }

  private var touch: UITouch? { didSet { touchTime = touch?.timestamp ?? 0 } }
  private var touchTime = 0.0

  public let sprite = SKSpriteNode()

  public override var enabled: Bool { didSet { sprite.colorBlendFactor = enabled ? 0 : 1 } }

  public override var size: CGSize { get { return sprite.size } set { sprite.size = newValue } }

  public var anchorPoint: CGPoint { get { return sprite.anchorPoint } set { sprite.anchorPoint = newValue } }

  /**
  initWithTextures:action:

  - parameter textures: [Texture]? = nil
  - parameter a: ControlNodeAction?
  */
  public init(textures: [Textures]? = nil, action a: ControlNodeAction?) {
    super.init(action: a)

    userInteractionEnabled = true

    for texturePair in textures ?? [] {
      switch texturePair {
        case .Default (let t): defaultTextures = t
        case .Dim (let t):     dimTextures = t
      }
    }

    sprite.name = "buttonSprite"
    sprite.texture = defaultTextures?.defaultTexture
    sprite.color = UIColor.whiteColor()
    sprite.size = defaultTextures?.defaultTexture.size() ?? CGSize.zeroSize
    sprite.colorBlendFactor = 1.0
    addChild(sprite)

  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

  /**
  touchesBegan:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard enabled, let firstTouch = touches.first else { return }
    if sprite.containsPoint(firstTouch.locationInNode(self)) { pressed = true; touch = firstTouch }
    else { super.touchesBegan(touches, withEvent: event) }
  }

  /**
  touchesCancelled:withEvent:

  - parameter touches: Set<UITouch>?
  - parameter event: UIEvent?
  */
  public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    if let touch = touch where touches?.contains(touch) == true { pressed = false; self.touch = nil }
    else if enabled { super.touchesCancelled(touches, withEvent: event) }
  }

  /**
  touchesEnded:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let touch = touch where touches.contains(touch) {
      // process touch
      if sprite.containsPoint(touch.locationInNode(self)) {
        // invoke action since touch ended in bounds

        let waitTime = minimumPressDuration + touchTime - touch.timestamp
        if waitTime > 0 {
          // delayed invocation
          runAction(SKAction.waitForDuration(waitTime)) { [weak self] in self?.pressed = false; self?.invokeAction() }
        } else {
          // invoke action now
          pressed = false
          invokeAction()
        }

      } else {
        // don't invoke action since touch ended out of bounds
        pressed = false
      }
      self.touch = nil  // clear touch regardless
    } else if enabled {
      // forward to super
      super.touchesEnded(touches, withEvent: event)
    }
  }
}
