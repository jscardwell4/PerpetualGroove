//
//  DialState.swift
//  
//
//  Created by Jason Cardwell on 1/22/21.
//
import Foundation
import SwiftUI
import MoonDev

struct DialState
{

  private static let minAngle = Angle(degrees: -180)
  private static let maxAngle = Angle(degrees: 180)

  /// The current angle of rotation.
  var angle: Angle

  /// Updates the state with the latest gesture value.
  /// - Parameter value: The latest rotation gesture value.
  mutating func update(for value: RotationGesture.Value)
  {
    let clippedValue = max(DialState.minAngle, min(value, DialState.maxAngle))
    angle = clippedValue
  }

}
