//
//  PlayerNode.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/12/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

/// Protocol for objects that can be set to handle touches received by a
/// `PlayerNode` instance.
@objc public protocol TouchReceiver {

  func touchesBegan    (_ touches: Set<UITouch>)
  func touchesCancelled(_ touches: Set<UITouch>)
  func touchesEnded    (_ touches: Set<UITouch>)
  func touchesMoved    (_ touches: Set<UITouch>)

}

/// `SKShapeNode` subclass that presents a bounding box for containing `Node` sprites.
public final class PlayerNode: SKShapeNode {

  /// Initialize with the shape defined by `bezierPath`.
  public init(bezierPath: UIBezierPath) {
    size = bezierPath.bounds.size
    super.init()
    name = "player"
    path = bezierPath.cgPath
    strokeColor = .primaryColor
    isUserInteractionEnabled = true
  }

  /// Overridden to disable initializing from a coder.
  public required init?(coder aDecoder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  /// Overridden to append a `node` reference to `midiNodes` when  `node is Node`
  public override func addChild(_ node: SKNode) {

    super.addChild(node)

    guard let midiNode = node as? Node else { return }

    midiNodes.append(midiNode)

  }

  /// Collection containing references to any `Node` instances added as children.
  public private(set) var midiNodes: WeakArray<Node> = []

  /// The collection of midi nodes for default mode.
  var linearNodes: [Node] { midiNodes(for: .linear) }

  /// The collection of midi nodes for loop mode.
  var loopNodes: [Node] { midiNodes(for: .loop) }

  /// The object currently handling touches received by the player node.
  public weak var touchReceiver: TouchReceiver?

  /// The size of the player node's bounding box.
  public let size: CGSize

  /// Returns the collection of midi nodes for `mode` via a search on the names of
  /// the player node's children.
  private func midiNodes(for mode: Controller.Mode) -> [Node] {
    self["<\(mode.rawValue)>*"].compactMap({$0 as? Node})
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchReceiver?.touchesBegan(touches)
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchReceiver?.touchesCancelled(touches)
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchReceiver?.touchesEnded(touches)
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchReceiver?.touchesMoved(touches)
  }

}
