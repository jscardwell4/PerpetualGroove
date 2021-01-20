//
//  VelocityPicker.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/18/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI

// MARK: - VelocityPicker

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct VelocityPicker: View
{
  @Binding public var selection: Int

  public var body: some View
  {
    Picker("VelocityPicker", selection: $selection)
    {
      ForEach(0 ..< Velocity.allCases.count, id: \.self)
      {
        Image(Velocity.allCases[$0].rawValue, bundle: .module).tag($0)
      }
    }
  }
}

// MARK: - VelocityPicker_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct VelocityPicker_Previews: PreviewProvider
{
  @State static var selection: Int = 0
  static var previews: some View
  {
    VelocityPicker(selection: $selection)
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .fixedSize()
  }
}
