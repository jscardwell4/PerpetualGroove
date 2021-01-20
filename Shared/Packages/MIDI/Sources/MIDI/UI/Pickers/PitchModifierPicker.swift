//
//  PitchModifierPicker.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/18/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - PitchModifierPicker

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct PitchModifierPicker: View
{
  @Binding public var selection: Int

  private static let rows: [Image] = [
    Image("flat", bundle: .module),
    Image("natural", bundle: .module),
    Image("sharp", bundle: .module)
  ]

  public var body: some View
  {
    Picker("PitchModifierPicker", selection: $selection)
    {
      ForEach(0 ..< PitchModifierPicker.rows.count, id: \.self)
      {
        PitchModifierPicker.rows[$0].tag($0)
      }
    }
  }
}

// MARK: - PitchModifierPicker_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct PitchModifierPicker_Previews: PreviewProvider
{
  @State static var selection: Int = 1
  static var previews: some View
  {
    PitchModifierPicker(selection: $selection)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .fixedSize()
  }
}
