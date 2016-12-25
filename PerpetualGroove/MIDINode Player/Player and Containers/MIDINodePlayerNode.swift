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

@objc protocol TouchReceiver {

  func touchesBegan    (_ touches: Set<UITouch>,  with event: UIEvent?)
  func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?)
  func touchesEnded    (_ touches: Set<UITouch>,  with event: UIEvent?)
  func touchesMoved    (_ touches: Set<UITouch>,  with event: UIEvent?)

}

final class MIDINodePlayerNode: SKShapeNode {

  init(bezierPath: UIBezierPath) {
    size = bezierPath.bounds.size
    super.init()
    name = "player"
    path = bezierPath.cgPath
    strokeColor = .primaryColor
    isUserInteractionEnabled = true

    MIDINodePlayer.playerNode = self
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  override func addChild(_ node: SKNode) {
    super.addChild(node)
    guard let midiNode = node as? MIDINode else { return }
    midiNodes.append(midiNode)
  }

  private(set) var midiNodes: WeakArray<MIDINode> = []

  var defaultNodes: [MIDINode] { return midiNodes(for: .default) }

  var loopNodes: [MIDINode] { return midiNodes(for: .loop) }

  weak var touchReceiver: TouchReceiver?

  let size: CGSize

  private func midiNodes(for mode: Sequencer.Mode) -> [MIDINode] {
    return self["<\(mode.rawValue)>*"].flatMap({$0 as? MIDINode})
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchReceiver?.touchesBegan(touches, with: event)
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchReceiver?.touchesCancelled(touches, with: event)
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchReceiver?.touchesEnded(touches, with: event)
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchReceiver?.touchesMoved(touches, with: event)
  }

}
