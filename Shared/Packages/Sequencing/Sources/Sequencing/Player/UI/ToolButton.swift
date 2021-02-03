//
//  ToolButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI
import MoonDev

// MARK: - ToolButton

/// A view to serve as a button for selecting one the player's tools.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ToolButton: View, Equatable, Identifiable
{
  /// The tool represented by this button.
  let tool: AnyTool

  /// The button's unique identifier.
  let id = UUID()

  /// Equatable conformance.
  static func ==(lhs: ToolButton, rhs: ToolButton) -> Bool
  {
    lhs.tool == rhs.tool && lhs.isSelected == rhs.isSelected
  }

  /// The sequencer's player loaded into the environment by `ContentView`.
  @EnvironmentObject var player: Player

  /// Flag indicating whether `tool` is the currently selected tool.
  private let isSelected: Bool

  @State private var preferenceValue: Set<AnyTool>

  /// The body of the view is either a single button or an empty view if `tool == .none`.
  var body: some View
  {
    Button
    {
//      logi("<\(#fileID) \(#function)> button action for tool '\(tool)'")
      preferenceValue = isSelected ? [] : [tool]
    }
    label: { tool.image.resizable().frame(width: 44, height: 44) }
    .accentColor(isSelected || !preferenceValue.isEmpty ? .highlightColor : .primaryColor1)
    .preference(key: CurrentTool.self, value: preferenceValue)
  }

  init(model: AnyTool, isSelected: Bool)
  {
    tool = model
    self.isSelected = isSelected
    _preferenceValue = State(initialValue: isSelected ? [model] : [])
  }
}

