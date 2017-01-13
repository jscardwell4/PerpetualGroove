//
//  MIDINodePlayerNode.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/12/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

/// Protocol for objects that can be set to handle touches received by a `MIDINodePlayerNode` instance.
@objc protocol TouchReceiver {

  func touchesBegan    (_ touches: Set<UITouch>,  with event: UIEvent?)
  func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?)
  func touchesEnded    (_ touches: Set<UITouch>,  with event: UIEvent?)
  func touchesMoved    (_ touches: Set<UITouch>,  with event: UIEvent?)

}

/// `SKShapeNode` subclass that presents a bounding box for containing `MIDINode` sprites.
final class MIDINodePlayerNode: SKShapeNode {

  /// Initialize with the shape defined by `bezierPath`. Sets `MIDINodePlayer.playerNode` to `self`.
  init(bezierPath: UIBezierPath) {
    size = bezierPath.bounds.size
    super.init()
    name = "player"
    path = bezierPath.cgPath
    strokeColor = .primaryColor
    isUserInteractionEnabled = true

    MIDINodePlayer.playerNode = self
  }

  /// Overridden to disable initializing from a coder.
  required init?(coder aDecoder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  /// Overridden to append a `node` reference to `midiNodes` when  `node is MIDINode`
  override func addChild(_ node: SKNode) {

    super.addChild(node)

    guard let midiNode = node as? MIDINode else { return }

    midiNodes.append(midiNode)

  }

  /// Collection containing references to any `MIDINode` instances added as children.
  private(set) var midiNodes: WeakArray<MIDINode> = []

  /// The collection of midi nodes for default mode.
  var defaultNodes: [MIDINode] { return midiNodes(for: .default) }

  /// The collection of midi nodes for loop mode.
  var loopNodes: [MIDINode] { return midiNodes(for: .loop) }

  /// The object currently handling touches received by the player node.
  weak var touchReceiver: TouchReceiver?

  /// The size of the player node's bounding box.
  let size: CGSize

  /// Returns the collection of midi nodes for `mode` via a search on the names of the player node's children.
  private func midiNodes(for mode: Sequencer.Mode) -> [MIDINode] {
    return self["<\(mode.rawValue)>*"].flatMap({$0 as? MIDINode})
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchReceiver?.touchesBegan(touches, with: event)
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchReceiver?.touchesCancelled(touches, with: event)
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchReceiver?.touchesEnded(touches, with: event)
  }

  /// Overridden to bounce invocation to `touchReceiver`.
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchReceiver?.touchesMoved(touches, with: event)
  }

}
