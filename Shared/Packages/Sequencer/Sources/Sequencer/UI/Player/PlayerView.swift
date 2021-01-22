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
  /// The currently active tool or `.none` if no tool is currently active.
  @State private var currentTool = AnyTool.none

  /// The currently active mode.
  @State private var currentMode = sequencer.mode

  /// Holds the view's subscriptions.
  private var subscriptions: Set<AnyCancellable> = []

  /// Initializer simply configures the view's subscriptions.
  public init()
  {
    player.$currentTool.assign(to: \.currentTool, on: self).store(in: &subscriptions)
    sequencer.$mode.assign(to: \.currentMode, on: self).store(in: &subscriptions)
  }

  /// The player view encapsulates the host for an instance of `PlayerSKView`,
  /// a text field for displaying and modifying the name of the currently loaded
  /// document, and a horizontal toolbar containing buttons for the player's tools.
  public var body: some View
  {
    VStack
    {
      PlayerHost()

      HStack
      {
        Spacer()
        ToolButton(tool: .newNodeGenerator)
        ToolButton(tool: .addNode)
        ToolButton(tool: .removeNode)
        ToolButton(tool: .deleteNode)
        ToolButton(tool: .nodeGenerator)
        ToolButton(tool: .rotate)
        Spacer()

        Group
        {
          if currentMode == .loop
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
