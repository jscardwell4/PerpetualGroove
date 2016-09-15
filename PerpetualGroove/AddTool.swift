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

  @objc var active = false {
    didSet {
      logDebug("oldValue = \(oldValue)  active = \(active)")
    }
  }

  var generator = MIDIGenerator(NoteGenerator())

  /**
  initWithBezierPath:

  - parameter bezierPath: UIBezierPath
  */
  init(playerNode: MIDIPlayerNode) { player = playerNode }

  // MARK: - Touch handling

  fileprivate var timestamp = 0.0
  fileprivate var location = CGPoint.null
  fileprivate var velocities: [CGVector] = []

  fileprivate var touch: UITouch? {
    didSet {
      velocities = []
      if let touch = touch {
        timestamp = touch.timestamp
        location = touch.location(in: player)
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

  fileprivate var touchNode: SKSpriteNode?

  /** updateData */
  fileprivate func updateData() {
    guard let timestamp = touch?.timestamp, let location = touch?.location(in: player)
      , timestamp != self.timestamp && location != self.location else { return }

    velocities.append(CGVector((location - self.location) / (timestamp - self.timestamp)))
    self.timestamp = timestamp
    self.location = location
  }

  /**
  touchesBegan:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  @objc func touchesBegan(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
    if active && touch == nil { touch = touches.first }
  }

  /**
  touchesCancelled:withEvent:

  - parameter touches: Set<UITouch>?
  - parameter event: UIEvent?
  */
  @objc func touchesCancelled(_ touches: Set<UITouch>?, withEvent event: UIEvent?) { touch = nil }

  /**
  touchesEnded:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  @objc func touchesEnded(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
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
  @objc func touchesMoved(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard touch != nil && touches.contains(touch!) else { return }
    guard let p = touch?.location(in: player) , player.contains(p) else {
      touch = nil
      return
    }
    updateData()
    touchNode?.position = p
  }

  // MARK: - MIDINode generation

  /** generate */
  fileprivate func generate() {
    guard velocities.count > 0 && !location.isNull else { return }
    guard let track = Sequencer.sequence?.currentTrack else { return }
    let trajectory = Trajectory(vector: velocities.reduce(CGVector(), +) / CGFloat(velocities.count), point: location )
    MIDIPlayer.placeNew(trajectory, target: track, generator: generator)
  }
}
