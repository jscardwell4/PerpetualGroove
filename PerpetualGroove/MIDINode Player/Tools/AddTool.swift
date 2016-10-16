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

final class AddTool: Tool {

  unowned let playerNode: MIDINodePlayerNode

  @objc var active = false

  var generator = AnyMIDIGenerator()

  init(playerNode: MIDINodePlayerNode) { self.playerNode = playerNode }

  private var timestamp = 0.0
  fileprivate var location = CGPoint.null
  fileprivate var velocities: [CGVector] = []

  fileprivate var touch: UITouch? {

    didSet {

      velocities = []

      if let touch = touch {

        timestamp = touch.timestamp
        location = touch.location(in: playerNode)

        touchNode = {
          let node = SKSpriteNode(texture: SKTexture(image: $0), color: $1, size: $0.size * 0.75)

          node.position = location
          node.name = "touchNode"
          node.colorBlendFactor = 1

          playerNode.addChild(node)

          return node
        }(#imageLiteral(resourceName: "ball"), (Sequencer.sequence?.currentTrack?.color ?? TrackColor.nextColor).value)

      } else {

        timestamp = 0
        location = .null
        touchNode?.removeFromParent()
        touchNode = nil

      }

    }

  }

  fileprivate var touchNode: SKSpriteNode?

  fileprivate func updateData() {

    guard let timestamp = touch?.timestamp,
          let location = touch?.location(in: playerNode),
          timestamp != self.timestamp && location != self.location
      else
    {
      return
    }

    velocities.append(CGVector((location - self.location) / (timestamp - self.timestamp)))

    self.timestamp = timestamp
    self.location = location

  }

}

extension AddTool: TouchReceiver {

  @objc func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if active && touch == nil { touch = touches.first }
  }

  @objc func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) { touch = nil }

  @objc func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard touch != nil && touches.contains(touch!) else { return }
    updateData()
    guard velocities.count > 0 && !location.isNull else { return }
    guard let track = Sequencer.sequence?.currentTrack else { return }
    let trajectory = MIDINode.Trajectory(vector: velocities.reduce(CGVector(), +) / CGFloat(velocities.count), point: location )
    MIDINodePlayer.placeNew(trajectory, target: track, generator: generator)
    touch = nil
  }

  @objc func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard touch != nil && touches.contains(touch!) else { return }
    guard let p = touch?.location(in: playerNode) , playerNode.contains(p) else {
      touch = nil
      return
    }
    updateData()
    touchNode?.position = p
  }

}
