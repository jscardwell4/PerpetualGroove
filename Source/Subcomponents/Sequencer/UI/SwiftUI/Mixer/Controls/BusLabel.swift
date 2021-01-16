//
//  BusLabel.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/14/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import MoonDev
import SwiftUI

// MARK: - BusLabel

struct BusLabel: View
{
  @State var label: String = "Bus 1"

  var body: some View
  {
    MarqueeHost(text: $label)
      .frame(width: 84, height: 14)
  }
}

// MARK: - MarqueeHost

private struct MarqueeHost: UIViewRepresentable
{
  @Binding var text: String

  func makeUIView(context: Context) -> MoonDev.MarqueeField
  {
    let marquee = MarqueeField(frame: CGRect(size: CGSize(width: 84, height: 14)))
    marquee.identifier = "BusLabel"
    marquee.text = text
    marquee.font = UIFont(fontStyle: FontStyle(font: TriumpFont.rock02,
                                               size: 14,
                                               style: .title))
    marquee.editingFont = marquee.font
    marquee.scrollEnabled = true
    marquee.verticalAlignment = .Top
    marquee.normalTintColor = UIColor(named: "trackLabelColor",
                                      in: bundle,
                                      compatibleWith: nil)

    return marquee
  }

  func updateUIView(_ uiView: MoonDev.MarqueeField, context: Context)
  {}
}

// MARK: - BusLabel_Previews

struct BusLabel_Previews: PreviewProvider
{
  @State static var label: String = "Bus 1"
  static var previews: some View
  {
    BusLabel(label: label)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
