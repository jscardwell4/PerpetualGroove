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

    var containerRect = frame.rectByInsetting(dx: 20, dy: 104).integerRect
    containerRect.origin.y += 16

    let ballContainer = BallContainer(rect: containerRect)
    ballContainer.name = "ballContainer"
    ballContainer.strokeColor = colors2[0]
    ballContainer.physicsBody = SKPhysicsBody(edgeLoopFromRect: containerRect)
    addChild(ballContainer)
    self.ballContainer = ballContainer


    let topBar = SKNode()
    topBar.name = "topBar"
    topBar.position = CGPoint(x: 32, y: frame.height - 32)
    addChild(topBar)

    let barWidth = frame.width - 64

    let buttons = SKTextureAtlas(named: "buttons")
    let texturePair: (String) -> ButtonNode.TexturePair = {
      ButtonNode.TexturePair(defaultTexture: buttons.textureNamed($0), pressedTexture: buttons.textureNamed("\($0)-selected"))
    }

    let revertButton = ButtonNode(textures: [.Default(texturePair("revert"))], action: { [unowned self] _ in self.revert() })
    revertButton.name = "revertButton"
    revertButton.setScale(0.75)
    topBar.addChild(revertButton)

    let slidersButton = ButtonNode(textures: [.Default(texturePair("sliders"))], action: { [unowned self] _ in self.sliders() })
    slidersButton.name = "slidersButton"
    slidersButton.position = CGPoint(x: barWidth * 0.25, y: 0)
    slidersButton.setScale(0.75)
    topBar.addChild(slidersButton)

    let audioButton = ButtonNode(textures: [.Default(texturePair("speaker"))], action: { [unowned self] _ in self.audio() })
    audioButton.name = "audioButton"
    audioButton.position = CGPoint(x: barWidth * 0.5, y: 0)
    audioButton.setScale(0.75)
    topBar.addChild(audioButton)

    let pianoButton = ButtonNode(textures: [.Default(texturePair("piano"))], action: { [unowned self] _ in self.piano() })
    pianoButton.name = "pianoButton"
    pianoButton.position = CGPoint(x: barWidth * 0.75, y: 0)
    pianoButton.setScale(0.75)
    topBar.addChild(pianoButton)

    let guitarButton = ButtonNode(textures: [.Default(texturePair("guitar"))], action: { [unowned self] _ in self.guitar() })
    guitarButton.name = "guitarButton"
    guitarButton.position = CGPoint(x: barWidth, y: 0)
    guitarButton.setScale(0.75)
    topBar.addChild(guitarButton)

    let bottomBar = SKNode()
    bottomBar.name = "bottomBar"
    bottomBar.position = CGPoint(x: 32, y: 74)
    addChild(bottomBar)
    
    let skipBackButton = ButtonNode(textures: [.Default(texturePair("skipBack"))], action: { [unowned self] _ in self.skipBack() })
    skipBackButton.name = "skipBackButton"
    skipBackButton.setScale(0.75)
    bottomBar.addChild(skipBackButton)

    let playButton = ButtonNode(textures: [.Default(texturePair("play"))], action: { [unowned self] _ in self.play() })
    playButton.name = "playButton"
    playButton.position = CGPoint(x: barWidth * 0.25, y: 0)
    playButton.setScale(0.75)
    bottomBar.addChild(playButton)

    let pauseButton = ButtonNode(textures: [.Default(texturePair("pause"))], action: { [unowned self] _ in self.pause() })
    pauseButton.name = "pauseButton"
    pauseButton.position = CGPoint(x: barWidth * 0.5, y: 0)
    pauseButton.setScale(0.75)
    bottomBar.addChild(pauseButton)

    let stopButton = ButtonNode(textures: [.Default(texturePair("stop"))], action: { [unowned self] _ in self.stop() })
    stopButton.name = "stopButton"
    stopButton.position = CGPoint(x: barWidth * 0.75, y: 0)
    stopButton.setScale(0.75)
    bottomBar.addChild(stopButton)



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
