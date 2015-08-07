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

class BallScene: SKScene {

  typealias BallType = Ball.BallType

  private var nextBallType = BallType.Concrete

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

  /** createContent */
  private func createContent() {

    backgroundColor = colors2[3]
    scaleMode = .ResizeFill

    let containerRect = frame.rectByInsetting(dx: 44, dy: 44).integerRect

    let ballContainer = SKShapeNode(rect: containerRect)
    ballContainer.name = "ballContainer"
    ballContainer.strokeColor = colors2[0]
    ballContainer.physicsBody = SKPhysicsBody(edgeLoopFromRect: containerRect)
    addChild(ballContainer)


    let context = CIContext(options: nil)
    let defaultTexture = nextBallType.texture
//    let filteredImage = MSPainter.embossImage(UIImage(named: nextBallType.assetName)!)
//    let defaultTextureImage = CIImage(image: UIImage(named: nextBallType.assetName)!)!
    let defaultTextureImage = CIImage(image: UIImage(named: nextBallType.assetName)!)!
    let motionBlurFilter = CIFilter(name: "CIMotionBlur", withInputParameters: ["inputImage": defaultTextureImage])!

    let filteredImage = motionBlurFilter.valueForKey(kCIOutputImageKey) as! CIImage

    let filteredCGImage = context.createCGImage(filteredImage, fromRect: defaultTextureImage.extent.rectByInsetting(dx: -20, dy: -20))

    let pressedTexture = SKTexture(CGImage: filteredCGImage)

    let nextBallSettings = ButtonNode(textures: [.Default(defaultTexture), .Pressed(pressedTexture)]) {
      _ in
      MSLogDebug("pressed bitches!!!")
    }

    nextBallSettings.name = "nextBallSettings"
    nextBallSettings.position = CGPoint(x: frame.width - 10, y: frame.height - 10) - nextBallSettings.size * 0.5
    addChild(nextBallSettings)

    addTestBalls()
    dumpNodeTree()
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

  /** addTestBalls */
  private func addTestBalls() {
    let concreteBall = Ball(.Concrete, CGVector(dx: 200, dy: 300))
    concreteBall.position = CGPoint(x: 60, y: 100)
    concreteBall.name = "concreteBall"
    addChild(concreteBall)

    let crustyBall = Ball(.Crusty, CGVector(dx: 100, dy: 150))
    crustyBall.position = CGPoint(x: 130, y: 80)
    crustyBall.name = "crustyBall"
    addChild(crustyBall)

    let oceanBall = Ball(.Ocean, CGVector(dx: 10, dy: -100))
    oceanBall.position = CGPoint(x: 170, y: 250)
    oceanBall.name = "oceanBall"
    addChild(oceanBall)

    let sandBall = Ball(.Sand, CGVector(dx: -400, dy: -300))
    sandBall.position = CGPoint(x: 250, y: 300)
    sandBall.name = "sandBall"
    addChild(sandBall)

    let waterBall = Ball(.Water, CGVector(dx: -500, dy: -100))
    waterBall.position = CGPoint(x: 300, y: 400)
    waterBall.name = "waterBall"
    addChild(waterBall)
  }

  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
  }
}
