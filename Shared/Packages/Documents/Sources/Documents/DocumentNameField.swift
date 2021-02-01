//
//  DocumentNameField.swift
//
//
//  Created by Jason Cardwell on 1/21/21.
//
import Combine
import Common
import MoonDev
import Sequencer
import SwiftUI

// MARK: - DocumentNameField

/// A view for displaying and setting the name of the current sequence.
/// - TODO: Figure out why edited names are not persisted.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct DocumentNameField: View, Identifiable
{
  /// The sequence whose name is being displayed.
  @EnvironmentObject var sequence: Sequence

  @Environment(\.openDocument) var openDocument

  /// The backing store used with the `KeyboardPreferenceKey`.
  @State private var keyboardRequest: KeyboardRequest? = nil

  public let id = UUID()

  /// Flag indicating whether any of the views controls are currently editing.
  @State private var isEditing = false

  public init() {}

  public var body: some View
  {
    GeometryReader
    {
      proxy in
      TextField("Document Name", text: $sequence.name)
      {
        [wasEditing = isEditing] isEditing in

        if isEditing ^ wasEditing
        {
          keyboardRequest = isEditing ? KeyboardRequest(id: id, proxy: proxy) : nil
          self.isEditing = isEditing
        }
      }
      onCommit:
      {
        openDocument?.document = Document(sequence: sequence)
      }
      .autocapitalization(.none)
      .disableAutocorrection(true)
      .foregroundColor(isEditing ? .highlightColor : .primaryColor1)
      .frame(width: proxy.size.width, height: proxy.size.height, alignment: .trailing)
      .preference(key: KeyboardPreferenceKey.self, value: keyboardRequest.asArray)
      .triumpFont(family: .rock, volume: .two, size: 24)
      .multilineTextAlignment(.trailing)
    }
    .frame(minHeight: 24)
    .padding(.top)
  }
}

// MARK: - OpenDocumentEnvironmentKey

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
private struct OpenDocumentEnvironmentKey: EnvironmentKey
{
  static let defaultValue: FileDocumentConfiguration<Document>? = nil
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension EnvironmentValues
{
  public var openDocument: FileDocumentConfiguration<Document>?
  {
    get { self[OpenDocumentEnvironmentKey.self] }
    set { self[OpenDocumentEnvironmentKey.self] = newValue }
  }
}
