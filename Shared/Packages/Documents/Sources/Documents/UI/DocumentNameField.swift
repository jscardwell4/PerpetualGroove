//
//  DocumentNameField.swift
//
//
//  Created by Jason Cardwell on 1/21/21.
//
import Combine
import SwiftUI

// MARK: - DocumentNameField

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct DocumentNameField: View
{
  /// The backing string for the document name text field
  @Binding public var documentName: String

  /// Flag indicating whether any of the views controls are currently editing.
  @State private var isEditing = false

  /// Invoked when the editing state of the text field bound to `documentName` changes.
  ///
  /// - Parameter newValue: The current editing state.
  private func isEditingDidChange(newValue: Bool) { isEditing = newValue }

  /// Invoked when the text field bound to `documentName` commits a new value.
  private let onCommit: () -> Void

  public init(documentName: Binding<String>, onCommit: @escaping () -> Void = {})
  {
    _documentName = documentName
    self.onCommit = onCommit
  }

  public var body: some View
  {
    TextField("Document Name",
              text: $documentName,
              onEditingChanged: isEditingDidChange(newValue:),
              onCommit: onCommit)
      .autocapitalization(.none)
      .disableAutocorrection(true)
      .foregroundColor(isEditing ? .highlightColor : .primaryColor1)
      .font(.largeControlEditing)
      .multilineTextAlignment(.trailing)
      .disabled(true)
  }
}

