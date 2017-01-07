//
//  DocumentItem.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/3/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// Enumeration wrapping the difference document sources.
enum DocumentItem: Named, CustomStringConvertible, CustomDebugStringConvertible, Hashable {
  
  case metaData (NSMetadataItem)
  case local    (LocalDocumentItem)
  case document (Document)

  /// The name shown in the user interface.
  var name: String {
    switch self {
      case .metaData(let item):     return item.displayName
      case .local   (let item):     return item.displayName
      case .document(let document): return document.localizedName
    }
  }

  /// Date the document's file was last modified.
  var modificationDate: Date? {
    switch self {
      case .metaData(let item):     return item.modificationDate
      case .local(let item):        return item.modificationDate
      case .document(let document): return document.fileModificationDate
    }
  }

  /// Date the document's file was created.
  var creationDate: Date? {
    switch self {
      case .metaData(let item):     return item.creationDate
      case .local(let item):        return item.creationDate
      case .document(let document): return document.fileCreationDate
    }
  }

  /// The size of the item's file on disk.
  var size: UInt64 {
    switch self {
      case .metaData(let item):     return item.size
      case .local(let item):        return item.size
      case .document(let document): return document.fileSize
    }
  }

  /// Whether the item represents a document stored on iCloud.
  var isUbiquitous: Bool {
    switch self {
      case .metaData:               return true
      case .local:                  return false
      case .document(let document): return document.isUbiquitous
    }
  }

  /// The url for the item's file.
  var url: URL {
    switch self {
      case .metaData(let item):     return item.URL
      case .local(let item):        return item.url
      case .document(let document): return document.fileURL
    }
  }

  var description: String { return "\(name)" }

  var debugDescription: String {
    var dict: [String:Any] = ["displayName": name, "size": size, "isUbiquitous": isUbiquitous]
    if let date = modificationDate { dict["modificationDate"] = date }
    if let date = creationDate { dict["creationDate"] = date }
    return "DocumentItem {\n\(dict.formattedDescription().indented(by: 4))\n}"
  }

  var hashValue: Int { return url.hashValue }

  static func ==(lhs: DocumentItem, rhs: DocumentItem) -> Bool {
    return lhs.url.isEqualToFileURL(rhs.url)
  }

}
