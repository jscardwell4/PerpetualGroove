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
public struct JogWheel: View
{
  /// The view's body is simply the hosted scroll wheel.
  public var body: some View
  {
    ScrollWheelHost()
      .frame(width: 150, height: 150)
  }

  public init() {}
}

// MARK: - ScrollWheelHost

/// A type for hosting `ScrollWheel` instances.
private struct ScrollWheelHost: UIViewRepresentable
{

  /// Generates a scroll wheel styled and configured for use as a jog control.
  func makeUIView(context: Context) -> ScrollWheel
  {
    let scrollWheel = ScrollWheel(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
    scrollWheel.wheelImage = UIImage(named: "wheel", in: Bundle.module, with: nil)
    scrollWheel.dimpleImage = UIImage(named: "dimple", in: Bundle.module, with: nil)
    scrollWheel.dimpleFillImage = UIImage(named: "dimple_fill", in: Bundle.module, with: nil)
    scrollWheel.dimpleColor = .secondaryColor1
    scrollWheel.wheelColor = .secondaryColor2
    scrollWheel.dimpleStyle = .sourceAtop
    scrollWheel.dimpleFillStyle = .sourceIn
    scrollWheel.bounds = CGRect(size: CGSize(width: 150, height: 150))
    return scrollWheel
  }

  /// Updates the hosted scroll wheel.
  ///
  /// - Notice: This method currently does nothing.
  ///
  /// - Parameters:
  ///   - uiView: The hosted `ScrollWheel` instance.
  ///   - context: This parameter is ignored.
  func updateUIView(_ uiView: ScrollWheel, context: Context)
  {}
}

// MARK: - JogWheel_Previews

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
