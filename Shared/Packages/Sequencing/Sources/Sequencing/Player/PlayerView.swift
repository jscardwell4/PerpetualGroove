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

  /// The player view encapsulates the host for an instance of `PlayerSKView`,
  /// a text field for displaying and modifying the name of the currently loaded
  /// document, and a horizontal toolbar containing buttons for the player's tools.
  public var body: some View
  {
    GeometryReader { PlayerSpriteView(size: CGSize(square: $0.size.minValue)) }
  }

  public init() {}
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
private struct PlayerSpriteView: View
{
  @EnvironmentObject var player: Player

  @Environment(\.enableMockData) static var enableMockData: Bool

  private let scene: SKScene
  private let playerNode: PlayerNode

  var body: some View
  {
    SpriteView(scene: scene,
               transition: nil,
               isPaused: false,
               preferredFramesPerSecond: 60,
               options: [.shouldCullNonVisibleNodes, .ignoresSiblingOrder],
               shouldRender: {_ in true})
  }

  init(size: CGSize) { (scene, playerNode) = PlayerSpriteView.buildScene(size) }

  private static func buildScene(_ size: CGSize) -> (SKScene, PlayerNode)
  {
    let scene = BouncingPlayerScene()
    scene.scaleMode = .fill
    scene.size = size
    scene.physicsWorld.gravity = .zero
    scene.backgroundColor = .backgroundColor2

    let playerNode = PlayerNode(bezierPath: UIBezierPath(rect: CGRect(size: size)))
    scene.addChild(playerNode)

    if enableMockData { scene.populate() }

    return (scene, playerNode)
  }
}
