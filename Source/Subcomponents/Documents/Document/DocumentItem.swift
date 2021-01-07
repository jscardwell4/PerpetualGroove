//
//  DocumentItem.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/3/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

// MARK: - DocumentItem

/// Enumeration wrapping the difference document sources.
public enum DocumentItem
{
  case metaData(NSMetadataItem)
  case local(LocalDocumentItem)
  case document(Document)

  /// Date the document's file was last modified.
  public var modificationDate: Date?
  {
    switch self
    {
      case let .metaData(item): return item.modificationDate
      case let .local(item): return item.modificationDate
      case let .document(document): return document.fileModificationDate
    }
  }

  /// Date the document's file was created.
  public var creationDate: Date?
  {
    switch self
    {
      case let .metaData(item): return item.creationDate
      case let .local(item): return item.creationDate
      case let .document(document): return document.fileCreationDate
    }
  }

  /// The size of the item's file on disk.
  public var size: UInt64
  {
    switch self
    {
      case let .metaData(item): return item.size
      case let .local(item): return item.size
      case let .document(document): return document.fileSize
    }
  }

  /// Whether the item represents a document stored on iCloud.
  public var isUbiquitous: Bool
  {
    switch self
    {
      case .metaData: return true
      case .local: return false
      case let .document(document): return document.isUbiquitous
    }
  }

  /// The url for the item's file.
  public var url: URL
  {
    switch self
    {
      case let .metaData(item): return item.URL
      case let .local(item): return item.url
      case let .document(document): return document.fileURL
    }
  }
}

// MARK: Named

extension DocumentItem: Named
{
  /// The name shown in the user interface.
  public var name: String
  {
    switch self
    {
      case let .metaData(item): return item.displayName
      case let .local(item): return item.displayName
      case let .document(document): return document.localizedName
    }
  }
}

// MARK: CustomStringConvertible

extension DocumentItem: CustomStringConvertible
{
  public var description: String { "\(name)" }
}

// MARK: CustomDebugStringConvertible

extension DocumentItem: CustomDebugStringConvertible
{
  public var debugDescription: String
  {
    var dict: [String: Any] = ["displayName": name, "size": size, "isUbiquitous": isUbiquitous]
    if let date = modificationDate { dict["modificationDate"] = date }
    if let date = creationDate { dict["creationDate"] = date }
    return "DocumentItem {\n\(dict.formattedDescription().indented(by: 4))\n}"
  }
}

// MARK: Hashable

extension DocumentItem: Hashable
{
  public func hash(into hasher: inout Hasher) { url.hash(into: &hasher) }
  public static func == (lhs: DocumentItem, rhs: DocumentItem) -> Bool
  {
    lhs.url.isEqualToFileURL(rhs.url)
  }
}
