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

  static var currentInstance: MIDIPlayerNode? { return MIDIPlayerScene.currentInstance?.player }

  private lazy var addToolDelegate:       AddToolDelegate = AddToolDelegate(playerNode: self)
  private lazy var removeToolDelegate:    RemoveToolDelegate = RemoveToolDelegate(playerNode: self)
  private lazy var generatorToolDelegate: GeneratorToolDelegate = GeneratorToolDelegate(playerNode: self)

  private weak var delegate: MIDIPlayerNodeDelegate? {
    didSet {
      guard oldValue !== delegate else { return }
      switch delegate {
        case let d? where d === addToolDelegate:       logDebug("addToolDelegate active")
        case let d? where d === removeToolDelegate:    logDebug("removeToolDelegate active")
        case let d? where d === generatorToolDelegate: logDebug("generatorToolDelegate active")
        default: logDebug("no active delegate")
      }
    }
  }

  var activeTool: Tool = .Add { didSet { activateDelegateForTool(activeTool) } }

  /**
   delegateForTool:

   - parameter tool: Tool

    - returns: MIDIPlayerNodeDelegate
  */
  private func delegateForTool(tool: Tool) -> MIDIPlayerNodeDelegate {
    switch tool {
      case .Add: return addToolDelegate
      case .Remove: return removeToolDelegate
      case .Generator: return generatorToolDelegate
    }
  }

  /**
   activateDelegateForTool:

   - parameter tool: Tool
  */
  private func activateDelegateForTool(tool: Tool) {
    let toolDelegate: MIDIPlayerNodeDelegate
    switch tool {
      case .Add:      toolDelegate = addToolDelegate
      case .Remove:   toolDelegate = removeToolDelegate
      case .Generator: toolDelegate = generatorToolDelegate
    }
    guard delegate !== toolDelegate else { return }
    delegate?.active = false
    delegate = toolDelegate
    delegate?.active = true
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

    activateDelegateForTool(activeTool)
  }

  private(set) var midiNodes: [MIDINode] = []

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
      Notification.DidAddNode.post(
        object: self,
        userInfo: [
          Notification.Key.AddedNode: midiNode,
          Notification.Key.AddedNodeTrack: track
        ]
      )
      logDebug("added node \(name)")

    } catch {
      logError(error)
    }
  }


  /**
   touchesBegan:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
   */
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    delegate?.touchesBegan(touches, withEvent: event)
  }

  /**
   touchesCancelled:withEvent:

   - parameter touches: Set<UITouch>?
   - parameter event: UIEvent?
   */
  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    delegate?.touchesCancelled(touches, withEvent: event)
  }

  /**
   touchesEnded:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
   */
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    delegate?.touchesEnded(touches, withEvent: event)
  }

  /**
   touchesMoved:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
   */
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    delegate?.touchesMoved(touches, withEvent: event)
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
    enum Key: String, NotificationKeyType { case AddedNode, AddedNodeTrack }
  }

}

extension NSNotification {
  var addedNode: MIDINode? {
    return userInfo?[MIDIPlayerNode.Notification.Key.AddedNode.key] as? MIDINode
  }
  var addedNodeTrack: InstrumentTrack? {
    return userInfo?[MIDIPlayerNode.Notification.Key.AddedNodeTrack.key] as? InstrumentTrack
  }
}

// MARK: - Tool
extension MIDIPlayerNode {
  enum Tool { case Add, Remove, Generator }
}

