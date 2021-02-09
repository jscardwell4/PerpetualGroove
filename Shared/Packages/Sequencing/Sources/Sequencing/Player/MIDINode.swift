//
//  MIDINode.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/12/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Combine
import struct Common.Trajectory
import CoreMIDI
import MIDI
import MoonDev
import SpriteKit
import UIKit
import SwiftUI

// MARK: - MIDINode

/// A sprite node that transmits MIDI messages upon making contact with scene boundaries.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public final class MIDINode: SKSpriteNode
{

  /// Default initializer for creating an instance of `Node`.
  ///
  /// - Parameters:
  ///   - trajectory: The initial trajectory for the node.
  ///   - name: The unique name for the node.
  ///   - dispatch: The object responsible for the node.
  ///   - identifier: A `UUID` used to uniquely identify this node across invocations.
  ///   - playerSize: The size of the player to which the node is being added.
  init(transport: Transport,
       trajectory: Trajectory,
       name: String,
       dispatch: NodeDispatch,
       generator: AnyGenerator,
       identifier: UUID = UUID(),
       playerSize: CGSize) throws
  {
    self.dispatch = dispatch
    coordinator = try NodeActionCoordinator(name: name,
                                            trajectory: trajectory,
                                            generator: generator,
                                            identifier: identifier,
                                            initTime: transport.time.barBeatTime,
                                            transport: transport,
                                            playerSize: playerSize)


    // Invoke `super` now that properties have been initialized.
    super.init(texture: MIDINode.texture,
               color: UIColor(dispatch.color),
               size: MIDINode.texture.size() * 0.75)

    // Finish configuring the node.
    self.name = name
    colorBlendFactor = 1
    position = trajectory.position
    normalTexture = MIDINode.normalMap

    // Start the node's movement.
    coordinator.node = self
    coordinator.move()
  }

  /// Initializing from a coder is not supported.
  @available(*, unavailable)
  public required init?(coder _: NSCoder)
  {
    fatalError("\(#function) has not been implemented")
  }


  /// Overridden to ensure `sendNoteOff` is invoked when the play action is removed.
  override public func removeAction(forKey key: String)
  {
    coordinator.didRemoveAction(for: key)
    super.removeAction(forKey: key)
  }

  /// The object responsible for handling the node's midi connections and management.
  /// Setting this property to `nil` will remove it from it's parent node when such
  /// a node exists.
  weak var dispatch: NodeDispatch?
  {
    didSet { if dispatch == nil, parent != nil { removeFromParent() } }
  }

  let coordinator: NodeActionCoordinator

  /// The texture used by all `Node` instances.
  static let texture = SKTexture(image: UIImage(named: "ball",
                                                in: Bundle.module,
                                                compatibleWith: nil)!)

  /// The normal map used by all `Node` instances.
  static let normalMap = MIDINode.texture.generatingNormalMap()

  /// The size of a node when it has no active notes.
  public static let defaultSize: CGSize = MIDINode.texture.size() * 0.75

  /// The size of a node when it has at least one active note.
  public static let playingSize: CGSize = MIDINode.texture.size()

}
