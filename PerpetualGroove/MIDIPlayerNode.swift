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

@objc protocol TouchReceiver {
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
    size = bezierPath.bounds.size
    super.init()
    name = "player"
    path = bezierPath.CGPath
    strokeColor = .primaryColor
    userInteractionEnabled = true

    MIDIPlayer.playerNode = self
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  /**
   addChild:

   - parameter node: SKNode
  */
  override func addChild(node: SKNode) {
    super.addChild(node)
    guard let midiNode = node as? MIDINode else { return }
    midiNodes.append(midiNode)
  }


  private(set) var midiNodes: WeakArray<MIDINode> = []

  var defaultNodes: [MIDINode] { return midiNodesForMode(.Default) }

  var loopNodes: [MIDINode] { return midiNodesForMode(.Loop) }

  weak var touchReceiver: TouchReceiver?

  let size: CGSize

  /**
   midiNodesForMode:

   - parameter mode: Sequencer.Mode

    - returns: [MIDINode]
  */
  private func midiNodesForMode(mode: Sequencer.Mode) -> [MIDINode] {
    return self["<\(mode.rawValue)>*"].flatMap({$0 as? MIDINode}) ?? []
  }

  /**
   touchesBegan:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
   */
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    touchReceiver?.touchesBegan(touches, withEvent: event)
  }

  /**
   touchesCancelled:withEvent:

   - parameter touches: Set<UITouch>?
   - parameter event: UIEvent?
   */
  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    touchReceiver?.touchesCancelled(touches, withEvent: event)
  }

  /**
   touchesEnded:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
   */
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    touchReceiver?.touchesEnded(touches, withEvent: event)
  }

  /**
   touchesMoved:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
   */
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    touchReceiver?.touchesMoved(touches, withEvent: event)
  }

}
