//
//  NSMetadataItem.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/7/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

extension NSMetadataItem {

  /// Enumeration wrapping various file attribute keys.
  enum ItemKey: String, EnumerableType {
    case fsName                 = "kMDItemFSName"                                     // NSString
    case displayName            = "kMDItemDisplayName"                                // NSString
    case url                    = "kMDItemURL"                                        // NSURL
    case path                   = "kMDItemPath"                                       // NSString
    case fsSize                 = "kMDItemFSSize"                                     // NSNumber
    case fsCreationDate         = "kMDItemFSCreationDate"                             // NSDate
    case fsContentChangeDate    = "kMDItemFSContentChangeDate"                        // NSDate
    case isUbiquitous           = "NSMetadataItemIsUbiquitousKey"                     // NSNumber: Bool
    case hasUnresolvedConflicts = "NSMetadataUbiquitousItemHasUnresolvedConflictsKey" // NSNumber: Bool
    case isDownloading          = "NSMetadataUbiquitousItemIsDownloadingKey"          // NSNumber: Bool
    case isUploaded             = "NSMetadataUbiquitousItemIsUploadedKey"             // NSNumber: Bool
    case isUploading            = "NSMetadataUbiquitousItemIsUploadingKey"            // NSNumber: Bool
    case percentDownloaded      = "NSMetadataUbiquitousItemPercentDownloadedKey"      // NSNumber: Double
    case percentUploaded        = "NSMetadataUbiquitousItemPercentUploadedKey"        // NSNumber: Double
    case downloadingStatus      = "NSMetadataUbiquitousItemDownloadingStatusKey"      // NSString
    case downloadingError       = "NSMetadataUbiquitousItemDownloadingErrorKey"       // NSError
    case uploadingError         = "NSMetadataUbiquitousItemUploadingErrorKey"         // NSError
    static var allCases: [ItemKey] { 
      return [fsName, displayName, url, path, fsSize, fsCreationDate, fsContentChangeDate, isUbiquitous,
              hasUnresolvedConflicts, isDownloading, isUploaded, isUploading, percentDownloaded,
              percentUploaded, downloadingStatus, downloadingError, uploadingError]
    }
  }

  /// Returns the value returned by invoking `value(forAttribute:)`.
  subscript(itemKey: ItemKey) -> Any? { return value(forAttribute: itemKey.rawValue) as Any? }

  var fileSystemName: String? { return self[.fsName] as? String }
  var displayName: String { return self[.displayName] as? String ?? "Unnamed Item" }
  var URL: Foundation.URL { return self[.url] as! Foundation.URL }
  var path: String? { return self[.path] as? String }
  var size: UInt64 { return (self[.fsSize] as! NSNumber).uint64Value }
  var creationDate: Date? { return self[.fsCreationDate] as? Date }
  var modificationDate: Date? { return self[.fsContentChangeDate] as? Date }
  var isUbiquitous: Bool? { return (self[.isUbiquitous] as? NSNumber)?.boolValue }
  var hasUnresolvedConflicts: Bool? { return (self[.hasUnresolvedConflicts] as? NSNumber)?.boolValue }
  var downloading: Bool? { return (self[.isDownloading] as? NSNumber)?.boolValue }
  var uploaded: Bool? { return (self[.isUploaded] as? NSNumber)?.boolValue }
  var uploading: Bool? { return (self[.isUploading] as? NSNumber)?.boolValue }
  var percentDownloaded: Double? { return (self[.percentDownloaded] as? NSNumber)?.doubleValue }
  var percentUploaded: Double? { return (self[.percentUploaded] as? NSNumber)?.doubleValue }
  var downloadingStatus: String? { return self[.downloadingStatus] as? String }
  var downloadingError: NSError? { return self[.downloadingError] as? NSError }
  var uploadingError: NSError? { return self[.uploadingError] as? NSError }

  var attributesDescription: String {
    var result = "NSMetadataItem {\n\t"
    result += "\n\t".join(ItemKey.allCases.flatMap({
      guard let value = self[$0] else { return nil }
      let key = $0.rawValue
      let name: String?
      switch key {
        case ~/"^kMDItem[a-zA-Z]+$":
          name = $0.rawValue[key.index(key.startIndex, offsetBy: 7)|->]
        case ~/"^NSMetadataItem[a-zA-Z]+Key$":
          name = $0.rawValue[key.characters.index(key.startIndex,
                                                  offsetBy: 14) ..< key.characters.index(key.endIndex,
                                                                                         offsetBy: -3)]
        case ~/"^NSMetadataUbiquitousItem[a-zA-Z]+Key$":
          name = $0.rawValue[key.characters.index(key.startIndex,
                                                  offsetBy: 24) ..< key.characters.index(key.endIndex,
                                                                                         offsetBy: -3)]
        default:
          name = nil
      }
      guard name != nil else { return nil }
      return "\(name!): \(value)"
      }))
    result += "\n}"
    return result
  }

}

extension Notification {

  /// The removed items for a notification posted by an instance of `NSMetaDataQuery` or `nil`.
  var removedMetadataItems: [NSMetadataItem]? {
    return userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem]
  }

  /// The changed items for a notification posted by an instance of `NSMetaDataQuery` or `nil`.
  var changedMetadataItems: [NSMetadataItem]? {
    return userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem]
  }

  /// The added items for a notification posted by an instance of `NSMetaDataQuery` or `nil`.
  var addedMetadataItems: [NSMetadataItem]? {
    return userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem]
  }

}
