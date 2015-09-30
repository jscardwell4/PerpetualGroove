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

  static var currentPlayer: MIDIPlayerNode? {
    return MIDIPlayerViewController.currentInstance?.midiPlayerView?.midiPlayerScene?.midiPlayer
  }

  /** An enumeration to wrap up notifications */
  enum Notification: String, NotificationType, NotificationNameType {
    case DidAddNode, DidRemoveNode
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
    strokeColor = .primaryColor
    
    guard let path = path else { return }
    physicsBody = SKPhysicsBody(edgeLoopFromPath: path)
    physicsBody?.categoryBitMask = 1
    physicsBody?.contactTestBitMask = 0xFFFFFFFF
    addChild(MIDIPlayerFieldNode(bezierPath: bezierPath, delegate: self))

    notificationReceptionist = NotificationReceptionist(callbacks:
      [
        Sequencer.Notification.DidReset.rawValue: (Sequencer.self, NSOperationQueue.mainQueue(), didReset)
      ]
    )
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
    guard midiNodes.count > 0, let track = Sequencer.sequence?.currentTrack else { return }
    let node = midiNodes.removeLast()
    do { try track.removeNode(node) } catch { logError(error) }
    node.removeFromParent()
    Notification.DidRemoveNode.post()
  }

  /**
  didReset:

  - parameter notification: NSNotification
  */
  func didReset(notification: NSNotification) {
    midiNodes.forEach { $0.removeFromParent() }
    midiNodes.removeAll()
  }

  private var notificationReceptionist: NotificationReceptionist!

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
//      // Get the track first to force a new track to be created when necessary before the `MIDINode` receives its color
//      let track: InstrumentTrack
//      if targetTrack != nil { track = targetTrack! }
//      else if let t = Sequencer.currentTrack where t.instrument.settingsEqualTo(Sequencer.auditionInstrument) { track = t }
//      else {
//        track = try sequence.newTrackWithInstrument(Sequencer.instrumentWithCurrentSettings())
//        Sequencer.currentTrack = track
//      }
      let midiNode = try MIDINode(placement: placement, name: "midiNode\(midiNodes.count)", track: track, note: attributes)
      addChild(midiNode)
      midiNodes.append(midiNode)
      try track.addNode(midiNode)
      if !Sequencer.playing { Sequencer.play() }
      Notification.DidAddNode.post()
    } catch {
      logError(error)
    }
  }

}
