//
//  DocumentItem.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 10/3/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct DocumentItem {

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

//  var data: NSData {
//    let data = NSMutableData()
//    let coder = NSKeyedArchiver(forWritingWithMutableData: data)
//    encodeWithCoder(coder)
//    coder.finishEncoding()
//    return data
//  }


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
      filePath = coder.decodeObjectForKey("filePath") as? String else { return nil }
    self.displayName = displayName
    self.filePath = filePath
    self.size = UInt64(coder.decodeInt64ForKey("size"))
    modificationDateString = coder.decodeObjectForKey("modificationDateString") as? String
    creationDateString = coder.decodeObjectForKey("creationDateString") as? String
  }

  /**
   encodeWithCoder:

   - parameter coder: NSCoder
   */
  func encodeWithCoder(coder: NSCoder) {
    coder.encodeObject(displayName, forKey: "displayName")
    coder.encodeObject(filePath, forKey: "filePath")
    coder.encodeObject(modificationDateString, forKey: "modificationDateString")
    coder.encodeObject(creationDateString, forKey: "creationDateString")
    coder.encodeInt64(Int64(size), forKey: "size")
  }
  
}

extension DocumentItem: DataConvertible {}

extension DocumentItem: Named {
  var name: String { return displayName }
}

extension DocumentItem: CustomStringConvertible {
  var description: String {
    let (baseName, ext) = filePath.baseNameExt
    return "\(baseName).\(ext)"
  }
}

extension DocumentItem: Hashable {
  var hashValue: Int { return URL.hashValue }
}

extension DocumentItem: Equatable {}

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

