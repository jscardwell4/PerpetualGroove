//
//  TransportButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI
import MoonDev

/// A view for toggling the state of recording for the transport.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct RecordToggle: View
{
  /// The transport being controlled by the button.
  @EnvironmentObject var transport: Transport

  /// Backing store for whether the toggle is on or off.
  @State private var isOn = false

  /// The toggle style to use.
  private let toggleStyle = ImageToggleStyle(name: "record",
                                             bundle: .module,
                                             primaryColor: .primaryColor1)

  var body: some View
  {
    Toggle(isOn: $isOn, label: { Text("Recording Toggle") })
      .toggleStyle(toggleStyle)
      .accentColor(.highlightColor)
      .onChange(of: isOn) { transport.isRecording = $0 }
      .onReceive(transport.$isRecording.receive(on: RunLoop.main)) { isOn = $0 }
  }
}
