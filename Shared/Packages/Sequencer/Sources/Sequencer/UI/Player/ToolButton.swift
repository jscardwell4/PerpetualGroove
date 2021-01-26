//
//  ToolButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - ToolButton

/// A view to serve as a button for selecting one the player's tools.
@available(iOS 14.0, *)
public struct ToolButton: View
{
  /// The tool represented by this button.
  let tool: AnyTool

  @Binding var currentTool: AnyTool

  /// The name of the image found in `bundle` for representing `tool`.
  private var imageName: String
  {
    switch tool
    {
      case .none: fatalError("There is no image associate with `AnyTool.none`.")
      case .newNodeGenerator: return "node_note_add"
      case .addNode: return "node_add"
      case .removeNode: return "node_remove"
      case .deleteNode: return "node_delete"
      case .nodeGenerator: return "node_note"
      case .rotate: return "node_rotate"
    }
  }

  /// The body of the view is either a single button or an empty view if `tool == .none`.
  public var body: some View
  {
    if tool != .none
    {
      Button
      {
        currentTool = currentTool == tool ? .none : tool
      }
      label:
      {
        Image(imageName, bundle: .module)
          .resizable()
          .frame(width: 44, height: 44)
      }

      .accentColor(currentTool == tool ? .highlightColor : .primaryColor1)
    }
    else
    {
      EmptyView()
    }
  }
}
