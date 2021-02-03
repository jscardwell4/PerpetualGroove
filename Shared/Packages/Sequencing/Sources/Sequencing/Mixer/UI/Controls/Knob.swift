//
//  Knob.swift
//
//
//  Created by Jason Cardwell on 1/21/21.
//
import Common
import SwiftUI
import MoonDev

// MARK: - Knob

// TODO: Convert to drag gesture to make it easier to turn the knob.
struct Knob: View
{

  @GestureState private var angle: Angle = .zero

  /// The rotation gesture used to work the knob.
  private var rotation: some Gesture
  {
    RotationGesture().updating($angle)
    {
      a, s, _ in
      s = max(Angle(degrees: -180), min(a, Angle(degrees: 180)))
      self.value = Float(s.degrees / 180)
    }
  }

  @Binding var value: Float

  var body: some View
  {
    ZStack
    {
      Image("knob", bundle: .module)
        .foregroundColor(Color(#colorLiteral(red: 0.499273628, green: 0.4559301734, blue: 0.3952253163, alpha: 1)))
      Group
      {
        Image("knob_indicator_fill", bundle: .module)
          .foregroundColor(.black)
        Image("knob_indicator", bundle: .module)
          .foregroundColor(.black)
      }
      .rotationEffect(angle + Angle(degrees: Double(value) * 90))
    }
    .gesture(rotation)
  }
}
