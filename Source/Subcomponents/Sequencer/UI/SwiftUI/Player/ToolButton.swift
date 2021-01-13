//
//  ToolButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - ToolButton

/// A view to serve as a button for one the player's tools.
public struct ToolButton: View
{
  /// The tool represented by this button.
  private let tool: AnyTool

  /// The name of the image for representing `tool`.
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
      Button(
        action: { player.currentTool = self.tool },
        label: { Image(imageName, bundle: bundle) }
      )
      .accentColor(player.currentTool == tool ? .highlightColor : .primaryColor1)
    }
  }

  /// Default initializer.
  ///
  /// - Parameters:
  ///   - tool: The tool the button shall represent.
  public init(tool: AnyTool) { self.tool = tool }
}

// MARK: - ToolButton_Previews

struct ToolButton_Previews: PreviewProvider
{
  static var previews: some View
  {
    ToolButton(tool: .none)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    ToolButton(tool: .newNodeGenerator)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    ToolButton(tool: .addNode)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    ToolButton(tool: .removeNode)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    ToolButton(tool: .deleteNode)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    ToolButton(tool: .nodeGenerator)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    ToolButton(tool: .rotate)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
