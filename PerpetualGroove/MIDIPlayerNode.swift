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

protocol MIDIPlayerNodeDelegate: class {
  init(playerNode: MIDIPlayerNode)
  var active: Bool { get set }
  func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
  func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?)
  func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
  func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
}

final class MIDIPlayerNode: SKShapeNode {

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
    userInteractionEnabled = true

    let borderRect = bezierPath.bounds
    let (minX, maxX, minY, maxY) = (borderRect.minX, borderRect.maxX, borderRect.minY, borderRect.maxY)


    addChild({
      let node = SKNode()
      node.name = "leftEdge"
      let leftBody = SKPhysicsBody(edgeFromPoint: CGPoint(x: minX, y: minY), toPoint: CGPoint(x: minX, y: maxY))
      leftBody.categoryBitMask = Edges.Left.rawValue
      node.physicsBody = leftBody
      return node
    }())

    addChild({
      let node = SKNode()
      node.name = "topEdge"
      let topBody = SKPhysicsBody(edgeFromPoint: CGPoint(x: minX, y: maxY), toPoint: CGPoint(x: maxX, y: maxY))
      topBody.categoryBitMask = Edges.Top.rawValue
      node.physicsBody = topBody
      return node
    }())

    addChild({
      let node = SKNode()
      node.name = "rightEdge"
      let rightBody = SKPhysicsBody(edgeFromPoint: CGPoint(x: maxX, y: maxY), toPoint: CGPoint(x: maxX, y: minY))
      rightBody.categoryBitMask = Edges.Right.rawValue
      node.physicsBody = rightBody
      return node
    }())

    addChild({
      let node = SKNode()
      node.name = "bottomEdge"
      let bottomBody = SKPhysicsBody(edgeFromPoint: CGPoint(x: minX, y: minY), toPoint: CGPoint(x: maxX, y: minY))
      bottomBody.categoryBitMask = Edges.Bottom.rawValue
      node.physicsBody = bottomBody
      return node
    }())

    receptionist.observe(Sequencer.Notification.DidReset,
                    from: Sequencer.self,
                callback: weakMethod(self, MIDIPlayerNode.didReset))

    receptionist.observe(MIDIDocumentManager.Notification.DidChangeDocument,
                    from: MIDIDocumentManager.self,
                callback: weakMethod(self, MIDIPlayerNode.didReset))

    MIDIPlayer.playerNode = self
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  var midiNodes: [MIDINode] { return children.flatMap({$0 as? MIDINode}) }

  // MARK: - Manipulating MIDINodes

  /**
  didReset:

  - parameter notification: NSNotification
  */
  func didReset(notification: NSNotification) {
    midiNodes.forEach { $0.removeFromParent() }
    logDebug("nodes removed")
  }

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.SceneContext
    return receptionist
  }()

  /**
   touchesBegan:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
   */
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    MIDIPlayer.touchesBegan(touches, withEvent: event)
  }

  /**
   touchesCancelled:withEvent:

   - parameter touches: Set<UITouch>?
   - parameter event: UIEvent?
   */
  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    MIDIPlayer.touchesCancelled(touches, withEvent: event)
  }

  /**
   touchesEnded:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
   */
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    MIDIPlayer.touchesEnded(touches, withEvent: event)
  }

  /**
   touchesMoved:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
   */
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    MIDIPlayer.touchesMoved(touches, withEvent: event)
  }

}

// MARK: - ContactMask
extension MIDIPlayerNode {

  enum Edge: UInt32 {
    case None   = 0b0000
    case Left   = 0b0001
    case Top    = 0b0010
    case Right  = 0b0100
    case Bottom = 0b1000
  }

  struct Edges: OptionSetType, CustomStringConvertible {
    let rawValue: UInt32

    static let None   = Edges(rawValue: Edge.None.rawValue)
    static let Left   = Edges(rawValue: Edge.Left.rawValue)
    static let Top    = Edges(rawValue: Edge.Top.rawValue)
    static let Right  = Edges(rawValue: Edge.Right.rawValue)
    static let Bottom = Edges(rawValue: Edge.Bottom.rawValue)
    static let All    = Edges(rawValue: Edge.Left.rawValue | Edge.Top.rawValue | Edge.Right.rawValue | Edge.Bottom.rawValue)

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

    init(rawValue: UInt32) { self.rawValue = rawValue }
    init(_ edge: Edge) { self.init(rawValue: edge.rawValue) }
  }
  
}
