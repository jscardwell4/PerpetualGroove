//
//  PlayerView.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import MoonDev
import SwiftUI

// MARK: - PlayerView

/// A view encapsulating the node player with limited editing functionality.
@available(iOS 14.0, *)
public struct PlayerView: View
{
  /// The controller for the player.
  @EnvironmentObject private var controller: Controller

  /// The player.
  @EnvironmentObject private var player: Player

  /// The player view encapsulates the host for an instance of `PlayerSKView`,
  /// a text field for displaying and modifying the name of the currently loaded
  /// document, and a horizontal toolbar containing buttons for the player's tools.
  public var body: some View
  {
    VStack
    {
      PlayerHost()

      HStack(spacing: 20)
      {
        Spacer()
        ToolButton(tool: .newNodeGenerator, currentTool: $player.currentTool)
        ToolButton(tool: .addNode, currentTool: $player.currentTool)
        ToolButton(tool: .removeNode, currentTool: $player.currentTool)
        ToolButton(tool: .deleteNode, currentTool: $player.currentTool)
        ToolButton(tool: .nodeGenerator, currentTool: $player.currentTool)
        ToolButton(tool: .rotate, currentTool: $player.currentTool)
        Spacer()

        Group
        {
          if controller.mode == .loop
          {
            LoopButton(action: .beginRepeat)
            LoopButton(action: .endRepeat)
            LoopButton(action: .cancelLoop)
            LoopButton(action: .confirmLoop)
          }
          else
          {
            LoopButton(action: .toggleLoop)
          }
        }
        Spacer()
      }
      .padding()
    }
    .frame(width: 447)
    .accentColor(.primaryColor1)
  }

  public init(){}
}

// MARK: - PlayerView_Previews

@available(iOS 14.0, *)
struct PlayerView_Previews: PreviewProvider
{
  static var previews: some View
  {
    PlayerView()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .padding()
  }
}
