//
//  LoopButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI
import func MoonDev.logi

// MARK: - LoopButton

/// A view to serve as a button for one the player's tools.
@available(iOS 14.0, *)
struct LoopButton: View
{
  /// The action to attach to this button.
  private let action: Action

  /// The body of the view is either a single button or an empty view if `tool == .none`.
  var body: some View
  {
    Button(action: action.action)
    {
      Image(action.imageName, bundle: .module)
        .resizable()
        .frame(width: 44, height: 44)
    }
    .accentColor(.primaryColor1)
  }

  /// Default initializer.
  ///
  /// - Parameters:
  ///   - tool: The tool the button shall represent.
  ///   - action: The action that the button shall perform.
  public init(action: Action) { self.action = action }

  /// An enumeration of the action's performable by an instance of `LoopButton`.
  @available(iOS 14.0, *)
  enum Action
  {
    /// Marks the starting position of a loop.
    case beginRepeat

    /// Marks the ending position of a loop.
    case endRepeat

    /// Exits loop mode discarding any editing modifications.
    case cancelLoop

    /// Exits loop mode storing any editing modifications.
    case confirmLoop

    /// Enters loop mode.
    case toggleLoop

    /// The name of the image found in `bundle` used by the button.
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

    /// The action performed by the button.
    var action: () -> Void
    {
      switch self
      {
        case .beginRepeat: return
          {
            Sequencer.shared.markLoopStart()
            logi("<\(#fileID) \(#function)> Controller.shared.markLoopStart()")
          }
        case .endRepeat: return
          {
            Sequencer.shared.markLoopEnd()
            logi("<\(#fileID) \(#function)> Controller.shared.markLoopEnd()")
          }
        case .cancelLoop: return
          {
            Sequencer.shared.exitLoopMode()
            logi("<\(#fileID) \(#function)> Controller.shared.exitLoopMode()")
          }
        case .confirmLoop: return
          {
            Sequencer.shared.exitLoopMode()
            logi("<\(#fileID) \(#function)> Controller.shared.exitLoopMode()")
          }
        case .toggleLoop: return
          {
            Sequencer.shared.enterLoopMode()
            logi("<\(#fileID) \(#function)> Controller.shared.enterLoopMode()")
          }
      }
    }
  }
}

// MARK: - LoopButton_Previews

@available(iOS 14.0, *)
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
