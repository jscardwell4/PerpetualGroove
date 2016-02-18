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

protocol ToolType: class {
  var active: Bool { get set }
  func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)
  func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?)
  func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?)
  func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?)
}

protocol ConfigurableToolType: ToolType {
  func didShowViewController(viewController: SecondaryContentViewController)
  func didHideViewController(viewController: SecondaryContentViewController)
  var viewController: SecondaryContentViewController { get }
  var isShowingViewController: Bool { get }
}

enum Tool: Int {
  case None = -1
  case NewNodeGenerator
  case AddNode
  case RemoveNode
  case DeleteNode
  case NodeGenerator
  case Rotate
  case LoopStart
  case LoopEnd
  case LoopToggle

  var toolType: ToolType? {
    switch self {
      case .None:              return nil
      case .NewNodeGenerator:  return MIDIPlayer.newGeneratorTool
      case .AddNode:           return MIDIPlayer.addTool
      case .RemoveNode:        return MIDIPlayer.removeTool
      case .DeleteNode:        return MIDIPlayer.deleteTool
      case .NodeGenerator:     return MIDIPlayer.existingGeneratorTool
      case .Rotate:            return MIDIPlayer.rotateTool
      case .LoopStart:         return nil
      case .LoopEnd:           return nil
      case .LoopToggle:        return nil
    }
  }

  var isCurrentTool: Bool { return MIDIPlayer.currentTool == self }

  init(_ int: Int) { self = Tool(rawValue: int) ?? .None }
  init(_ toolType: ToolType?) {
    switch toolType {
      case let t? where MIDIPlayer.newGeneratorTool === t:      self = .NewNodeGenerator
      case let t? where MIDIPlayer.addTool === t:               self = .AddNode
      case let t? where MIDIPlayer.removeTool === t:            self = .RemoveNode
      case let t? where MIDIPlayer.deleteTool === t:            self = .DeleteNode
      case let t? where MIDIPlayer.existingGeneratorTool === t: self = .NodeGenerator
      default:                                                  self = .None
    }
  }

}
