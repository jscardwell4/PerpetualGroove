//
//  PlayerView.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import SwiftUI

// MARK: - PlayerView

/// A view encapsulating the node player and various editing functionality.
public struct PlayerView: View
{
  /// The backing string for the document name text field
  @State private var documentName: String = "Awesome Sauce"

  /// Flag indicating whether any of the views controls are currently editing.
  @State private var isEditing = false

  /// The currently active tool or `.none` if no tool is currently active.
  @State private var currentTool = AnyTool.none

  /// The currently active mode.
  @State private var currentMode = sequencer.mode

  /// Invoked when the text field bound to `documentName` commits a new value.
  private func documentNameDidCommit()
  {}

  /// Invoked when the editing state of the text field bound to `documentName` changes.
  ///
  /// - Parameter newValue: The current editing state.
  private func isEditingDidChange(newValue: Bool) { isEditing = newValue }

  /// Subscription for the player's current tool.
  private var currentToolSubscription: Cancellable?

  /// Subscription for the controller's current mode.
  private var currentModeSubscription: Cancellable?

  /// Initializer simply configures the view's subscriptions.
  public init()
  {
    currentToolSubscription = player.$currentTool.assign(to: \.currentTool, on: self)
    currentModeSubscription = sequencer.$mode.assign(to: \.currentMode, on: self)
  }

  /// The player view encapsulates the host for an instance of `PlayerSKView`,
  /// a text field for displaying and modifying the name of the currently loaded
  /// document, and a horizontal toolbar containing buttons for the player's tools.
  public var body: some View
  {
    // Wrap everything in a vertical stack.
    VStack
    {
      // Create a text field for manipulating the name of the currently loaded document.
      TextField("Document Name",
                text: $documentName,
                onEditingChanged: isEditingDidChange(newValue:),
                onCommit: documentNameDidCommit)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .foregroundColor(isEditing ? .highlightColor : .primaryColor1)
        .font(Font.custom("Triump-Rg-Rock-02", size: 24))
        .multilineTextAlignment(.trailing)
        .padding(.trailing)

      // Create the host for the `SKView` subclass.
      PlayerHost().frame(width: 447, height: 447, alignment: .center)

      // Create the horizontal stack for the tool buttons.
      HStack
      {
        Spacer()
        ToolButton(tool: .newNodeGenerator)
        ToolButton(tool: .addNode)
        ToolButton(tool: .removeNode)
        ToolButton(tool: .deleteNode)
        ToolButton(tool: .nodeGenerator)
        ToolButton(tool: .rotate)
        Spacer()

        Group
        {
          if currentMode == .loop
          {
            LoopButton(action: .beginRepeat)
            LoopButton(action: .endRepeat)
            LoopButton(action: .cancelLoop)
            LoopButton(action: .confirmLoop)
          }
          else
          {
            LoopButton(action: .toggleLoop)
          }
        }
        Spacer()
      }
      .padding()
    }
    .padding()
    .accentColor(.primaryColor1)
  }
}

// MARK: - PlayerView_Previews

struct PlayerView_Previews: PreviewProvider
{
  static var previews: some View
  {
    Group {
      PlayerView().frame(width: 680, height: 600, alignment: .center)
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
    }
  }
}
