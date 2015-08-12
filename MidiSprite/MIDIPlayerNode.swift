//
//  MIDIPlayerNode.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/12/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

class MIDIPlayerNode: SKShapeNode {

  // MARK: - Initialization

  /**
  initWithBezierPath:

  - parameter bezierPath: UIBezierPath
  */
  init(bezierPath: UIBezierPath) {
    super.init()
    name = "player"
    path = bezierPath.CGPath
    strokeColor = UIColor(red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0)
    guard let path = path else { return }
    physicsBody = SKPhysicsBody(edgeLoopFromPath: path)
    physicsBody?.categoryBitMask = 1
    physicsBody?.contactTestBitMask = 0xFFFFFFFF
    addChild(MIDIPlayerFieldNode(bezierPath: bezierPath, delegate: self))
  }

  private var midiNodes: [MIDINode] = []

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }


  // MARK: - Manipulating MIDINodes

  var soundSet = Instrument.SoundSet.PureOscillators
  var program: UInt8 = 0
  var channel: UInt8 = 0
  var note = Instrument.Note()
  var textureType = MIDINode.TextureType.PlasticWrap

  /** dropLast */
  func dropLast() { guard midiNodes.count > 0 else { return }; midiNodes.removeLast().removeFromParent() }

  /**
  placeNew:

  - parameter placement: MIDINode.Placement
  */
  func placeNew(placement: MIDINode.Placement) {
    let instrument = MIDIManager.connectedInstrumentWithSoundSet(soundSet, program: program, channel: channel)
                       ?? Instrument(soundSet: soundSet, program: program, channel: channel)
    let midiNode = MIDINode(texture: textureType, placement: placement, instrument: instrument, note: note)
    midiNode.name = "midiNode\(midiNodes.count)"
    addChild(midiNode)
    midiNodes.append(midiNode)
  }

}
