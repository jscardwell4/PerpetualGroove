//
//  BallScene.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import SpriteKit
import CoreImage
import MoonKit
import Chameleon
import AVFoundation

class BallScene: SKScene {

  weak var ballContainer: BallContainer!

  static let defaultBackgroundColor = UIColor(red: 0.202, green: 0.192, blue: 0.192, alpha: 1.0)

  private var contentCreated = false

  /** revert */
  func revert() { ballContainer.dropBall() }

  /** createContent */
  private func createContent() {
    scaleMode = .AspectFit

    let w = frame.width - 20
    let containerRect = CGRect(x: 10, y: frame.midY - w * 0.5, width: w, height: w)
//    var containerRect = frame.rectByInsetting(dx: 20, dy: 104).integerRect
//    containerRect.origin.y += 16

    let ballContainer = BallContainer(rect: containerRect)
    ballContainer.name = "ballContainer"
    physicsWorld.contactDelegate = ballContainer
    addChild(ballContainer)
    self.ballContainer = ballContainer

  }

  private func sliders() {}

  private func audio() {}

  private func piano() {}

  private func guitar() {}

  private func play() {}

  private func stop() {}

  private func pause() {}

  private func skipBack() {}

  /**
  didMoveToView:

  - parameter view: SKView
  */
  override func didMoveToView(view: SKView) {
    guard !contentCreated else { return }
    createContent()
    contentCreated = true
  }


  /** dumpNodeTree */
  func dumpNodeTree() {
    func nodeDescription(node: SKNode) -> String {
      return "{name: \(node.name!); frame: \(node.frame); position: \(node.position); physicsBody: \(node.physicsBody)}"
    }
    let nodeDescriptions = children.map { nodeDescription($0) }
    MSLogDebug("scene frame: \(frame)\nballs: {\n\t" + "\n\t".join(nodeDescriptions) + "\n}")
  }

  /**
  update:

  - parameter currentTime: CFTimeInterval
  */
//  override func update(currentTime: CFTimeInterval) {
//    /* Called before each frame is rendered */
//  }
}
