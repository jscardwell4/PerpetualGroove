//
//  GrooveDocument.swift
//  Documents
//
//  Created by Jason Cardwell on 1/19/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Foundation
import Sequencer
import MoonDev
import MIDI
import Common
import SwiftUI
import UniformTypeIdentifiers

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public extension UTType
{
  static var groove: UTType { UTType(importedAs: "com.moondeerstudios.groove-document") }
}

// MARK: - GrooveDocument

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct GrooveDocument: FileDocument
{
  /// The type of which document's are comprised.
  public typealias Sequence = Sequencer.Sequence

  /// The sequence being persisted by the document.
  public private(set) var sequence: Sequence

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
  }

  /// This method generates a file wrapper around the document's raw data representation.
  ///
  /// - Parameter configuration: The desired configuration.
  /// - Throws: Any error thrown while initializing the file wrapper.
  /// - Returns: A file wrapper holding the document's raw data.
  public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
  {
    .init(regularFileWithContents: File(sequence: sequence).data)
  }
}
