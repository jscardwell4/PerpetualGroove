//
//  OctavePicker.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/18/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - OctavePicker

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct OctavePicker: View
{
  @Binding public var selection: Int

  public var body: some View
  {
    Picker("OctavePicker", selection: $selection)
    {
      ForEach(0 ..< Octave.allCases.count, id: \.self)
      {
        Text("\(Octave.allCases[$0].rawValue)").tag($0)
      }
    }
  }
}

// MARK: - OctavePicker_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct OctavePicker_Previews: PreviewProvider
{
  @State static var selection: Int = 6
  static var previews: some View
  {
    OctavePicker(selection: $selection)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .fixedSize()
  }
}
