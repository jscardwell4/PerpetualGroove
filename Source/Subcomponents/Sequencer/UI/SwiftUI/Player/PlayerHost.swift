//
//  PlayerHost.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - PlayerView

public struct PlayerHost: UIViewRepresentable
{
  public func makeUIView(context: Context) -> PlayerSKView
  {
    PlayerSKView(frame: CGRect(x: 0, y: 0, width: 447, height: 447))
  }

  public func updateUIView(_ uiView: PlayerSKView, context: Context) {}
}
