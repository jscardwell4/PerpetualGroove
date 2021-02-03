//
//  PlayerNode.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/12/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import MoonDev
import SpriteKit
import UIKit

// MARK: - PlayerNode

/// `SKShapeNode` subclass that presents a bounding box for containing `Node` sprites.
@available(iOS 14.0, *)
public final class PlayerNode: SKShapeNode
{
  /// Initialize with the shape defined by `bezierPath`.
  public init(bezierPath: UIBezierPath)
  {
    size = bezierPath.bounds.size
    super.init()
    name = "player"
    path = bezierPath.cgPath
    strokeColor = .primaryColor1
    isUserInteractionEnabled = true
  }

  /// Overridden to disable initializing from a coder.
  @available(*, unavailable)
  public required init?(coder aDecoder: NSCoder)
  {
    fatalError("\(#function) is unavailable.")
  }

  /// Overridden to append a `node` reference to `midiNodes` when  `node is Node`
  override public func addChild(_ node: SKNode)
  {
    super.addChild(node)
    if let midiNode = node as? MIDINode { midiNodes.append(midiNode) }
  }

  /// Collection containing references to any `Node` instances added as children.
  public private(set) var midiNodes: WeakArray<MIDINode> = []

  /// The collection of midi nodes for default mode.
  var linearNodes: [MIDINode] { midiNodes(forMode: .linear) }

  /// The collection of midi nodes for loop mode.
  var loopNodes: [MIDINode] { midiNodes(forMode: .loop) }

  /// The object currently handling touches received by the player node.
  public weak var receiver: TouchReceiver?

  /// The size of the player node's bounding box.
  public let size: CGSize

  /// Returns the collection of midi nodes for `mode` via a search on the names of
  /// the player node's children.
  private func midiNodes(forMode mode: Mode) -> [MIDINode]
  {
    self["<\(mode.rawValue)>*"].compactMap { $0 as? MIDINode }
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    receiver?.touchesBegan(touches)
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    receiver?.touchesCancelled(touches)
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    receiver?.touchesEnded(touches)
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    receiver?.touchesMoved(touches)
  }
}

// MARK: - TouchReceiver

/// Protocol for objects that can be set to handle touches received by a
/// `PlayerNode` instance.
@objc public protocol TouchReceiver
{
  func touchesBegan(_ touches: Set<UITouch>)
  func touchesCancelled(_ touches: Set<UITouch>)
  func touchesEnded(_ touches: Set<UITouch>)
  func touchesMoved(_ touches: Set<UITouch>)
}
