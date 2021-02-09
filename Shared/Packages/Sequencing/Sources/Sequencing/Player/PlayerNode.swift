//
//  PlayerNode.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/12/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import MoonDev
import SpriteKit
//import UIKit

// MARK: - PlayerNode

/// `SKShapeNode` subclass that presents a bounding box for containing `Node` sprites.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
final class PlayerNode: SKShapeNode
{
  /// Initialize with the shape defined by `bezierPath`.
  init(rect: CGRect)
  {
    size = rect.size
    super.init()
    name = "player"
    path = CGPath(rect: rect, transform: nil)
    strokeColor = .primaryColor1
    isUserInteractionEnabled = true
  }

  /// Overridden to disable initializing from a coder.
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder)
  {
    fatalError("\(#function) is unavailable.")
  }

  /// Overridden to append a `node` reference to `midiNodes` when  `node is Node`
  override func addChild(_ node: SKNode)
  {
    super.addChild(node)
    if let midiNode = node as? MIDINode { midiNodes.append(midiNode) }
  }

  /// Collection containing references to any `Node` instances added as children.
  private(set) var midiNodes: WeakArray<MIDINode> = []

  /// The collection of midi nodes for default mode.
  var linearNodes: [MIDINode] { midiNodes(forMode: .linear) }

  /// The collection of midi nodes for loop mode.
  var loopNodes: [MIDINode] { midiNodes(forMode: .loop) }

  /// The object currently handling touches received by the player node.
  weak var receiver: TouchReceiver?

  /// The size of the player node's bounding box.
  var size: CGSize { didSet { path = CGPath(rect: CGRect(size: size), transform: nil) } }

  /// Returns the collection of midi nodes for `mode` via a search on the names of
  /// the player node's children.
  private func midiNodes(forMode mode: Mode) -> [MIDINode]
  {
    self["<\(mode.rawValue)>*"].compactMap { $0 as? MIDINode }
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    receiver?.touchesBegan(touches)
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    receiver?.touchesCancelled(touches)
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    receiver?.touchesEnded(touches)
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    receiver?.touchesMoved(touches)
  }
}

// MARK: - TouchReceiver

/// Protocol for objects that can be set to handle touches received by a
/// `PlayerNode` instance.
@objc protocol TouchReceiver
{
  func touchesBegan(_ touches: Set<UITouch>)
  func touchesCancelled(_ touches: Set<UITouch>)
  func touchesEnded(_ touches: Set<UITouch>)
  func touchesMoved(_ touches: Set<UITouch>)
}
