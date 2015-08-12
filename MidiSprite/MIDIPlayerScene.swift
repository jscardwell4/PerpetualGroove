//
//  MIDIPlayerScene.swift
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

class MIDIPlayerScene: SKScene {

  weak var midiPlayer: MIDIPlayerNode!

  static let defaultBackgroundColor = UIColor(red: 0.202, green: 0.192, blue: 0.192, alpha: 1.0)

  private var contentCreated = false

  /** revert */
  func revert() { midiPlayer.dropLast() }

  /** createContent */
  private func createContent() {
    scaleMode = .AspectFit
    let w = frame.width - 20
    let containerRect = CGRect(x: 10, y: frame.midY - w * 0.5, width: w, height: w)

    let player = MIDIPlayerNode(bezierPath: UIBezierPath(rect: containerRect))
    addChild(player)
    midiPlayer = player

    physicsWorld.contactDelegate = self
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
  override func didMoveToView(view: SKView) { guard !contentCreated else { return }; createContent(); contentCreated = true }


  /**
  update:

  - parameter currentTime: CFTimeInterval
  */
//  override func update(currentTime: CFTimeInterval) {
//    /* Called before each frame is rendered */
//  }
}

extension MIDIPlayerScene: SKPhysicsContactDelegate {
  /**
  didBeginContact:

  - parameter contact: SKPhysicsContact
  */
  func didBeginContact(contact: SKPhysicsContact) {
//    guard let ball = contact.bodyB.node as? Ball else { return }
//    ball.instrument.playNote(ball.note)
  }
}
