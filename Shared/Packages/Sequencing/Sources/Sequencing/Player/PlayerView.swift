//
//  PlayerView.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import MoonDev
import SpriteKit
import SwiftUI

// MARK: - PlayerView

/// A view encapsulating the node player with limited editing functionality.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct PlayerView: View
{
  @Environment(\.player) var player: Player

  /// The player view encapsulates the host for an instance of `PlayerSKView`,
  /// a text field for displaying and modifying the name of the currently loaded
  /// document, and a horizontal toolbar containing buttons for the player's tools.
  public var body: some View
  {
    SpriteView(scene: player.scene,
               transition: nil,
               isPaused: false,
               preferredFramesPerSecond: 60,
               options: [.shouldCullNonVisibleNodes, .ignoresSiblingOrder])
    {
      timeInterval in
      player.playerNode.midiNodes.forEach
      {
        $0?.coordinator.updatePosition(timeInterval)
      }
      return true
    }
    .gesture(DragGesture().onChanged(update(for:)))
  }

  public init() {}

  private func update(for value: DragGesture.Value)
  {
    logi("<\(#fileID) \(#function)> value: \(value)")
  }
}
