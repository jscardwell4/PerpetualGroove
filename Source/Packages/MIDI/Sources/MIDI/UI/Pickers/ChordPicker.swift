//
//  ChordPicker.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/18/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - ChordPicker

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct ChordPicker: View
{
  @Binding public var selection: Int

  public var body: some View
  {
    Picker("ChordPicker", selection: $selection)
    {
      Text("-").tag(-1)
      ForEach(0 ..< Chord.Pattern.Standard.allCases.count, id: \.self)
      {
        Text(Chord.Pattern.Standard.allCases[$0].name).tag($0)
      }
    }
  }
}

// MARK: - ChordPicker_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ChordPicker_Previews: PreviewProvider
{
  @State static var selection: Int = -1
  static var previews: some View
  {
    ChordPicker(selection: $selection)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .fixedSize()
  }
}
