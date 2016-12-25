//
//  DocumentItem.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/3/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file

enum DocumentItem {
  
  case metaData(NSMetadataItem)
  case local   (LocalDocumentItem)
  case document(Document)

  var displayName: String {
    switch self {
      case .metaData(let item):     return item.displayName
      case .local   (let item):     return item.displayName
      case .document(let document): return document.localizedName
    }
  }

  var modificationDate: Date? {
    switch self {
      case .metaData(let item):
        return item.modificationDate
      case .local(let item):
        return item.modificationDate
      case .document(let document):
        return (try? FileManager.default
          .attributesOfItem(atPath: document.fileURL.path)[FileAttributeKey.modificationDate]
          ) as? Date

    }
  }

  var creationDate: Date? {
    switch self {
      case .metaData(let item):
        return item.creationDate
      case .local(let item):
        return item.creationDate
      case .document(let document):
        return (try? FileManager.default
          .attributesOfItem(atPath: document.fileURL.path)[FileAttributeKey.creationDate]
          ) as? Date
    }
  }

  var size: UInt64 {
    switch self {
      case .metaData(let item): return item.size
      case .local(let item): return item.size
      case .document(let document):
        return (try? FileManager.default
          .attributesOfItem(atPath: document.fileURL.path)[FileAttributeKey.size]
          ) as? UInt64 ?? 0
    }
  }

  var isUbiquitous: Bool {
    switch self {
    case .metaData: return true
    case .local: return false
    case .document(let document):
      return FileManager.default.isUbiquitousItem(at: document.fileURL)
    }
  }

  var url: URL {
    switch self {
      case .metaData(let item):     return item.URL
      case .local(let item):        return item.url
      case .document(let document): return document.fileURL
    }
  }

  var data: Any {
    switch self {
      case .metaData(let item):     return item
      case .local(let item):        return item
      case .document(let document): return document
    }
  }

  init?(_ data: Any) {
    switch data {
      case let item as NSMetadataItem:      self = .metaData(item)
      case let item as LocalDocumentItem:   self = .local(item)
      case let document as Document:        self = .document(document)
      default:                              return nil
    }
  }
}


extension DocumentItem: Named {

  var name: String { return displayName }

}

extension DocumentItem: CustomStringConvertible {

  var description: String { return "\(displayName)" }

}

extension DocumentItem: CustomDebugStringConvertible {

  var debugDescription: String {
    var dict: [String:Any] = [
      "displayName": displayName,
      "size": size,
      "isUbiquitous": isUbiquitous
    ]
    if let date = modificationDate { dict["modificationDate"] = date }
    if let date = creationDate { dict["creationDate"] = date }
    return "DocumentItem {\n\(dict.formattedDescription().indented(by: 4))\n}"
  }

}

extension DocumentItem: Hashable {

  var hashValue: Int { return url.hashValue }

}

extension DocumentItem: Equatable {

  static func ==(lhs: DocumentItem, rhs: DocumentItem) -> Bool {
    return lhs.url.isEqualToFileURL(rhs.url)
        && lhs.displayName == rhs.displayName
        && lhs.creationDate == rhs.creationDate
        && lhs.modificationDate == rhs.modificationDate
        && lhs.size == rhs.size
        && lhs.isUbiquitous == rhs.isUbiquitous
  }

}
