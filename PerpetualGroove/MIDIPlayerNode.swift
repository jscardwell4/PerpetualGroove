//
//  MIDIPlayerNode.swift
//  PerpetualGroove
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

    let borderRect = bezierPath.bounds
    let (minX, maxX, minY, maxY) = (borderRect.minX, borderRect.maxX, borderRect.minY, borderRect.maxY)

    let leftEdge = SKNode()
    leftEdge.name = "leftEdge"
    let leftBody = SKPhysicsBody(edgeFromPoint: CGPoint(x: minX, y: minY), toPoint: CGPoint(x: minX, y: maxY))
    leftBody.categoryBitMask = Edges.Left.rawValue
    leftEdge.physicsBody = leftBody
    addChild(leftEdge)

    let topEdge = SKNode()
    topEdge.name = "topEdge"
    let topBody = SKPhysicsBody(edgeFromPoint: CGPoint(x: minX, y: maxY), toPoint: CGPoint(x: maxX, y: maxY))
    topBody.categoryBitMask = Edges.Top.rawValue
    topEdge.physicsBody = topBody
    addChild(topEdge)

    let rightEdge = SKNode()
    rightEdge.name = "rightEdge"
    let rightBody = SKPhysicsBody(edgeFromPoint: CGPoint(x: maxX, y: maxY), toPoint: CGPoint(x: maxX, y: minY))
    rightBody.categoryBitMask = Edges.Right.rawValue
    rightEdge.physicsBody = rightBody
    addChild(rightEdge)

    let bottomEdge = SKNode()
    bottomEdge.name = "bottomEdge"
    let bottomBody = SKPhysicsBody(edgeFromPoint: CGPoint(x: minX, y: minY), toPoint: CGPoint(x: maxX, y: minY))
    bottomBody.categoryBitMask = Edges.Bottom.rawValue
    bottomEdge.physicsBody = bottomBody
    addChild(bottomEdge)


    addChild(MIDIPlayerFieldNode(bezierPath: bezierPath, delegate: self))

    receptionist.observe(Sequencer.Notification.DidReset,
                    from: Sequencer.self,
                callback: weakMethod(self, MIDIPlayerNode.didReset))

    receptionist.observe(MIDIDocumentManager.Notification.DidChangeDocument,
                    from: MIDIDocumentManager.self,
                callback: weakMethod(self, MIDIPlayerNode.didReset))
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
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.SceneContext
    return receptionist
  }()

  /**
  placeNew:

  - parameter placement: Placement
  */
  func placeNew(placement: Placement,
    targetTrack: InstrumentTrack? = nil,
     attributes: MIDINoteGenerator = Sequencer.currentNote)
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

// MARK: - ContactMask
extension MIDIPlayerNode {

  struct Edges: OptionSetType, CustomStringConvertible {
    let rawValue: UInt32

    static let None   = Edges(rawValue: 0b0000)
    static let Left   = Edges(rawValue: 0b0001)
    static let Top    = Edges(rawValue: 0b0010)
    static let Right  = Edges(rawValue: 0b0100)
    static let Bottom = Edges(rawValue: 0b1000)
    static let All    = Edges(rawValue: 0b1111)

    var description: String {
      var result = "["
      var flagStrings: [String] = []
      if contains(.Left)   { flagStrings.append("Left") }
      if contains(.Top)    { flagStrings.append("Top") }
      if contains(.Right)  { flagStrings.append("Right") }
      if contains(.Bottom) { flagStrings.append("Bottom") }
      if flagStrings.isEmpty { flagStrings.append("None") }
      else if flagStrings.count == 4 { flagStrings[0 ... 3] = ["All"] }
      result += ", ".join(flagStrings)
      result += "]"
      return result
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
