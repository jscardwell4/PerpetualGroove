//
//  NSMetadataItem.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/7/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file

extension NSMetadataItem {

  enum ItemKey: String, EnumerableType {
    case FSName                 = "kMDItemFSName"                                     // NSString
    case DisplayName            = "kMDItemDisplayName"                                // NSString
    case URL                    = "kMDItemURL"                                        // NSURL
    case Path                   = "kMDItemPath"                                       // NSString
    case FSSize                 = "kMDItemFSSize"                                     // NSNumber
    case FSCreationDate         = "kMDItemFSCreationDate"                             // NSDate
    case FSContentChangeDate    = "kMDItemFSContentChangeDate"                        // NSDate
    case IsUbiquitous           = "NSMetadataItemIsUbiquitousKey"                     // NSNumber: Bool
    case HasUnresolvedConflicts = "NSMetadataUbiquitousItemHasUnresolvedConflictsKey" // NSNumber: Bool
    case IsDownloading          = "NSMetadataUbiquitousItemIsDownloadingKey"          // NSNumber: Bool
    case IsUploaded             = "NSMetadataUbiquitousItemIsUploadedKey"             // NSNumber: Bool
    case IsUploading            = "NSMetadataUbiquitousItemIsUploadingKey"            // NSNumber: Bool
    case PercentDownloaded      = "NSMetadataUbiquitousItemPercentDownloadedKey"      // NSNumber: Double
    case PercentUploaded        = "NSMetadataUbiquitousItemPercentUploadedKey"        // NSNumber: Double
    case DownloadingStatus      = "NSMetadataUbiquitousItemDownloadingStatusKey"      // NSString
    case DownloadingError       = "NSMetadataUbiquitousItemDownloadingErrorKey"       // NSError
    case UploadingError         = "NSMetadataUbiquitousItemUploadingErrorKey"         // NSError
    static var allCases: [ItemKey] { 
      return [FSName, DisplayName, URL, Path, FSSize, FSCreationDate, FSContentChangeDate, IsUbiquitous,
              HasUnresolvedConflicts, IsDownloading, IsUploaded, IsUploading, PercentDownloaded,
              PercentUploaded, DownloadingStatus, DownloadingError, UploadingError]
    }
  }

  subscript(itemKey: ItemKey) -> AnyObject? { return value(forAttribute: itemKey.rawValue) as AnyObject? }

  var fileSystemName: String? { return self[.FSName] as? String }
  var displayName: String { return self[.DisplayName] as? String ?? "Unnamed Item" }
  var URL: Foundation.URL { return self[.URL] as! Foundation.URL }
  var path: String? { return self[.Path] as? String }
  var size: UInt64 { return (self[.FSSize] as! NSNumber).uint64Value }
  var creationDate: Date? { return self[.FSCreationDate] as? Date }
  var modificationDate: Date? { return self[.FSContentChangeDate] as? Date }
  var isUbiquitous: Bool? { return (self[.IsUbiquitous] as? NSNumber)?.boolValue }
  var hasUnresolvedConflicts: Bool? { return (self[.HasUnresolvedConflicts] as? NSNumber)?.boolValue }
  var downloading: Bool? { return (self[.IsDownloading] as? NSNumber)?.boolValue }
  var uploaded: Bool? { return (self[.IsUploaded] as? NSNumber)?.boolValue }
  var uploading: Bool? { return (self[.IsUploading] as? NSNumber)?.boolValue }
  var percentDownloaded: Double? { return (self[.PercentDownloaded] as? NSNumber)?.doubleValue }
  var percentUploaded: Double? { return (self[.PercentUploaded] as? NSNumber)?.doubleValue }
  var downloadingStatus: String? { return self[.DownloadingStatus] as? String }
  var downloadingError: NSError? { return self[.DownloadingError] as? NSError }
  var uploadingError: NSError? { return self[.UploadingError] as? NSError }

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
          name = $0.rawValue[key.characters.index(key.startIndex, offsetBy: 14) ..< key.characters.index(key.endIndex, offsetBy: -3)]
        case ~/"^NSMetadataUbiquitousItem[a-zA-Z]+Key$":
          name = $0.rawValue[key.characters.index(key.startIndex, offsetBy: 24) ..< key.characters.index(key.endIndex, offsetBy: -3)]
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

  var removedMetadataItems: [NSMetadataItem]? {
    return userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem]
  }

  var changedMetadataItems: [NSMetadataItem]? {
    return userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem]
  }

  var addedMetadataItems: [NSMetadataItem]? {
    return userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem]
  }

}
