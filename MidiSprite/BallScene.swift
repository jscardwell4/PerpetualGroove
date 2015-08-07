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
import Glyphish

class BallScene: SKScene {

  private weak var ballContainer: BallContainer!

  /// bright copper, lime, flat red, gold
  let colors1 = Chameleon.colorsForScheme(.Analogous, with: Chameleon.quietLightCopperDark, flat: true, unique: true)

  /// gray, lighter gray, darkish green-gray, darkish red-gray
  let colors2 = Chameleon.colorsForScheme(.Complementary, with: Chameleon.cssGray, flat: false, unique: true)

  /// grayish blue, sky blue, orange-red, pinkish red, brownish red
  let colors3 = Chameleon.colorsForScheme(.Complementary, with: Chameleon.cssOrangeRedDark, flat: true, unique: true)

  /// darkish tomato, powdery blue, gray-greenish blue, tomato, pinkish tomato
  let colors4 = Chameleon.colorsForScheme(.Complementary, with: Chameleon.cssTomatoDark, flat: false, unique: true)

  /// brown, tan, blue-greenish gray, slatish blue, darker tan
  let colors5 = Chameleon.colorsForScheme(.Complementary, with: Chameleon.cssRosyBrownDark, flat: true, unique: true)

  private var contentCreated = false

  func revert() {
    ballContainer.dropBall()
  }

  /** createContent */
  private func createContent() {

    backgroundColor = colors2[3]
    scaleMode = .ResizeFill

    let containerRect = frame.rectByInsetting(dx: 20, dy: 88).integerRect

    let ballContainer = BallContainer(rect: containerRect)
    ballContainer.name = "ballContainer"
    ballContainer.strokeColor = colors2[0]
    ballContainer.physicsBody = SKPhysicsBody(edgeLoopFromRect: containerRect)
    addChild(ballContainer)
    self.ballContainer = ballContainer

    if let revertImage = Glyphish.imageNamed("1026-revert")?.recoloredImageWithColor(colors2[0]),
           revertImageSelected = Glyphish.imageNamed("1026-revert-selected")?.recoloredImageWithColor(colors2[0])
    {
      let texturePair = ButtonNode.TexturePair(defaultTexture: SKTexture(image: revertImage),
                                               pressedTexture: SKTexture(image: revertImageSelected))
      let revertButton = ButtonNode(textures: [.Default(texturePair)], action: { [unowned self] _ in self.revert() })
      revertButton.name = "revertButton"
      revertButton.position = CGPoint(x: 44, y: frame.height - 44)
      addChild(revertButton)
    }
  }

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
