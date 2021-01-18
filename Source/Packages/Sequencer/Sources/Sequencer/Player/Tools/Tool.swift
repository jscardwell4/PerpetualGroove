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

// MARK: - Tool

/// Protocol for types that provide an interface for generating or modifying
/// `Node` instances.
@available(iOS 14.0, *)
public protocol Tool: TouchReceiver
{
  /// Whether the tool is currently receiving touch events.
  var active: Bool { get set }
}

// MARK: - PresentingTool

/// Protocol for a `Tool` that provides secondary content.
@available(iOS 14.0, *)
public protocol PresentingTool: Tool, SecondaryContentProvider {}

// MARK: - AnyTool

/// Enumeration of the possible tools.
@available(iOS 14.0, *)
public enum AnyTool: Int
{
  /// The empty tool.
  case none = -1

  /// Tool for configuring the generator used when adding new nodes.
  case newNodeGenerator

  /// Tool for adding new nodes.
  case addNode

  /// Tool for generating node removal events.
  case removeNode

  /// Tool for erasing nodes.
  case deleteNode

  /// Tool for editing the generator for existing nodes.
  case nodeGenerator

  /// Tool for modifiying the initial trajectory of a node.
  case rotate

  /// The current corresponding instance of the tool. This is `nil` for
  /// `none` and one of the `Player` tools otherwise.
  public var tool: Tool?
  {
    switch self
    {
      case .none: return nil
      case .newNodeGenerator: return player.newGeneratorTool
      case .addNode: return player.addTool
      case .removeNode: return player.removeTool
      case .deleteNode: return player.deleteTool
      case .nodeGenerator: return player.existingGeneratorTool
      case .rotate: return player.rotateTool
    }
  }

  /// Whether the tool is player's current tool.
  public var isCurrentTool: Bool { player.currentTool == self }

  /// Non-optional initalizer from `rawValue`. Invalid values return `none`.
  public init(_ int: Int) { self = AnyTool(rawValue: int) ?? .none }

  /// Initialize from the instance of a tool. Initialize to `none` if `tool`
  /// is `nil`.`tool` must be an instance owned by `NodePlayer` otherwise it
  /// is as if `tool == nil`.
  public init(_ tool: Tool?)
  {
    guard let tool = tool,
          player.playerNode != nil
    else
    {
      self = .none
      return
    }

    switch ObjectIdentifier(tool)
    {
      case ObjectIdentifier(player.newGeneratorTool!): self = .newNodeGenerator
      case ObjectIdentifier(player.addTool!): self = .addNode
      case ObjectIdentifier(player.removeTool!): self = .removeNode
      case ObjectIdentifier(player.deleteTool!): self = .deleteNode
      case ObjectIdentifier(player.existingGeneratorTool!): self = .nodeGenerator
      default: self = .none
    }
  }
}
