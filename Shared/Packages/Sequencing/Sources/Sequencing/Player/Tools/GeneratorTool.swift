//
//  GeneratorTool.swift
//  Sequencing
//
//  Created by Jason Cardwell on 2/8/21.
//
import Combine
import MIDI
import MoonDev
import SoundFont
import SpriteKit
import SwiftUI

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
final class GeneratorTool: NodeSelectionTool
{
  // Enumeration of the supported modes for which the tool can be configured.
  public enum Mode
  {
    /// The tool is used to configure the generator assigned to new node placements.
    case new

    /// The tool is used to configure the generator assigned to an existing node.
    case existing
  }

  /// Specifies whether the generator is applied to new or existing nodes.
  let mode: Mode

  /// Initialize with a player node and mode.
  init(mode: Mode)
  {
    self.mode = mode
  }

  /// Callback for changes to the secondary content's generator.
  private func didChangeGenerator(_ generator: AnyGenerator)
  {
    // Check that there is a node selected.
    guard let node = node else { return }

    // Register an action for undoing the changes to the node's generator.
    player.undoManager.registerUndo(withTarget: node)
    {
      [self, initialGenerator = node.coordinator.generator] node in

      node.coordinator.generator = initialGenerator

      // Register an action for redoing the changes to the node's generator.
      player.undoManager
        .registerUndo(withTarget: node) { $0.coordinator.generator = generator }
    }

    // Actually change the node's generator.
    node.coordinator.generator = generator
  }
}
