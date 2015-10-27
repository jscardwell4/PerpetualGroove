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

  static var currentInstance: MIDIPlayerNode? { return MIDIPlayerScene.currentInstance?.midiPlayer }

  // MARK: - Initialization

  /**
  initWithBezierPath:

  - parameter bezierPath: UIBezierPath
  */
  init(bezierPath: UIBezierPath) {
    super.init()
    name = "player"
    path = bezierPath.CGPath
    strokeColor = .primaryColor
    
    guard let path = path else { return }
    physicsBody = SKPhysicsBody(edgeLoopFromPath: path)
    physicsBody?.categoryBitMask = 1
    physicsBody?.contactTestBitMask = 0xFFFFFFFF
    addChild(MIDIPlayerFieldNode(bezierPath: bezierPath, delegate: self))

    let queue = NSOperationQueue.mainQueue()

    receptionist.observe(Sequencer.Notification.DidReset, from: Sequencer.self, queue: queue) {
      [weak self] in self?.didReset($0)
    }

    receptionist.observe(MIDIDocumentManager.Notification.DidChangeDocument, from: MIDIDocumentManager.self, queue: queue) {
      [weak self] in self?.didReset($0)
    }
  }

  private(set) var midiNodes: [MIDINode] = [] { didSet { logDebug("player now has \(midiNodes.count) nodes") } }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }


  // MARK: - Manipulating MIDINodes

  /**
  didReset:

  - parameter notification: NSNotification
  */
  func didReset(notification: NSNotification) {
    while let node = midiNodes.popLast() { node.removeFromParent() }
    logDebug("midi nodes removed")
  }

  private let receptionist: NotificationReceptionist = {
    let r = NotificationReceptionist()
    r.logContext = LogManager.SceneContext
    return r
  }()

  /**
  placeNew:

  - parameter placement: Placement
  */
  func placeNew(placement: Placement,
                targetTrack: InstrumentTrack? = nil,
                attributes: NoteAttributes = Sequencer.currentNoteAttributes)
  {
    guard let track = targetTrack ?? Sequencer.sequence?.currentTrack else {
      logWarning("Cannot place a node without a track")
      return
    }
    
    do {
      let name = "\(track.name) \(attributes)"
      let midiNode = try MIDINode(placement: placement, name: name, track: track, note: attributes)
      addChild(midiNode)
      midiNodes.append(midiNode)
      try track.addNode(midiNode)
      if !Sequencer.playing { Sequencer.play() }
      Notification.DidAddNode.post()
      logDebug("added node \(name)")

    } catch {
      logError(error)
    }
  }

}

// MARK: - Notification
extension MIDIPlayerNode {

  /** An enumeration to wrap up notifications */
  enum Notification: String, NotificationType, NotificationNameType {
    case DidAddNode, DidRemoveNode
    var object: AnyObject? { return MIDIPlayerNode.self }
    typealias Key = String
  }

}
