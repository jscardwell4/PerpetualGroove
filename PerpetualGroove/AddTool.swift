//
//  AddTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/12/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

final class AddTool: ToolType {

  unowned let player: MIDIPlayerNode

  var active = false {
    didSet {
      logDebug("oldValue = \(oldValue)  active = \(active)")
    }
  }

  var noteGenerator: MIDINodeGenerator = NoteGenerator()

  /**
  initWithBezierPath:

  - parameter bezierPath: UIBezierPath
  */
  init(playerNode: MIDIPlayerNode) { player = playerNode }

  // MARK: - Touch handling

  private var timestamp = 0.0
  private var location = CGPoint.null
  private var velocities: [CGVector] = []

  private var touch: UITouch? {
    didSet {
      velocities = []
      if let touch = touch {
        timestamp = touch.timestamp
        location = touch.locationInNode(player)
        let image = UIImage(named: "ball")!
        let color = (Sequencer.sequence?.currentTrack?.color ?? TrackColor.nextColor).value
        let size = image.size * 0.75
        touchNode = SKSpriteNode(texture: SKTexture(image: image), color: color, size: size)
        touchNode!.position = location
        touchNode!.name = "touchNode"
        touchNode!.colorBlendFactor = 1
        player.addChild(touchNode!)
      } else {
        timestamp = 0
        location = .null
        touchNode?.removeFromParent()
        touchNode = nil
      }
    }
  }

  private var touchNode: SKSpriteNode?

  /** updateData */
  private func updateData() {
    guard let timestamp = touch?.timestamp, location = touch?.locationInNode(player)
      where timestamp != self.timestamp && location != self.location else { return }

    velocities.append(CGVector((location - self.location) / (timestamp - self.timestamp)))
    self.timestamp = timestamp
    self.location = location
  }

  /**
  touchesBegan:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if active && touch == nil { touch = touches.first }
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
    guard touch != nil && touches.contains(touch!) else { return }
    updateData()
    generate()
    touch = nil
  }

  /**
  touchesMoved:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard touch != nil && touches.contains(touch!) else { return }
    guard let p = touch?.locationInNode(player) where player.containsPoint(p) else {
      touch = nil
      return
    }
    updateData()
    touchNode?.position = p
  }

  // MARK: - MIDINode generation

  /** generate */
  private func generate() {
    guard velocities.count > 0 && !location.isNull else { return }
    guard let track = Sequencer.sequence?.currentTrack else { return }
    let trajectory = Trajectory(vector: sum(velocities) / CGFloat(velocities.count), point: location )
    MIDIPlayer.placeNew(trajectory, target: track, generator: noteGenerator)
  }
}
