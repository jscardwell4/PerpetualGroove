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

// TODO: Nudge, Throttle, Rotate tools

protocol Tool: TouchReceiver {

  var active: Bool { get set }

}

protocol PresentingTool: Tool, SecondaryControllerContentProvider {}

enum AnyTool: Int {
  case none = -1, newNodeGenerator, addNode, removeNode, deleteNode,
       nodeGenerator, rotate, loopStart, loopEnd, loopToggle

  var tool: Tool? {
    switch self {
      case .none:              return nil
      case .newNodeGenerator:  return MIDINodePlayer.newGeneratorTool
      case .addNode:           return MIDINodePlayer.addTool
      case .removeNode:        return MIDINodePlayer.removeTool
      case .deleteNode:        return MIDINodePlayer.deleteTool
      case .nodeGenerator:     return MIDINodePlayer.existingGeneratorTool
      case .rotate:            return MIDINodePlayer.rotateTool
      case .loopStart:         return nil
      case .loopEnd:           return nil
      case .loopToggle:        return nil
    }
  }

  var isCurrentTool: Bool { return MIDINodePlayer.currentTool == self }

  init(_ int: Int) { self = AnyTool(rawValue: int) ?? .none }

  init(_ tool: Tool?) {
    guard let tool = tool, MIDINodePlayer.playerNode != nil else { self = .none; return }

    switch ObjectIdentifier(tool) {
      case ObjectIdentifier(MIDINodePlayer.newGeneratorTool!):      self = .newNodeGenerator
      case ObjectIdentifier(MIDINodePlayer.addTool!):               self = .addNode
      case ObjectIdentifier(MIDINodePlayer.removeTool!):            self = .removeNode
      case ObjectIdentifier(MIDINodePlayer.deleteTool!):            self = .deleteNode
      case ObjectIdentifier(MIDINodePlayer.existingGeneratorTool!): self = .nodeGenerator
      default:                                                  self = .none
    }
  }

}
