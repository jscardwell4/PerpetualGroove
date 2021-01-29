//
//  JogWheel.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import MoonDev
import SwiftUI

// MARK: - JogWheel

/// A view serving as a jog wheel control for the transport.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct JogWheel: View
{
  /// The transport being controlled by the wheel.
  @EnvironmentObject private var transport: Transport

  /// The wheel's action.
  private let onJog: (Double) -> Void

  /// The view's body is simply the hosted scroll wheel.
  var body: some View
  {
    Wheel(onJog: onJog)
      .frame(width: 150, height: 150)
  }

  /// Default initializer.
  /// - Parameter onJog: The action to perform upon jogging.
  init(onJog: @escaping (Double) -> Void) { self.onJog = onJog }
}
