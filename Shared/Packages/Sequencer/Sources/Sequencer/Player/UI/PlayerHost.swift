//
//  PlayerHost.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI
import SpriteKit

// MARK: - PlayerHost

/// A view for hosting the `SKView` presenting the scene used to drive the sequencer.
@available(iOS 14.0, *)
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
@available(iOS 14.0, *)
private struct _PlayerHost: UIViewRepresentable
{
  /// Creates the hosted instance of `PlayerSKView`.
  public func makeUIView(context: Context) -> SKView
  {
    let scene = PlayerScene(size: CGSize(width: 447, height: 447))
    let view  = SKView(frame: CGRect(size: CGSize(width: 447, height: 447)))
    view.ignoresSiblingOrder = true
    view.shouldCullNonVisibleNodes = false
    view.showsFPS = true
    view.showsNodeCount = true
    view.presentScene(scene)
    return view
  }
  
  /// Updates the hosted instance of `PlayerSKView`.
  ///
  /// - Notice: This method currently does nothing.
  ///
  /// - Parameters:
  ///   - uiView: The hosted view.
  ///   - context: This parameter is ignored.
  public func updateUIView(_ uiView: SKView, context: Context) {}
}

// MARK: - PlayerHost_Previews
@available(iOS 14.0, *)
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
