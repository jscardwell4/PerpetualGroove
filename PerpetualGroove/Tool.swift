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

protocol ToolType: TouchReceiver {
  var active: Bool { get set }

}

protocol PresentingToolType: ToolType, SecondaryControllerContentProvider {}

enum Tool: Int {
  case none = -1
  case newNodeGenerator
  case addNode
  case removeNode
  case deleteNode
  case nodeGenerator
  case rotate
  case loopStart
  case loopEnd
  case loopToggle

  var toolType: ToolType? {
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

  init(_ int: Int) { self = Tool(rawValue: int) ?? .none }
  init(_ toolType: ToolType?) {
    switch toolType {
      case let t? where MIDIPlayer.newGeneratorTool === t:      self = .newNodeGenerator
      case let t? where MIDIPlayer.addTool === t:               self = .addNode
      case let t? where MIDIPlayer.removeTool === t:            self = .removeNode
      case let t? where MIDIPlayer.deleteTool === t:            self = .deleteNode
      case let t? where MIDIPlayer.existingGeneratorTool === t: self = .nodeGenerator
      default:                                                  self = .none
    }
  }

}
