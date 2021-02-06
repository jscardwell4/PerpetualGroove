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

/// A view for hosting the `SKView` presenting the scene used to drive the Controller.shared.
//@available(iOS 14.0, *)
//@available(macCatalyst 14.0, *)
//@available(OSX 10.15, *)
//struct PlayerHost: UIViewRepresentable
//{
//   private let size: CGSize
//
//  /// Creates the hosted instance of `PlayerSKView`.
//  func makeUIView(context: Context) -> SKView
//  {
//    let scene = PlayerScene(size: size)
//    let view  = SKView(frame: CGRect(size: size))
//    view.ignoresSiblingOrder = true
//    view.shouldCullNonVisibleNodes = false
//    view.showsFPS = true
//    view.showsNodeCount = true
//    view.presentScene(scene)
//    return view
//  }
//  
//  /// Updates the hosted instance of `PlayerSKView`.
//  ///
//  /// - Notice: This method currently does nothing.
//  ///
//  /// - Parameters:
//  ///   - uiView: The hosted view.
//  ///   - context: This parameter is ignored.
//  func updateUIView(_ uiView: SKView, context: Context) {}
//
//  init(side: CGFloat)
//  {
//    size = CGSize(width: side, height: side)
//  }
//}
