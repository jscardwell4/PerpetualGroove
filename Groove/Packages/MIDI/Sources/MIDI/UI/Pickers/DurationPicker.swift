//
//  DurationPicker.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/18/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - DurationPicker

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct DurationPicker: View
{
  @Binding public var selection: Int
  public var body: some View
  {
    Picker("DurationPicker", selection: $selection)
    {
      ForEach(0 ..< Duration.allCases.count, id: \.self)
      {
        Image(Duration.allCases[$0].rawValue, bundle: .module).tag($0)
      }
    }
  }
}

// MARK: - DurationPicker_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct DurationPicker_Previews: PreviewProvider
{
  @State static var selection = 6
  static var previews: some View
  {
    DurationPicker(selection: $selection)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .fixedSize()
  }
}
