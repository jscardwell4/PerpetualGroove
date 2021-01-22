//
//  Knob.swift
//
//
//  Created by Jason Cardwell on 1/21/21.
//
import Common
import SwiftUI

// MARK: - Knob

struct Knob: View
{
  private static let rotationalOffset = -90.0

  @State var angle = Angle(degrees: Knob.rotationalOffset)

  private var rotation: some Gesture
  {
    RotationGesture()
      .onChanged {
        let degrees = min(max($0.degrees, -90), 90)
        self.angle = Angle(degrees: degrees + Knob.rotationalOffset)
        self.degreesOver90 = Float(degrees/90)
      }
  }

  @Binding var degreesOver90: Float

  init(degreesOver90: Binding<Float>)
  {
    _degreesOver90 = degreesOver90
    angle.degrees += min(max(Double(self.degreesOver90) * 90, -90), 90)
  }

  var body: some View
  {
    ZStack
    {
      Image("knob", bundle: .module)
        .foregroundColor(Color(#colorLiteral(red: 0.499273628, green: 0.4559301734, blue: 0.3952253163, alpha: 1)))
      Group
      {
        Image("indicator_fill", bundle: .module)
          .foregroundColor(.black)
        Image("indicator", bundle: .module)
          .foregroundColor(.black)
      }
      .rotationEffect(angle)
    }
    .gesture(rotation)
  }
}

// MARK: - Knob_Previews

struct Knob_Previews: PreviewProvider
{
  static var previews: some View
  {
    Knob(degreesOver90: .constant(-0.5))
      .padding()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
  }
}
