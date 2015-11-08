//
//  DocumentItem.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 10/3/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct DocumentItem: Equatable, Hashable {

  let displayName: String
  let filePath: String
  private let modificationDateString: String?
  private let creationDateString: String?
  let size: UInt64

  private static let dateFormatter: NSDateFormatter = {
    let dateFormatter = NSDateFormatter()
    dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
    dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
    return dateFormatter
  }()

  var URL: NSURL { return NSURL(fileURLWithPath: filePath) }

  var modificationDate: NSDate? {
    guard let dateString = modificationDateString else { return nil }
    return DocumentItem.dateFormatter.dateFromString(dateString)
  }

  var creationDate: NSDate? {
    guard let dateString = creationDateString else { return nil }
    return DocumentItem.dateFormatter.dateFromString(dateString)
  }

  var hashValue: Int { return URL.hashValue }

  var data: NSData { return encode(self) }

  /**
  init:

  - parameter item: NSMetadataItem
  */
  init(_ item: NSMetadataItem) {
    displayName = item.displayName.baseNameExt.0
    filePath = item.URL.path!
    if let date = item.modificationDate {
      modificationDateString = DocumentItem.dateFormatter.stringFromDate(date)
    } else {
      modificationDateString = nil
    }
    if let date = item.creationDate {
      creationDateString = DocumentItem.dateFormatter.stringFromDate(date)
    } else {
       creationDateString = nil
    }
    size = item.size
  }

  /**
  init:

  - parameter item: LocalDocumentItem
  */
  init(_ item: LocalDocumentItem) {
    displayName = item.displayName.baseNameExt.0
    filePath = item.URL.path!
    if let date = item.modificationDate {
      modificationDateString = DocumentItem.dateFormatter.stringFromDate(date)
    } else {
      modificationDateString = nil
    }
    if let date = item.creationDate {
      creationDateString = DocumentItem.dateFormatter.stringFromDate(date)
    } else {
       creationDateString = nil
    }
    size = item.size
  }

  /**
  init:

  - parameter documentItem: DocumentItem
  */
  init(_ documentItem: DocumentItem) {
    self = documentItem
//    displayName = documentItem.displayName
//    filePath = documentItem.filePath
//    modificationDateString = documentItem.modificationDateString
//    creationDateString = documentItem.creationDateString
//    size = documentItem.size
  }

  /**
  init:

  - parameter item: AnyObject
  */
  init?(_ item: AnyObject) {
    if let item = item as? NSMetadataItem { self.init(item) }
    else if let item = item as? LocalDocumentItem { self.init(item) }
    else if let data = item as? NSData, documentItem: DocumentItem = decode(data) { print("documentItem = \(documentItem)"); self.init(documentItem) }
    else { return nil }
  }

  /**
  init:base:

  - parameter wrapper: NSFileWrapper
  - parameter base: NSURL
  */
  init?(_ wrapper: NSFileWrapper, _ base: NSURL) {
    guard let item = LocalDocumentItem(wrapper, base) else { return nil }
    self.init(item)
  }
}

/**
Equatable compliance

- parameter lhs: DocumentItem
- parameter rhs: DocumentItem

- returns: Bool
*/
func ==(lhs: DocumentItem, rhs: DocumentItem) -> Bool {
  return lhs.filePath == rhs.filePath
      && lhs.displayName == rhs.displayName
      && lhs.creationDateString == rhs.creationDateString
      && lhs.modificationDateString == rhs.modificationDateString
      && lhs.size == rhs.size
}

