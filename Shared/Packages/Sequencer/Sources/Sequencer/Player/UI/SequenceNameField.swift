//
//  SequenceNameField.swift
//
//
//  Created by Jason Cardwell on 1/21/21.
//
import Combine
import Common
import func MoonDev.logi
import SwiftUI

/// A view for displaying and setting the name of the current sequence.
/// - TODO: Figure out why edited names are not persisted.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct SequenceNameField: View, Identifiable
{
  /// The sequence whose name is being displayed.
  @EnvironmentObject var sequence: Sequence

  public let id = UUID()

  /// Flag indicating whether any of the views controls are currently editing.
  @Binding var isEditing: Bool

  private let onCommit: () -> Void

  public init(isEditing: Binding<Bool>,
              onCommit: @escaping () -> Void)
  {
    _isEditing = isEditing
    self.onCommit = onCommit
  }

  public var body: some View
  {
    GeometryReader
    {
      proxy in
      TextField("Sequence Name",
                text: $sequence.name,
                onEditingChanged: { self.isEditing = $0 },
                onCommit: onCommit)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .foregroundColor(isEditing ? .highlightColor : .primaryColor1)
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .trailing)
        .preference(key: KeyboardPreferenceKey.self,
                    value: isEditing
                    ? [KeyboardRequest(id: id, frame: proxy.frame(in: .global))]
                    : [])
        .triumpFont(family: .rock, volume: .two, size: 24)
        .multilineTextAlignment(.trailing)

    }
    .frame(minHeight: 24)
    .padding(.top)
  }
}
