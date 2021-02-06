//
//  NodeAction.swift
//  
//
//  Created by Jason Cardwell on 2/5/21.
//
import SpriteKit

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct NodeAction
{
  /// Specifies what kind of action is run.
  let key: Key

  /// The node upon which the action runs.
  unowned let coordinator: NodeActionCoordinator

  /// The `SKAction` object generator for the action.
  var action: SKAction
  {
    switch key
    {
      case .move:

        // Get the current segment on the path.
        let segment = coordinator.flightPath[coordinator.currentSegment]

        // Get the duration, which is the time it will take to travel the
        // current segment.
        let duration = segment.trajectory.time(from: coordinator.node.position,
                                               to: segment.endLocation)

        // Create the action to move the node to the end of the current segment.
        let move = SKAction.move(to: segment.endLocation, duration: duration)

        // Create the play action.
        let play = NodeAction(key: .play, coordinator: coordinator).action

        // Create the action that updates the current segment and continues movement.
        let updateAndRepeat = SKAction.run
        {
          coordinator.currentSegment = coordinator.currentSegment &+ 1
          coordinator.move()
        }

        // Group actions to play and repeat.
        let playUpdateAndRepeat = SKAction.group([play, updateAndRepeat])

        // Return as a sequence.
        return SKAction.sequence([move, playUpdateAndRepeat])

      case .play:

        // Calculate half of the action's duration.
        let halfDuration = coordinator.generator.duration
          .seconds(withBPM: Sequencer.shared.tempo) * 0.5

        // Scale up to playing size for half the action.
        let scaleUp = SKAction.resize(toWidth: MIDINode.playingSize.width,
                                      height: MIDINode.playingSize.height,
                                      duration: halfDuration)

        // Send the 'note on' event.
        let noteOn = SKAction.run { coordinator.sendNoteOn() }

        // Scale down to default size for half the action.
        let scaleDown = SKAction.resize(toWidth: MIDINode.defaultSize.width,
                                        height: MIDINode.defaultSize.height,
                                        duration: halfDuration)

        // Send the 'note off' event
        let noteOff = SKAction.run { coordinator.sendNoteOff() }

        // Group the 'note on' and scale up actions.
        let scaleUpAndNoteOn = SKAction.group([scaleUp, noteOn])

        // Return as a sequence.
        return SKAction.sequence([scaleUpAndNoteOn, scaleDown, noteOff])

      case .fadeOut:

        // Fade the node.
        let fade = SKAction.fadeOut(withDuration: 0.25)

        // Send 'note off' event and pause the node.
        let pause = SKAction.run
        {
          coordinator.sendNoteOff(); coordinator.node.isPaused = true
        }

        // Return as a sequence.
        return SKAction.sequence([fade, pause])

      case .fadeOutAndRemove:

        // Fade the node.
        let fade = SKAction.fadeOut(withDuration: 0.25)

        // Remove the node from it's parent.
        let remove = SKAction.removeFromParent()

        // Return as a sequence.
        return SKAction.sequence([fade, remove])

      case .fadeIn:

        // Fade the node.
        let fade = SKAction.fadeIn(withDuration: 0.25)

        // Unpause the node.
        let unpause = SKAction.run { coordinator.node.isPaused = false }

        // Return as a sequence
        return SKAction.sequence([fade, unpause])
    }
  }

  /// Runs `action` on `node` keyed by `key.rawValue`
  func run() { coordinator.node.run(action, withKey: key.rawValue) }

  // MARK: Key

  /// Enumeration of the available actions.
  enum Key: String
  {
    /// Move the node along its current segment to that segment's end location,
    /// at which point the node runs `play`, the node's segment is updated and
    /// the action is repeated.
    case move

    /// Send the node's 'note on' event, scale up for half the note's duration,
    /// scale back down for half the note's duration and send the node's
    /// 'note off' event.
    case play

    /// Fade out the node.
    case fadeOut

    /// Fade out the node and remove it from it's parent node.
    case fadeOutAndRemove

    /// Fade in the node.
    case fadeIn
  }

}
