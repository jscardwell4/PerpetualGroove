//
//  GrooveDocument.swift
//  Documents
//
//  Created by Jason Cardwell on 1/19/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI
import UniformTypeIdentifiers
import Sequencer

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public extension UTType
{
  static var exampleText: UTType
  {
    UTType(importedAs: "com.example.plain-text")
  }
}

// MARK: - GrooveDocument

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct GrooveDocument: FileDocument
{
  public var text: String

  public init(text: String = "Hello, world!")
  {
    self.text = text
  }

  public static var readableContentTypes: [UTType] { [.exampleText] }

  public init(configuration: ReadConfiguration) throws
  {
    guard let data = configuration.file.regularFileContents,
          let string = String(data: data, encoding: .utf8)
    else
    {
      throw CocoaError(.fileReadCorruptFile)
    }
    text = string
  }

  public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper
  {
    let data = text.data(using: .utf8)!
    return .init(regularFileWithContents: data)
  }
}
