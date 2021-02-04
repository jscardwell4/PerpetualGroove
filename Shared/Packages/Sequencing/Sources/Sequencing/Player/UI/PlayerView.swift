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
    GeometryReader
    {
      proxy in

      let pad_vertical: CGFloat = 10 // Constant for spacing from top and bottom.
      let 𝘩_toolbar: CGFloat = 44 // Constant height for the toolbar.

      let 𝘸 = proxy.size.width // Total available width.
      let 𝘩 = proxy.size.height // Total available height.
      let 𝘩_player = min(𝘸, 𝘩) - 𝘩_toolbar - pad_vertical // The player height.

      VStack(spacing: 0)
      {
        PlayerHost(side: 𝘩_player)
          .frame(width: 𝘩_player, height: 𝘩_player, alignment: .center)
          .padding(.top, pad_vertical)

        Toolbar()
          .environmentObject(sequencer.sequence)
          .frame(width: 𝘸, height: 𝘩_toolbar, alignment: .center)
      }
    }

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
