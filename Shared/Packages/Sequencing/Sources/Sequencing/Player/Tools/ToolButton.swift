//
//  ToolButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import MoonDev
import SwiftUI

// MARK: - ToolButton

/// A view to serve as a button for selecting one the player's tools.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ToolButton: View, Identifiable
{
  @Environment(\.toolset) var toolset: Toolset

  /// The tool represented by this button.
  let tool: Tool

  /// The button's unique identifier.
  var id: Tool { tool }

  /// Insets to apply to the button's image.
  let insets: EdgeInsets

  /// The sequencer's player loaded into the environment by `ContentView`.
  @Environment(\.player) var player: Player

  init(tool: Tool, insets: EdgeInsets = EdgeInsets())
  {
    self.tool = tool
    self.insets = insets
  }

  /// The body of the view is either a single button or an empty view if `tool == .none`.
  var body: some View
  {
    Button("Tool Button (\(tool.rawValue))"){}
    .buttonStyle(ToolStyle(tool: tool, insets: insets))
  }

  struct ToolStyle: PrimitiveButtonStyle
  {
    @Environment(\.toolset) var toolset: Toolset
    
    @State private var isSelected = false
    @State private var isHighlighted = false

    let tool: Tool

    let insets: EdgeInsets

    @Environment(\.player) var player: Player

    func makeBody(configuration: Configuration) -> some View
    {
      tool.image
        .resizable()
        .aspectRatio(contentMode: .fit)
        .padding(insets)
        .foregroundColor(isSelected || isHighlighted ? .highlightColor : .primaryColor1)
        .brightness(isHighlighted ? 0.25 : 0)
        .onReceive(toolset.$currentTool.receive(on: RunLoop.main))
        {
          isSelected = $0 == tool
        }
        .gesture(DragGesture(minimumDistance: 0)
          .onChanged { _ in isHighlighted = true }
          .onEnded
          { _ in
            isHighlighted = false
            toolset.currentTool = isSelected ? nil : tool
            configuration.trigger()
          })
    }
  }
}
