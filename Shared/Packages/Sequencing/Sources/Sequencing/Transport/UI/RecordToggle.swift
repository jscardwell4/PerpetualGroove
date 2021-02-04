//
//  TransportButton.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

/// A view for toggling the state of recording for the transport.
@available(iOS 14.0, *)
struct RecordToggle: View
{
  @EnvironmentObject var transport: Transport

  @State private var isOn = false

  /// The view's body is composed of a single button that toggle's the value
  /// of `transport.recording` and styles the button accordingly.
  var body: some View
  {
    Button { transport.isRecording.toggle() }
      label: {
        Image("record", bundle: Bundle.module)
          .resizable()
          .aspectRatio(contentMode: .fit)
      }
      .accentColor(isOn ? .highlightColor : .primaryColor2)
      .onReceive(transport.$isRecording.receive(on: RunLoop.main)) { isOn = $0 }
  }

  public init() {}
}
