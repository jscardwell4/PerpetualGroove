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

/// A tool for generating new `MIDINode` instances.
final class AddTool: Tool {

  /// The player node to which midi nodes are to be added.
  unowned let playerNode: MIDINodePlayerNode

  /// Whether the tool is currently receiving touch events.
  @objc var active = false

  /// The generator given to generated nodes.
  var generator = AnyMIDIGenerator()

  /// Default initializer.
  init(playerNode: MIDINodePlayerNode) { self.playerNode = playerNode }

  /// The most recent timestamp retrieved from `touch`.
  private var timestamp = 0.0

  /// The most recent location retrieved from `touch`.
  private var location = CGPoint.null

  /// Collection of velocity values calculated from timestamp and location values retrieved from `touch`.
  private var velocities: [CGVector] = []

  /// The currently tracked touch.
  private var touch: UITouch? {

    didSet {

      // Clear cache of velocities.
      velocities = []

      switch touch {

        case let touch?:

          // Check that there is a dispatch object from which to grab a track color.
          guard let dispatchColor = MIDINodePlayer.currentDispatch?.color else { return }

          // Update the timestamp and location.
          timestamp = touch.timestamp
          location = touch.location(in: playerNode)

          // Update `touchNode` with a new sprite
          touchNode = {

            let node = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "ball")),
                                    color: dispatchColor.value,
                                    size: MIDINode.defaultSize)

            node.position = location
            node.name = "touchNode"
            node.colorBlendFactor = 1

            playerNode.addChild(node)

            return node

          }()

        case nil:

          timestamp = 0
          location = .null
          touchNode?.removeFromParent()
          touchNode = nil

      }

    }

  }

  /// Sprite used to provide visual feedback of the tracked touch.
  private var touchNode: SKSpriteNode?

  /// Appends a new velocity to `velocities` using the timestamp and location retrieved from `touch`.
  private func updateData() {

    // Check that the timestamp and location can be retrieved and that they are both new values.
    guard let timestampʹ = touch?.timestamp,
          let locationʹ = touch?.location(in: playerNode),
          timestampʹ != timestamp && locationʹ != location
      else
    {
      return
    }

    // Calculate the new velocity as the change in location over the change in time.
    let 𝝙location = locationʹ - location
    let 𝝙timestamp = timestampʹ - timestamp
    let velocity = CGVector(𝝙location / 𝝙timestamp)

    // Append the new velocity.
    velocities.append(velocity)

    // Update timestamp and location.
    timestamp = timestampʹ
    location = locationʹ

  }

  /// Updates `touch` when `active && touch == nil`.
  @objc func touchesBegan(_ touches: Set<UITouch>) {

    guard active && touch == nil else { return }

    touch = touches.first

  }

  /// Sets `touch` to `nil`.
  @objc func touchesCancelled(_ touches: Set<UITouch>) {

    // Check that there is a touch being tracked and that it is present in `touches`.
    guard touch != nil && touches.contains(touch!) else { return }

    touch = nil

  }

  /// Adds a new node to the player.
  @objc func touchesEnded(_ touches: Set<UITouch>) {

    // Check that there is a touch being tracked and that it is present in `touches`.
    guard touch != nil && touches.contains(touch!) else { return }

    // Append a new velocity.
    updateData()

    // Check that `velocities` is not empty and `location` is valid.
    guard velocities.count > 0 && !location.isNull else { return }

    // Check that there is a valid dispatch target.
    guard let dispatch = MIDINodePlayer.currentDispatch else { return }

    // Calculate the velocity as the average of the elements in `velocities`.
    let velocity = CGVector.mean(velocities)

    // Create the initial trajectory.
    let trajectory = MIDINode.Trajectory(velocity: velocity, position: location )

    // Add a new node to the player.
    MIDINodePlayer.placeNew(trajectory, target: dispatch, generator: generator)

    // Update `touch`.
    touch = nil

  }

  /// Appends a new velocity to `velocities` and updates the position of `touchNode`.
  @objc func touchesMoved(_ touches: Set<UITouch>) {

    // Check that there is a touch being tracked and that it is present in `touches`.
    guard touch != nil && touches.contains(touch!) else { return }

    // Check that tracked touch is within the player's bounding box.
    guard let position = touch?.location(in: playerNode) , playerNode.contains(position) else {
      touch = nil
      return
    }

    // Append a new velocity to `velocities`.
    updateData()

    // Update the position of `touchNode`.
    touchNode?.position = position

  }

}
