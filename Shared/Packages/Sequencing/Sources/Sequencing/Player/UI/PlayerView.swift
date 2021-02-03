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
  /// The sequencer loaded into the enviroment by `GrooveApp`.
  @EnvironmentObject var sequencer: Sequencer

  /// The sequencer's player loaded into the environment by `ContentView`.
  @EnvironmentObject var player: Player

  /// The player view encapsulates the host for an instance of `PlayerSKView`,
  /// a text field for displaying and modifying the name of the currently loaded
  /// document, and a horizontal toolbar containing buttons for the player's tools.
  public var body: some View
  {
      VStack
      {
        GeometryReader
        {
          let side = min($0.size.width, $0.size.height)
          PlayerHost(side: side)
            .frame(width: side, height: side, alignment: .center)
        }
        HStack(spacing: 20)
        {
          Spacer()
          Group
          {
          ToolButton(model: .newNodeGenerator,
                     isSelected: player.currentTool == .newNodeGenerator)
          ToolButton(model: .addNode,
                     isSelected: player.currentTool == .addNode)
          ToolButton(model: .removeNode,
                     isSelected: player.currentTool == .removeNode)
          ToolButton(model: .deleteNode,
                     isSelected: player.currentTool == .deleteNode)
          ToolButton(model: .nodeGenerator,
                     isSelected: player.currentTool == .nodeGenerator)
          ToolButton(model: .rotate,
                     isSelected: player.currentTool == .rotate)
          }
          .onPreferenceChange(CurrentTool.self)
          {
//            logi("<\(#fileID) \(#function)> $0 = \($0)")
            player.currentTool = $0.first ?? .none
          }

          Spacer()
          Group
          {
            if sequencer.mode == .loop
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
        .frame(height: 44)
      }
      .accentColor(.primaryColor1)
  }

  public init() {}
}

// MARK: - CurrentTool

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct CurrentTool: PreferenceKey
{
  static var defaultValue: Set<AnyTool> = []
  static func reduce(value: inout Set<AnyTool>, nextValue: () -> Set<AnyTool>)
  {
    value.formUnion(nextValue())
  }
}
