//
//  DocumentItem.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/3/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev

// MARK: - DocumentItem

/// Enumeration wrapping the difference document sources.
@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
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

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
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

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
extension DocumentItem: CustomStringConvertible
{
  public var description: String { name }
}

// MARK: CustomDebugStringConvertible

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
extension DocumentItem: CustomDebugStringConvertible
{
  public var debugDescription: String
  {
    """
    DocumentItem {
      displayName: \(name)
      size: \(size)
      modificationDate: \(String(describing: modificationDate ?? nil))
      creationDate: \(String(describing: creationDate ?? nil))
    }
    """
  }
}

// MARK: Hashable

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
extension DocumentItem: Hashable
{
  public func hash(into hasher: inout Hasher) { url.hash(into: &hasher) }
  public static func == (lhs: DocumentItem, rhs: DocumentItem) -> Bool
  {
    lhs.url.isEqualToFileURL(rhs.url)
  }
}
