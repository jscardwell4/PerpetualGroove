//
//  LoopButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - LoopButton

/// A view to serve as a button for one the player's tools.
struct LoopButton: View
{
  /// The action to attach to this button.
  private let action: Action

  /// The body of the view is either a single button or an empty view if `tool == .none`.
  var body: some View
  {
    Button(action: action.action, label: { Image(action.imageName, bundle: bundle) })
      .accentColor(.primaryColor1)
  }

  /// Default initializer.
  ///
  /// - Parameters:
  ///   - tool: The tool the button shall represent.
  ///   - action: The action that the button shall perform.
  public init(action: Action)
  {
    self.action = action
  }
}

extension LoopButton
{
  enum Action
  {
    case beginRepeat, endRepeat, cancelLoop, confirmLoop, toggleLoop

    var imageName: String
    {
      switch self
      {
        case .beginRepeat: return "begin_repeat"
        case .endRepeat: return "end_repeat"
        case .cancelLoop: return "cancel_loop"
        case .confirmLoop: return "confirm_loop"
        case .toggleLoop: return "tape"
      }
    }

    var action: () -> Void
    {
      switch self
      {
        case .beginRepeat: return { sequencer.markLoopStart() }
        case .endRepeat: return { sequencer.markLoopEnd() }
        case .cancelLoop: return { sequencer.exitLoopMode() }
        case .confirmLoop: return { sequencer.exitLoopMode() }
        case .toggleLoop: return { sequencer.enterLoopMode() }
      }
    }
  }
}

// MARK: - LoopButton_Previews

struct LoopButton_Previews: PreviewProvider
{
  static var previews: some View
  {
    LoopButton(action: .beginRepeat)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    LoopButton(action: .endRepeat)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    LoopButton(action: .cancelLoop)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    LoopButton(action: .confirmLoop)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    LoopButton(action: .toggleLoop)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
