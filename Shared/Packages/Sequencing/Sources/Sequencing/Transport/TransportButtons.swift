//
//  TransportButtons.swift
//  Sequencing
//
//  Created by Jason Cardwell on 2/4/21.
//
import Foundation
import SwiftUI

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct TransportButtons: View
{
  @Environment(\.currentMode) var currentMode: Mode

  var body: some View
  {
    let loopActions = LoopButton.Action.actions(for: currentMode)

    HStack(spacing: 20)
    {
      RecordToggle()
      PlayButton()
      StopButton()
      Spacer()
      ForEach(loopActions) { LoopButton(action: $0) }
      Spacer()
    }
  }
}
