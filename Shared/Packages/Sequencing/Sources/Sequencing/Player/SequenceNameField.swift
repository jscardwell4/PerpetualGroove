//
//  SequenceNameField.swift
//  Sequencer
//
//  Created by Jason Cardwell on 2/3/21.
//
import Common
import SwiftUI
import MoonDev

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct SequenceNameField: View, Identifiable
{
  /// The sequence whose name is being displayed.
  @EnvironmentObject var sequence: Sequence

  /// The backing store used with the `KeyboardPreferenceKey`.
//  @State private var keyboardRequest: KeyboardRequest? = nil

  /// Flag indicating whether any of the views controls are currently editing.
  @State private var isEditing = false

  /// Unique identifier for `keyboardRequest`.
  public let id = UUID()

  public var body: some View
  {
    GeometryReader
    {
      proxy in
      TextField("Sequence Name", text: $sequence.name)
      {
        [wasEditing = isEditing] isEditing in

        if isEditing ^ wasEditing
        {
//          keyboardRequest = isEditing ? KeyboardRequest(id: id, proxy: proxy) : nil
          self.isEditing = isEditing
        }
      }
      .frame(width: proxy.size.width, height: proxy.size.height, alignment: .trailing)
      .commonTextField(isEditing: $isEditing)
      .disabled(true)
//      .preference(key: KeyboardPreferenceKey.self, value: keyboardRequest.asArray)
      .triumpFont(family: .rock, volume: .two, size: 24)
      .multilineTextAlignment(.center)
    }
  }

  public init(){}
}
