//
//  PlayerView.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import MoonDev
import SwiftUI
import SpriteKit

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
               options: [.shouldCullNonVisibleNodes, .ignoresSiblingOrder],
               shouldRender: {_ in true})
  }

  public init() {}
}

