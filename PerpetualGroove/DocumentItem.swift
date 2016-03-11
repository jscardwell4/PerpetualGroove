//
//  DocumentItem.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/3/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct DocumentItem {

  let displayName: String
  let fileBookmark: NSData
  private let modificationDateString: String?
  private let creationDateString: String?
  let size: UInt64
  let isUbiquitous: Bool

  private static let dateFormatter: NSDateFormatter = {
    let dateFormatter = NSDateFormatter()
    dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
    dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
    return dateFormatter
  }()

  var URL: NSURL? {
    return try? NSURL(byResolvingBookmarkData: fileBookmark,
                      options: .WithoutUI,
                      relativeToURL: nil,
                      bookmarkDataIsStale: nil)
  }

  var modificationDate: NSDate? {
    guard let dateString = modificationDateString else { return nil }
    return DocumentItem.dateFormatter.dateFromString(dateString)
  }

  var creationDate: NSDate? {
    guard let dateString = creationDateString else { return nil }
    return DocumentItem.dateFormatter.dateFromString(dateString)
  }

  /**
  init:

  - parameter item: NSMetadataItem
  */
  init(_ item: NSMetadataItem) {
    displayName = item.displayName.baseNameExt.0
    guard let bookmarkData = try? item.URL.bookmarkDataWithOptions(.SuitableForBookmarkFile,
                                                                   includingResourceValuesForKeys: nil,
                                                                   relativeToURL: nil) else
    {
      fatalError("unable to create bookmark data for url: \(item.URL)")
    }

    fileBookmark = bookmarkData
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
    isUbiquitous = item.isUbiquitous == true
  }

  /**
  init:

  - parameter item: LocalDocumentItem
  */
  init(_ item: LocalDocumentItem) {
    displayName = item.displayName.baseNameExt.0
    guard let bookmarkData = try? item.URL.bookmarkDataWithOptions(.SuitableForBookmarkFile,
                                                                   includingResourceValuesForKeys: nil,
                                                                   relativeToURL: nil) else
    {
      fatalError("unable to create bookmark data for url: \(item.URL)")
    }

    fileBookmark = bookmarkData
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
    isUbiquitous = false
  }

  init(_ document: Document) {
    let fileManager = NSFileManager.defaultManager()
    guard let path = String(UTF8String: document.fileURL.fileSystemRepresentation) else {
      fatalError("Unable to get the document's path representation")
    }

    guard let attributes = try? fileManager.attributesOfItemAtPath(path) else {
      fatalError("Unable to get file attributes for document")
    }

    size = (attributes as NSDictionary).fileSize()
    if let date = (attributes as NSDictionary).fileModificationDate() {
      modificationDateString = DocumentItem.dateFormatter.stringFromDate(date)
    } else { modificationDateString = nil }

    if let date = (attributes as NSDictionary).fileCreationDate() {
      creationDateString = DocumentItem.dateFormatter.stringFromDate(date)
    } else { creationDateString = nil }

    displayName = document.localizedName
    guard let bookmarkData = try? document.fileURL.bookmarkDataWithOptions(.SuitableForBookmarkFile,
                                                                   includingResourceValuesForKeys: nil,
                                                                   relativeToURL: nil) else
    {
      fatalError("unable to create bookmark data for url: \(document.fileURL)")
    }

    fileBookmark = bookmarkData
    isUbiquitous = fileManager.isUbiquitousItemAtURL(document.fileURL)
  }

  /**
  init:

  - parameter item: AnyObject
  */
  init?(_ item: AnyObject) {
    if let item = item as? NSMetadataItem { self.init(item) }
    else if let item = item as? LocalDocumentItem { self.init(item) }
    else if let data = item as? NSData {
      let coder = NSKeyedUnarchiver(forReadingWithData: data)
      self.init(coder: coder)
    } else { return nil }
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

extension DocumentItem: Coding {
  /**
   initWithCoder:

   - parameter coder: NSCoder
   */
  init?(coder: NSCoder) {
    guard let displayName = coder.decodeObjectForKey("displayName") as? String,
              bookmarkData = coder.decodeObjectForKey("fileBookmark") as? NSData
      else { return nil }

    self.displayName = displayName
    fileBookmark = bookmarkData
    isUbiquitous = coder.decodeBoolForKey("isUbiquitous")
    size = UInt64(coder.decodeInt64ForKey("size"))
    modificationDateString = coder.decodeObjectForKey("modificationDateString") as? String
    creationDateString = coder.decodeObjectForKey("creationDateString") as? String
  }

  /**
   encodeWithCoder:

   - parameter coder: NSCoder
   */
  func encodeWithCoder(coder: NSCoder) {
    coder.encodeObject(fileBookmark, forKey: "fileBookmark")
    coder.encodeObject(displayName, forKey: "displayName")
    coder.encodeObject(modificationDateString, forKey: "modificationDateString")
    coder.encodeObject(creationDateString, forKey: "creationDateString")
    coder.encodeInt64(Int64(size), forKey: "size")
    coder.encodeBool(isUbiquitous, forKey: "isUbiquitous")
  }
  
}

extension DocumentItem: DataConvertible {}

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
    return "DocumentItem {\n\(dict.formattedDescription().indentedBy(4))\n}"
  }
}

extension DocumentItem: Hashable {
  var hashValue: Int {
    guard let url = URL else { return displayName.hashValue ^ size.hashValue ^ isUbiquitous.hashValue }
    return url.hashValue
  }
}

extension DocumentItem: Equatable {}

/**
Equatable compliance

- parameter lhs: DocumentItem
- parameter rhs: DocumentItem

- returns: Bool
*/
func ==(lhs: DocumentItem, rhs: DocumentItem) -> Bool {
  let lhsURL = try? NSURL(byResolvingBookmarkData: lhs.fileBookmark, options: .WithoutUI, relativeToURL: nil, bookmarkDataIsStale: nil)
  let rhsURL = try? NSURL(byResolvingBookmarkData: rhs.fileBookmark, options: .WithoutUI, relativeToURL: nil, bookmarkDataIsStale: nil)
  guard lhsURL != nil && rhsURL != nil && lhsURL!.isEqualToFileURL(rhsURL!) else { return false }
  return lhs.displayName == rhs.displayName
      && lhs.creationDateString == rhs.creationDateString
      && lhs.modificationDateString == rhs.modificationDateString
      && lhs.size == rhs.size
      && lhs.isUbiquitous == rhs.isUbiquitous
}

