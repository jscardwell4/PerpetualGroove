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
  let onJog: (Double) -> Void

  // MARK: Gesture

  /// The gesture state for the view's drag gesture.
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


private struct RotaryState
{
  /// The current angle of rotation in radians.
  var radians = 0.0

  /// The current angle of rotation.
  var angle = Angle(radians: 0)

  /// Flag indicating whether the drag gesture is currently handling a touch.
  private var isDragging = false

  /// Values required for updating rotation
  private var preliminaryValues: (location: CGPoint,
                                  quadrant: CircleQuadrant,
                                  time: Date)?

  // MARK: Calculations

  /// The center of the wheel for the purpose of angle calculation.
  private let wheelCenter = CGPoint(x: 75, y: 75)

  /// The offset in radians for the dimple's starting point.
  private let dimpleOffset: CGFloat = .pi * 0.5

  private var 𝝙radians = 0.0

  private var 𝝙seconds = 0.0

  /// Cache of calculated direction values
  private var directionHistory: [RotationalDirection] = []

  /// The current direction of rotation
  private var trendingDirection: RotationalDirection
  {
    var n = 0.0

    let directions = directionHistory.reversed().prefix(5)

    guard !directions.isEmpty else { return .unspecified }

    for (i, d) in zip((1 ... directions.count).reversed(), directions)
    {
      n += Double(d.rawValue) * (5.0 + Double(i) * 0.1)
    }

    let result: RotationalDirection
    switch n
    {
      case <--0: result = .counterClockwise
      case 0|->: result = .clockwise
      default: result = .unspecified
    }

    return result
  }

  /// The difference between the `angle` and the angle of the initial touch location
  private var touchOffset: CGFloat = 0.0

  var velocity: Double { 𝝙radians / 𝝙seconds }

  /// A method for calculating the angle to associate with a given location.
  /// - Parameter location: The location for which to calculate an angle.
  /// - Returns: The angle associated with `location`.
  private func angle(for location: CGPoint) -> CGFloat
  {
    let 𝝙 = location - wheelCenter
    let quadrant = CircleQuadrant(point: location, center: wheelCenter)
    let (x, y) = 𝝙.absolute.unpack
    let h = hypot(x, y)
    var α = acos(x / h)

    // Adjust the angle for the quadrant
    switch quadrant
    {
      case .I: α = .pi * 2 - α
      case .II: α += .pi
      case .III: α = .pi - α
      case .IV: break
    }

    // Adjust the angle for the rotated dimple
    α += dimpleOffset

    // Adjust for initial touch offset
    α += touchOffset

    return α
  }

  /// Update state for the new location.
  /// - Parameter value: The latest gesture value.
  mutating func update(for value: DragGesture.Value)
  {
    guard isDragging
    else
    {
      let quadrant = CircleQuadrant(point: value.location, center: wheelCenter)

      touchOffset = (CGFloat(angle.radians) - angle(for: value.location))
        .truncatingRemainder(dividingBy: .pi * 2)

      radians = 0
      𝝙radians = 0
      preliminaryValues = (value.location, quadrant, value.time)
      isDragging = true
      return
    }

    // Get the new location, angle and quadrant
    let locationʹ = value.location
    let angleʹ = angle(for: locationʹ)
    let quadrantʹ = CircleQuadrant(point: locationʹ, center: wheelCenter)

    // Make sure we already had some values or cache the new values and return
    guard let (location, quadrant, time) = preliminaryValues
    else
    {
      preliminaryValues = (locationʹ, quadrantʹ, value.time)
      return
    }

    // Make sure the location has actually changed
    guard locationʹ != location else { return }

    // Get the current direction of rotation and cache it
    let direction = RotationalDirection(
      from: location,
      to: locationʹ,
      about: wheelCenter,
      trending: trendingDirection
    )
    directionHistory.append(direction)

    // Make sure we haven't changed direction or clear cached values and return
    guard direction == trendingDirection
    else
    {
      preliminaryValues = nil
      return
    }

    // Get the absolute change in radians between the previous angle and the current angle
    var 𝝙angle = abs(angleʹ - CGFloat(angle.radians))
    assert(𝝙angle.isNaN == false)

    // Correct the value if we've crossed the 0/2π threshold
    if quadrantʹ == .IV && quadrant == .I || quadrantʹ == .I && quadrant == .IV
    {
      𝝙angle -= .pi * 2
    }

    // Get the change in radians signed for the current direction
    let 𝝙radiansʹ = Double(direction == .counterClockwise ? -𝝙angle : 𝝙angle)

    // Calculate the updated total radians
    let radiansʹ = radians + 𝝙radiansʹ

    // Calculate the number of seconds over which the change in radians occurred
    let 𝝙secondsʹ = value.time.timeIntervalSince(time)

    // Update the cached values
    preliminaryValues = (locationʹ, quadrantʹ, value.time)

    // Update property values
    𝝙radians = 𝝙radiansʹ
    𝝙seconds = 𝝙secondsʹ
    angle.radians = Double(angleʹ)

    // Update radians last so all values have been updated when actions are sent
    radians = radiansʹ
  }
}

