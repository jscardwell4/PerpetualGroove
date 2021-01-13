//
//  PlayerHost.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - PlayerHost

/// A view for hosting the `SpriteKit` scene used to drive the sequencer.
public struct PlayerHost: View
{
  /// The view's body is simply the wrapped host.
  public var body: some View
  {
    _PlayerHost()
      .frame(width: 447, height: 447)
  }
}

// MARK: - _PlayerHost

/// A structure for wrapping an instance of `PlayerSKView`.
private struct _PlayerHost: UIViewRepresentable
{
  /// Creates the hosted instance of `PlayerSKView`.
  public func makeUIView(context: Context) -> PlayerSKView
  {
    PlayerSKView(frame: CGRect(x: 0, y: 0, width: 447, height: 447))
  }
  
  /// Updates the hosted instance of `PlayerSKView`.
  ///
  /// - Notice: This method currently does nothing.
  ///
  /// - Parameters:
  ///   - uiView: The hosted view.
  ///   - context: This parameter is ignored.
  public func updateUIView(_ uiView: PlayerSKView, context: Context) {}
}

// MARK: - PlayerHost_Previews

struct PlayerHost_Previews: PreviewProvider
{
  static var previews: some View
  {
    PlayerHost()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .padding()
  }
}
