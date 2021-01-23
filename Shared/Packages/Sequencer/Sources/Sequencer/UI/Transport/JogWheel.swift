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

/// A view for hosting an instance of `ScrollWheel` for jogging the transport.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct JogWheel: View
{

  /// The view's body is simply the hosted scroll wheel.
  public var body: some View
  {
    Wheel { radians in
      logi("\(#fileID) \(#function) radians = \(radians)")
    }
      .frame(width: 150, height: 150)
  }

  public init() {}
}

// MARK: - JogWheel_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct JogWheel_Previews: PreviewProvider
{
  static var previews: some View
  {
    JogWheel()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .padding()
  }
}
