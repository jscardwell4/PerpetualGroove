//
//  Player.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/5/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Combine
import struct Common.Trajectory
import Foundation
import MIDI
import MoonDev
import SpriteKit
import UIKit
import SwiftUI

// MARK: - Player

/// Coordinates `Node` and `PlayerNode` operations.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public final class Player: ObservableObject
{
  // MARK: Environment

  @Environment(\.enableMockData) static var enableMockData: Bool

  @Environment(\.currentTransport) var currentTransport: Transport
  @Environment(\.linearTransport) var linearTransport: Transport
  @Environment(\.loopTransport) var loopTransport: Transport
  @Environment(\.currentMode) var currentMode: Mode

  // MARK: Properties

  /// The scene's size.
  public var sceneSize: CGSize {
    didSet
    {
      scene.size = sceneSize
      playerNode.size = sceneSize
    }
    
  }

  /// The scene generated for the player.
  let scene: SKScene

  /// The player node held by `scene`.
  let playerNode: PlayerNode

  /// The manager for undoing `Node` operations.
  let undoManager = UndoManager()

  /// The object through which new node events are dispatched.
  @Published var currentDispatch: NodeDispatch?

  private var lastAdded: CurrentValueSubject<MIDINode?, Never> = CurrentValueSubject(nil)


  private var lastRemoved: CurrentValueSubject<MIDINode?, Never> = CurrentValueSubject(nil)

  public func resize(_ newSize: CGSize) { scene.size = newSize }

  // MARK: Undo Support

  /// Invokes `undoManager.undo()` when `undoManager.canUndo`.
  /// Returns `true` iff `undo()` was invoked.
  @discardableResult
  public func rollBack() -> Bool
  {
    guard undoManager.canUndo else { return false }
    if undoManager.groupingLevel > 0 { undoManager.endUndoGrouping() }
    undoManager.undo()
    return true
  }

  // MARK: Initializing

  public init(size: CGSize)
  {
    sceneSize = size
    (scene, playerNode) = Player.buildScene(size)
    undoManager.groupsByEvent = false
  }

  // MARK: Placing and Removing Nodes

  /// Creates a new `Node` object using the specified parameters and adds it
  /// to `playerNode`.
  func placeNew(trajectory: Trajectory,
                target: NodeDispatch,
                generator: AnyGenerator,
                identifier: UUID = UUID())
  {
    dispatchToMain
    { [self] in
      do
      {
        // Generate a name for the node composed of the current sequencer mode
        // and the name provided by target.
        let name = "<\(currentMode.rawValue)> \(target.nextNodeName)"

        // Create and add the node to the player node.
        let node = try MIDINode(transport: currentTransport,
                                trajectory: trajectory,
                                name: name,
                                dispatch: target,
                                generator: generator,
                                identifier: identifier,
                                playerSize: playerNode.size)
        playerNode.addChild(node)

        // Hand off the newly created node to the target's manager to handle
        // connecting, etc.
        try target.nodeManager.add(node: node)

        // Initiate playback if the transport is not currently playing.
        if !currentTransport.isPlaying { currentTransport.isPlaying = true }
        lastAdded.send(node)
      }
      catch
      {
        loge("\(error as NSObject)")
      }
    }
  }

  /// Removes `node` from the player node.
  public func remove(node: MIDINode)
  {
    dispatchToMain
    {
      [self] in
      // Check that `node` is a child of `playerNode`.
      guard node.parent === playerNode else { return }

      // Fade out and remove `node`.
      node.coordinator.fadeOut(remove: true)
      lastRemoved.send(node)
    }
  }

  // MARK: Scene building
  private static func buildScene(_ size: CGSize) -> (SKScene, PlayerNode)
  {
    let scene = BouncingPlayerScene()
    scene.scaleMode = .fill
    scene.size = size
    scene.physicsWorld.gravity = .zero
    scene.backgroundColor = .backgroundColor2

    let playerNode = PlayerNode(rect: CGRect(size: size))
    scene.addChild(playerNode)

    if enableMockData { scene.populate() }

    return (scene, playerNode)
  }

}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension Player
{
  public enum PublishedSubject { case lastAdded, lastRemoved }

  public func publisher(for subject: PublishedSubject) -> AnyPublisher<MIDINode?, Never>
  {
    switch subject
    {
      case .lastAdded: return lastAdded.eraseToAnyPublisher()
      case .lastRemoved: return lastRemoved.eraseToAnyPublisher()
    }
  }
}
