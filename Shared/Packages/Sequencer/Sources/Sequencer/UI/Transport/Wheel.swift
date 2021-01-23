//
//  Wheel.swift
//
//
//  Created by Jason Cardwell on 1/22/21.
//
import Combine
import MoonDev
import SwiftUI

// MARK: - Wheel

/// A view that serves as a scroll wheel control.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct Wheel: View
{

  // MARK: Action

  /// Action to execute upon jogging.
  var onJog: (Double) -> Void

  // MARK: Gesture

  /// The gesture state for the view.
  @GestureState private var state = RotaryState()

  /// The drag gesture used to jog the wheel.
  private var drag: some Gesture
  {
    DragGesture().updating($state)
    {
      v, s, _ in s.update(for: v); self.onJog(s.radians)
    }
  }
  // MARK: View

  /// The view's body is composed of a single scroll wheel.
  var body: some View
  {
    ZStack
    {
      Image("wheel", bundle: .module)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 150)
        .foregroundColor(Color(#colorLiteral(red: 0.499273628, green: 0.4559301734, blue: 0.3952253163, alpha: 1)))
      Group
      {
        Image("wheel_dimple_fill", bundle: .module)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 50)
          .foregroundColor(Color(#colorLiteral(red: 0.6629999876, green: 0.6269999743, blue: 0.5799999833, alpha: 1)))
        Image("wheel_dimple", bundle: .module)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 50)
          .foregroundColor(.black)
      }
      .offset(x: 0, y: -40)
      .rotationEffect(state.angle)
    }
    .gesture(drag)
  }

}
