//
//  PitchPicker.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/18/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - PitchPicker

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct PitchPicker: View
{
  @Binding public var selection: Int

  public var body: some View
  {
    Picker("PitchPicker", selection: $selection)
    {
      ForEach(0 ..< Natural.allCases.count, id: \.self)
      {
        Text(Natural.allCases[$0].rawValue).tag($0)
      }
    }
  }
}

// MARK: - PitchPicker_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct PitchPicker_Previews: PreviewProvider
{
  @State static var selection: Int = 0
  static var previews: some View
  {
    PitchPicker(selection: $selection)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .fixedSize()
  }
}
