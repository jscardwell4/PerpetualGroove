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
  /// The view's body is composed of a single button that toggle's the value
  /// of `transport.recording` and styles the button accordingly. 
  var body: some View
  {
    Button(action: { transport.recording.toggle() })
    {
      Image("record", bundle: Bundle.module)
    }
    .accentColor(transport.recording ? .highlightColor : .primaryColor2)
  }
}

@available(iOS 14.0, *)
struct RecordToggle_Previews: PreviewProvider {
  static var previews: some View {
    RecordToggle()
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
  
}
