//
//  Clock.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import Foundation
import MIDI
import MoonDev
import SwiftUI

// MARK: - Clock

/// A view for displaying the transport's clock.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct Clock: View
{
  /// The time being monitored by the clock.
  @EnvironmentObject private var time: Time

  /// The current time to display.
  private var currentTime: BarBeatTime { time.barBeatTime }

  /// The view's body is composed of three groups of digits representing
  /// the bar, beat, and subbeat values for `currentTime`.
  var body: some View
  {
    HStack(alignment: .center, spacing: 2)
    {
      Digits(time: currentTime, component: .bar)
      Divider(component: .barBeatDivider)
      Digits(time: currentTime, component: .beat)
      Divider(component: .beatSubbeatDivider)
      Digits(time: currentTime, component: .subbeat)
    }
    .font(.clock)
    .foregroundColor(.primaryColor1)
  }
}

// MARK: - Digits

/// A view for displaying digits for a clock component.
private struct Digits: View
{
  /// An enumeration of digit-representable clock components.
  enum Component
  {
    /// The number of bars in the bar beat time.
    case bar

    /// The number of beats in the bar beat time.
    case beat

    /// The number of subbeats in the bar beat time.
    case subbeat
  }

  /// A string containing the component's digits.
  private var digits: String
  {
    let value: UInt, minCount: Int

    switch component
    {
      case .bar:
        value = time.bar
        minCount = 3
      case .beat:
        value = time.beat
        minCount = 1
      case .subbeat:
        value = time.subbeat
        minCount = 3
    }

    return String(value, radix: 10, minCount: minCount)
  }

  /// The time of which these digits compose some portion.
  let time: BarBeatTime

  /// The component to which the digits are assigned.
  let component: Component

  /// The view's body is simply some verbatim text set to `digits`.
  var body: some View
  {
    Text(verbatim: digits)
  }
}

// MARK: - Divider

/// A view for displaying a divider between two instances of `Digits`.
private struct Divider: View
{
  /// An enumeration of clock inter-digit dividers.
  enum Component
  {
    /// The ':' divider between the bar and beat digits.
    case barBeatDivider

    /// The '.' divider between the beat and subbeat digits.
    case beatSubbeatDivider
  }

  /// The component to which the divider is assigned.
  let component: Component

  /// The view's body is simply some verbatim text set to ':' or '.' accordinglgy.
  var body: some View
  {
    Text(verbatim: component == .barBeatDivider ? ":" : ".").baselineOffset(4.0)
  }
}
