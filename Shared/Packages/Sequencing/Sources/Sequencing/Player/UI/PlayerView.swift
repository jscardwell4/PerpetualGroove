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

  /// The player view encapsulates the host for an instance of `PlayerSKView`,
  /// a text field for displaying and modifying the name of the currently loaded
  /// document, and a horizontal toolbar containing buttons for the player's tools.
  public var body: some View
  {
    GeometryReader
    {
      let 𝘴 = min($0.size.width, $0.size.height)
      PlayerHost(side: 𝘴).frame(width: 𝘴, height: 𝘴, alignment: .center)
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
