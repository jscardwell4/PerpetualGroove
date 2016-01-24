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
  func didShowViewController(viewController: UIViewController)
  func didHideViewController(viewController: UIViewController)
  var viewController: UIViewController { get }
  var isShowingViewController: Bool { get }
}

enum Tool: Int {
  case None = -1
  case NewNodeGenerator = 0
  case AddNode = 1
  case RemoveNode = 2
  case DeleteNode = 3
  case NodeGenerator = 4
  case LoopStart = 5
  case LoopEnd = 6
  case LoopToggle = 7

  var toolType: ToolType? {
    switch self {
      case .None:              return nil
      case .NewNodeGenerator:  return MIDIPlayer.newGeneratorTool
      case .AddNode:           return MIDIPlayer.addTool
      case .RemoveNode:        return MIDIPlayer.removeTool
      case .DeleteNode:        return MIDIPlayer.deleteTool
      case .NodeGenerator:     return MIDIPlayer.existingGeneratorTool
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
