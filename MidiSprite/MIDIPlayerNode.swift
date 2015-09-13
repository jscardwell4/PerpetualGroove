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

final class MIDIPlayerNode: SKShapeNode {

  /** An enumeration to wrap up notifications */
  enum Notification: String, NotificationType, NotificationNameType {
    case NodeAdded, NodeRemoved
    var object: AnyObject? { return MIDIPlayerNode.self }
  }

  // MARK: - Initialization

  /**
  initWithBezierPath:

  - parameter bezierPath: UIBezierPath
  */
  init(bezierPath: UIBezierPath) {
    super.init()
    name = "player"
    path = bezierPath.CGPath
//    strokeColor = .strokeColor
    strokeTexture = SKTexture(image: UIImage(named: "stroketexture")!.imageWithColor(.strokeColor))
    guard let path = path else { return }
    physicsBody = SKPhysicsBody(edgeLoopFromPath: path)
    physicsBody?.categoryBitMask = 1
    physicsBody?.contactTestBitMask = 0xFFFFFFFF
    addChild(MIDIPlayerFieldNode(bezierPath: bezierPath, delegate: self))
  }

  private(set) var midiNodes: [MIDINode] = []
  
  var emptyField: Bool { return midiNodes.count == 0 }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }


  // MARK: - Manipulating MIDINodes

  /** dropLast */
  func dropLast() {
    guard midiNodes.count > 0 else { return }
    let node = midiNodes.removeLast()
    do { try Sequencer.currentTrack.removeNode(node) } catch { logError(error) }
    node.removeFromParent()
    Notification.NodeRemoved.post()
  }

  /** reset */
  func reset() { midiNodes.forEach { $0.removeFromParent() }; midiNodes.removeAll() }

  /**
  placeNew:

  - parameter placement: MIDINode.Placement
  */
  func placeNew(placement: MIDINode.Placement) {
    do {
      // We have to get the track first to force a new track to be created when necessary before the `MIDINode` receives its color
      let track = Sequencer.currentTrackForAddingNode
      let midiNode = try MIDINode(placement, "midiNode\(midiNodes.count)")
      addChild(midiNode)
      midiNodes.append(midiNode)
      try track.addNode(midiNode)
      Notification.NodeAdded.post()
    } catch {
      logError(error)
    }
  }

}
