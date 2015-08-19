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
import typealias AudioToolbox.MusicDeviceGroupID

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

  var soundSet = SoundSet.PureOscillators
  var program: UInt8 = 0
  var channel: MusicDeviceGroupID = 0

  /** dropLast */
  func dropLast() { guard midiNodes.count > 0 else { return }; midiNodes.removeLast().removeFromParent() }

  /** reset */
  func reset() { midiNodes.forEach { $0.removeFromParent() }; midiNodes.removeAll() }

  /**
  placeNew:

  - parameter placement: MIDINode.Placement
  */
  func placeNew(placement: MIDINode.Placement) {
    guard let controller = UIApplication.sharedApplication().keyWindow?.rootViewController
                             as? MIDIPlayerSceneViewController else { return }
    if !controller.playing { controller.play() }

    let track: InstrumentTrack

    if let t = Mixer.currentTrack { track = t }
    else {
      do {
        track = try Mixer.newTrackWithSoundSet(Instrument.currentSoundSet)
        try track.instrument.setProgram(Instrument.currentProgram, onChannel: Instrument.currentChannel)
        Mixer.currentTrack = track
      } catch {
        logError(error)
        return
      }
    }

      let midiNode = MIDINode(placement: placement, track: track)

      midiNode.name = "midiNode\(midiNodes.count)"
      midiNode.color = track.color.value
      midiNode.colorBlendFactor = 1.0

      addChild(midiNode)

      midiNodes.append(midiNode)
  }

}
