//
//  Clock.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import Foundation
import MIDI
import MoonKit
import SwiftUI

// MARK: - Clock

struct Clock: View
{
  @Binding var currentTime: BarBeatTime
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
    .font(Font.custom("EvelethDotRegularBold", size: 44))
    .foregroundColor(.primaryColor1)
  }
}

extension Clock
{
  struct Digits: View
  {
    enum Component { case bar, beat, subbeat }

    private var digits: String
    {
      switch component
      {
        case .bar: return String(time.bar, radix: 10, minCount: 3)
        case .beat: return String(time.beat)
        case .subbeat: return String(time.subbeat, radix: 10, minCount: 3)
      }
    }

    let time: BarBeatTime
    let component: Component

    var body: some View
    {
      Text(verbatim: digits)
    }
  }

  struct Divider: View
  {
    enum Component { case barBeatDivider, beatSubbeatDivider }

    let component: Component

    var body: some View
    {
      Text(verbatim: component == .barBeatDivider ? ":" : ".").baselineOffset(4.0)
    }
  }
}

// MARK: - Clock_Previews

struct Clock_Previews: PreviewProvider
{
  @State static var previewBarBeatTime = BarBeatTime(
    bar: 1,
    beat: 2,
    subbeat: 124,
    beatsPerBar: 4,
    beatsPerMinute: 120,
    subbeatDivisor: 480,
    isNegative: false
  )
  static var previews: some View
  {
    Clock(currentTime: $previewBarBeatTime)
      .frame(width: 300, height: 100, alignment: .center)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
  }
}
