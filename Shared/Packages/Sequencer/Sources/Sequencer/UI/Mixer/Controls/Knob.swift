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

struct Knob: View
{
  var onDial: (Angle) -> Void

  @GestureState private var state = DialState(angle: Angle(degrees: 0))

  /// The rotation gesture used to work the knob.
  private var rotation: some Gesture
  {
    RotationGesture().updating($state)
    {
      a, s, _ in
      s.update(for: a); self.onDial(s.angle)
    }
  }

  @Binding var value: Float

  init(value: Binding<Float>, onDial: @escaping (Angle) -> Void)
  {
    _value = value
    self.onDial = onDial
  }

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
      .rotationEffect(state.angle)
    }
    .gesture(rotation)
  }
}

// MARK: - Knob_Previews

struct Knob_Previews: PreviewProvider
{
  static var previews: some View
  {
    Knob(value: .constant(-0.5)){_ in}
      .padding()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
  }
}
