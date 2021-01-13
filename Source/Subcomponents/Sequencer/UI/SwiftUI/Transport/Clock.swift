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
import MoonKit
import SwiftUI

// MARK: - Clock

/// A view for displaying the transport's clock.
struct Clock: View
{
  /// The bar beat time backing the display of this view.
  @State private var currentTime: BarBeatTime = transport.time.barBeatTime

  /// Holds the subscription for `transport.time.barBeatTime` updates.
  private var currentTimeSubscription: Cancellable?

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
    .frame(width: 300, height: 100)
  }

  /// The initializer configures the subscription for `transport.time.$barBeatTime`.
  init()
  {
    currentTimeSubscription = transport.time.$barBeatTime.assign(
      to: \.currentTime,
      on: self
    )
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
    switch component
    {
      case .bar: return String(time.bar, radix: 10, minCount: 3)
      case .beat: return String(time.beat)
      case .subbeat: return String(time.subbeat, radix: 10, minCount: 3)
    }
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

// MARK: - Clock_Previews

struct Clock_Previews: PreviewProvider
{
  static var previews: some View
  {
    Clock()
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
