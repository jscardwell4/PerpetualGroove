//
//  ProgramPicker.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/18/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct ProgramPicker: View
{
  @Binding public var selection: Int

  let programs: [String]

  public var body: some View
  {
    Picker("ProgramPicker", selection: $selection)
    {
      ForEach(0 ..< programs.count, id: \.self)
      {
        Text(programs[$0]).tag($0)
      }
    }
  }

  public init(selection: Binding<Int>, soundFont: AnySoundFont)
  {
    _selection = selection
    programs = soundFont.presetHeaders.map(\.name)
  }
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ProgramPicker_Previews: PreviewProvider
{
  @State static var selection: Int = 0
  static var previews: some View
  {
    ProgramPicker(selection: $selection, soundFont: SoundFont.guitarsAndBasses)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .fixedSize()
  }
}


