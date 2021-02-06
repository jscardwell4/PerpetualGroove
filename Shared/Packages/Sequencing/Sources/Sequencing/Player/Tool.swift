//
//  Tool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/13/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Common
import Foundation
import MoonDev
import UIKit
import SwiftUI

// MARK: - Tool

/// Protocol for types that provide an interface for generating or modifying
/// `Node` instances.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public protocol Tool: TouchReceiver
{
  /// Whether the tool is currently receiving touch events.
  var active: Bool { get set }
}

// MARK: - PresentingTool

/// Protocol for a `Tool` that provides secondary content.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public protocol PresentingTool: Tool {}

// MARK: - AnyTool

/// Enumeration of the possible tools.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public enum AnyTool: String, CustomStringConvertible
{
  /// The empty tool.
  case none = ""

  /// Tool for configuring the generator used when adding new nodes.
  case newNodeGenerator = "node_note_add"

  /// Tool for adding new nodes.
  case addNode = "node_add"

  /// Tool for generating node removal events.
  case removeNode = "node_remove"

  /// Tool for erasing nodes.
  case deleteNode = "node_delete"

  /// Tool for editing the generator for existing nodes.
  case nodeGenerator = "node_note"

  /// Tool for modifiying the initial trajectory of a node.
  case rotate = "node_rotate"

  /// The current corresponding instance of the tool. This is `nil` for
  /// `none` and one of the `Player` tools otherwise.
  public var tool: Tool?
  {
    switch self
    {
//      case .newNodeGenerator: return player.newGeneratorTool
      case .addNode: return Sequencer.shared.player.addTool
      case .removeNode: return Sequencer.shared.player.removeTool
      case .deleteNode: return Sequencer.shared.player.deleteTool
//      case .nodeGenerator: return player.existingGeneratorTool
//      case .rotate: return player.rotateTool
      default: return nil
    }
  }

  /// A short description of the tool.
  public var description: String {
    switch self
    {
      case .none: return "none"
      case .newNodeGenerator: return "newNodeGenerator"
      case .addNode: return "addNode"
      case .removeNode: return "removeNode"
      case .deleteNode: return "deleteNode"
      case .nodeGenerator: return "nodeGenerator"
      case .rotate: return "rotate"
    }
  }

  public var image: Image { Image(rawValue, bundle: .module) }

  /// Whether the tool is player's current tool.
  public var isCurrentTool: Bool { Sequencer.shared.player.currentTool == self }

  /// Initialize from the instance of a tool. Initialize to `none` if `tool`
  /// is `nil`.`tool` must be an instance owned by `NodePlayer` otherwise it
  /// is as if `tool == nil`.
  public init(_ tool: Tool?)
  {
    self = .none
    guard let tool = tool,
          Sequencer.shared.player.playerNode != nil
    else
    {
      self = .none
      return
    }

    switch ObjectIdentifier(tool)
    {
//      case ObjectIdentifier(player.newGeneratorTool!): self = .newNodeGenerator
      case ObjectIdentifier(Sequencer.shared.player.addTool!): self = .addNode
      case ObjectIdentifier(Sequencer.shared.player.removeTool!): self = .removeNode
      case ObjectIdentifier(Sequencer.shared.player.deleteTool!): self = .deleteNode
//      case ObjectIdentifier(player.existingGeneratorTool!): self = .nodeGenerator
      default: self = .none
    }
  }
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension AnyTool: CaseIterable
{
  public static let allCases: [AnyTool] = [.newNodeGenerator,
                                           .addNode,
                                           .removeNode,
                                           .deleteNode,
                                           .nodeGenerator,
                                           .rotate]
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension AnyTool: Identifiable
{
  public var id: String { rawValue }
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension AnyTool: Hashable, Equatable {}
