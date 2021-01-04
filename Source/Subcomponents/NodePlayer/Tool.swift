//
//  Tool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/13/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import UIKit
import MoonKit
import Common

/// Protocol for types that provide an interface for generating or modifying `MIDINode` instances.
public protocol Tool: TouchReceiver {

  /// Whether the tool is currently receiving touch events.
  var active: Bool { get set }

}

/// Protocol for a `Tool` that provides secondary content.
public protocol PresentingTool: Tool, SecondaryContentProvider {}

/// Enumeration of the possible tools.
public enum AnyTool: Int {

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

  /// The current corresponding instance of the tool. This is `nil` for `none` and one of the
  /// `MIDINodePlayer` tools otherwise.
  public var tool: Tool? {
    switch self {
      case .none:              return nil
      case .newNodeGenerator:  return MIDINodePlayer.newGeneratorTool
      case .addNode:           return MIDINodePlayer.addTool
      case .removeNode:        return MIDINodePlayer.removeTool
      case .deleteNode:        return MIDINodePlayer.deleteTool
      case .nodeGenerator:     return MIDINodePlayer.existingGeneratorTool
      case .rotate:            return MIDINodePlayer.rotateTool
    }
  }

  /// Whether the tool is player's current tool.
  public var isCurrentTool: Bool { return MIDINodePlayer.currentTool == self }

  /// Non-optional initalizer from `rawValue`. Invalid values return `none`.
  public init(_ int: Int) { self = AnyTool(rawValue: int) ?? .none }

  /// Initialize from the instance of a tool. Initialize to `none` if `tool` is `nil`.
  /// `tool` must be an instance owned by `MIDINodePlayer` otherwise it is as if `tool == nil`.
  public init(_ tool: Tool?) {

    guard let tool = tool,
          MIDINodePlayer.playerNode != nil
      else
    {
      self = .none
      return
    }

    switch ObjectIdentifier(tool) {
      case ObjectIdentifier(MIDINodePlayer.newGeneratorTool!):      self = .newNodeGenerator
      case ObjectIdentifier(MIDINodePlayer.addTool!):               self = .addNode
      case ObjectIdentifier(MIDINodePlayer.removeTool!):            self = .removeNode
      case ObjectIdentifier(MIDINodePlayer.deleteTool!):            self = .deleteNode
      case ObjectIdentifier(MIDINodePlayer.existingGeneratorTool!): self = .nodeGenerator
      default:                                                      self = .none
    }

  }

}
