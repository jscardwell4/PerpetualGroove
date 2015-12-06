//
//  GeneratorTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/2/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

final class GeneratorTool: MIDIPlayerNodeDelegate, ToolType {

  unowned let player: MIDIPlayerNode

  var active = false { didSet { logDebug("oldValue = \(oldValue)  active = \(active)") } }

  private var touch: UITouch?
  private weak var node: MIDINode? {
    didSet {
      generatorViewController?.loadGenerator(node?.noteGenerator ?? NoteGenerator())
    }
  }
  weak var generatorViewController: GeneratorViewController? {
    didSet {
      generatorViewController?.didChangeGenerator = { [weak self] in self?.node?.noteGenerator = $0 }
    }
  }

  init(playerNode: MIDIPlayerNode) { player = playerNode }

  private typealias NodeRef = Weak<MIDINode>

  private func showViewController() {

  }

  /**
   trackNodeAtPoint:

   - parameter point: CGPoint

   - returns: [Weak<MIDINode>]
   */
  private func trackNodeAtPoint(point: CGPoint) -> MIDINode? {
    guard let track = MIDIDocumentManager.currentDocument?.sequence?.currentTrack else { return nil }
    let midiNodes = player.nodesAtPoint(point).flatMap({$0 as? MIDINode}).map({NodeRef($0)})
    return midiNodes.filter({track.nodes.contains($0) == true}).first?.reference
  }


  /**
   touchesBegan:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
  */
  func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    node = nil
    guard active && touch == nil else { return }
    touch = touches.first
    guard let point = touch?.locationInNode(player) where player.containsPoint(point) else { return }
    node = trackNodeAtPoint(point)
  }

  /**
   touchesMoved:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
  */
  func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard node == nil, let point = touch?.locationInNode(player) where player.containsPoint(point) else { return }
    node = trackNodeAtPoint(point)
  }

  /**
   touchesCancelled:withEvent:

   - parameter touches: Set<UITouch>?
   - parameter event: UIEvent?
  */
  func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) { touch = nil }

  /**
   touchesEnded:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
  */
  func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard touch != nil && touches.contains(touch!) && node != nil else { return }
    showViewController()
  }

}