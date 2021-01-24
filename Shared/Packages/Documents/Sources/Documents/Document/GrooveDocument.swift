//
//  GrooveDocument.swift
//  Documents
//
//  Created by Jason Cardwell on 1/19/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import Foundation
import MIDI
import MoonDev
import class Sequencer.Sequence
import SwiftUI
import UniformTypeIdentifiers

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension UTType
{
  public static var groove: UTType
  {
    UTType(importedAs: "com.moondeerstudios.groove-document")
  }
}

// MARK: - GrooveDocument

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public final class GrooveDocument: FileDocument, Identifiable, ObservableObject
{
  /// The sequence being persisted by the document.
  public private(set) var sequence: Sequence

  /// The unique identifier for this document instance.
  public let id = UUID()

  /// The document's display name.
  public var name = "Awesomesauce"

  /// Initializing with a sequence
  ///
  /// - Parameter sequence: The document's sequence. The default behavior is to
  ///                       create a new empty sequence.
  public init(sequence: Sequence = Sequence())
  {
    self.sequence = sequence
  }

  /// The array of uniform type identifiers for handleable files.
  public static var readableContentTypes: [UTType] { [.groove] }

  /// Initializing via a file read operation.
  ///
  /// - Parameter configuration: The configuration to use for file I/O.
  /// - Throws: Any error encountered reading the specified file.
  public init(configuration: ReadConfiguration) throws
  {
    // Get the raw data from specified `configuration`.
    guard let data = configuration.file.regularFileContents,
          let file = File(data: data)
    else
    {
      throw CocoaError(.fileReadCorruptFile)
    }

    // Initialize the document's sequence.
    sequence = Sequence(file: file)

    logv("""
    \(#fileID) \(#function)
    loaded file with the following contents: \(String(data: data, encoding: .utf8)!)
    """)
  }

  /// Initializing via a file read operation.
  ///
  /// - Parameter bookmark: The bookmark data with which to retrieve the file content.
  /// - Throws: Any error encountered reading the bookmark data or the actual file.
  public init(bookmark: Data) throws
  {
    var isStale = false
    let fileURL = try URL(resolvingBookmarkData: bookmark,
                          options: [],
                          relativeTo: nil,
                          bookmarkDataIsStale: &isStale)
    let fileWrapper = try FileWrapper(url: fileURL, options: .immediate)
    guard let data = fileWrapper.regularFileContents,
          let file = File(data: data)
    else
    {
      throw CocoaError(.fileReadCorruptFile)
    }

    // Grab the file name for display purposes.
    name = fileURL.deletingPathExtension().lastPathComponent

    // Initialize the document's sequence.
    sequence = Sequence(file: file)

    logi("\(#fileID) \(#function) loaded file '\(name)'")
  }

  /// This method generates a file wrapper around the document's raw data representation.
  ///
  /// - Parameter configuration: The desired configuration.
  /// - Throws: Any error thrown while initializing the file wrapper.
  /// - Returns: A file wrapper holding the document's raw data.
  public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
  {
    let data = File(sequence: sequence).data

    logv("""
    \(#fileID) \(#function)
    saving file with the following contents: \(String(data: data, encoding: .utf8)!)
    """)

    return .init(regularFileWithContents: data)
  }
}
