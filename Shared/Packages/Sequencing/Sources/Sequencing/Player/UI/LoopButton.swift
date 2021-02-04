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
  /// The sequencer loaded into the enviroment by `GrooveApp`.
  @EnvironmentObject var sequencer: Sequencer

  /// The action to attach to this button.
  private let action: Action

  /// The width of the image, and the button.
  private let imageWidth: CGFloat

  /// The body of the view is either a single button or an empty view if `tool == .none`.
  var body: some View
  {
    Button(action: action.action(sequencer: sequencer))
    {
      action.image
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: imageWidth)
    }
  }

  /// Default initializer.
  ///
  /// - Parameters:
  ///   - width: The button's width.
  ///   - action: The action that the button shall perform.
  public init(width: CGFloat, action: Action)
  {
    imageWidth = width
    self.action = action
  }

  /// An enumeration of the action's performable by an instance of `LoopButton`.
  @available(iOS 14.0, *)
  @available(macCatalyst 14.0, *)
  @available(OSX 10.15, *)
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
    func action(sequencer: Sequencer) -> () -> Void
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
}
