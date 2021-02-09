//
//  MetronomeToggle.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI
import MoonDev

// MARK: - MetronomeToggle

/// A view for toggling the metronome on and off.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct MetronomeToggle: View
{
  /// The metronome being controlled by the button.
  @EnvironmentObject var metronome: Metronome

  /// Backing store for whether the toggle is on or off.
  @State private var isOn = false

  /// The toggle style to use.
  private let toggleStyle = ImageToggleStyle(name: "metronome",
                                             bundle: .module,
                                             primaryColor: .primaryColor1,
                                             insets: EdgeInsets(top: 4,
                                                                leading: 0,
                                                                bottom: 4,
                                                                trailing: 0))

  var body: some View
  {
    Toggle(isOn: $isOn, label: { Text("Metronome") })
      .toggleStyle(toggleStyle)
      .accentColor(.highlightColor)
      .onChange(of: isOn) { metronome.isOn = $0 }
      .onReceive(metronome.$isOn.receive(on: RunLoop.main)) { isOn = $0 }
  }
}
