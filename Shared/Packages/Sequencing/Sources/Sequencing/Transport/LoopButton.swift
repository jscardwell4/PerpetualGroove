//
//  LoopButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI
import MoonDev

// MARK: - LoopButton

/// A view to serve as a button for one the player's tools.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct LoopButton: View
{
  /// The sequencer loaded into the enviroment by `GrooveApp`.
  @EnvironmentObject var sequencer: Sequencer

  /// The action to attach to this button.
  private let action: Action

  /// The body of the view is either a single button or an empty view if `tool == .none`.
  var body: some View
  {
    Button("Loop Button (\(action.rawValue))"){}
      .buttonStyle(ActionStyle(action: action))
  }

  /// Default initializer.
  ///
  /// - Parameters:
  ///   - action: The action that the button shall perform.
  init(action: Action) { self.action = action }

  /// An enumeration of the action's performable by an instance of `LoopButton`.
  enum Action: String, Hashable, Equatable, Identifiable
  {
    /// Marks the starting position of a loop.
    case beginRepeat = "begin_repeat"

    /// Marks the ending position of a loop.
    case endRepeat = "end_repeat"

    /// Exits loop mode discarding any editing modifications.
    case cancelLoop = "cancel_loop"

    /// Exits loop mode storing any editing modifications.
    case confirmLoop = "confirm_loop"

    /// Enters loop mode.
    case toggleLoop = "tape"

    /// The action's unique identifier.
    var id: String { rawValue }

    /// The image found in `bundle` used by the button.
    var image: Image { Image(rawValue, bundle: .module) }

    /// The action performed by the button.
    func trigger(sequencer: Sequencer) -> () -> Void
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

    /// The array of actions corresponding to a specific mode.
    /// - Parameter mode: The mode for which to generate actions.
    /// - Returns: The array of actions for `mode`.
    static func actions(for mode: Mode) -> [Action]
    {
      mode == .linear
        ? [.toggleLoop]
        : [.beginRepeat, .endRepeat, .cancelLoop, .confirmLoop]
    }
  }

  struct ActionStyle: PrimitiveButtonStyle
  {
    @State private var isPressed = false

    @EnvironmentObject var sequencer: Sequencer

    let action: Action

    func makeBody(configuration: Configuration) -> some View
    {
      action.image
        .resizable()
        .aspectRatio(contentMode: .fit)
        .foregroundColor(isPressed ? .highlightColor : .primaryColor1)
        .gesture(DragGesture(minimumDistance: 0)
          .onChanged { _ in isPressed = true }
          .onEnded
          { _ in
            isPressed = false
            action.trigger(sequencer: sequencer)()
          })
    }
  }

}
