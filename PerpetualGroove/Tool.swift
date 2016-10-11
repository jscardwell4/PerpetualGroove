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
      case .newNodeGenerator:  return MIDIPlayer.newGeneratorTool
      case .addNode:           return MIDIPlayer.addTool
      case .removeNode:        return MIDIPlayer.removeTool
      case .deleteNode:        return MIDIPlayer.deleteTool
      case .nodeGenerator:     return MIDIPlayer.existingGeneratorTool
      case .rotate:            return MIDIPlayer.rotateTool
      case .loopStart:         return nil
      case .loopEnd:           return nil
      case .loopToggle:        return nil
    }
  }

  var isCurrentTool: Bool { return MIDIPlayer.currentTool == self }

  init(_ int: Int) { self = AnyTool(rawValue: int) ?? .none }

  init(_ tool: Tool?) {
    guard let tool = tool, MIDIPlayer.playerNode != nil else { self = .none; return }

    switch ObjectIdentifier(tool) {
      case ObjectIdentifier(MIDIPlayer.newGeneratorTool!):      self = .newNodeGenerator
      case ObjectIdentifier(MIDIPlayer.addTool!):               self = .addNode
      case ObjectIdentifier(MIDIPlayer.removeTool!):            self = .removeNode
      case ObjectIdentifier(MIDIPlayer.deleteTool!):            self = .deleteNode
      case ObjectIdentifier(MIDIPlayer.existingGeneratorTool!): self = .nodeGenerator
      default:                                                  self = .none
    }
  }

}
