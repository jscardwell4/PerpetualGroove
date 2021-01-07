//
//  NSMetadataItem.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/7/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

/// Extends `NSMetadataItem` to provide more convenient access to the various file
/// attributes of the item.
extension NSMetadataItem
{
  /// Enumeration wrapping various file attribute keys.
  enum ItemKey: String, EnumerableType
  {
    case fsName = "kMDItemFSName"
    case displayName = "kMDItemDisplayName"
    case url = "kMDItemURL"
    case path = "kMDItemPath"
    case fsSize = "kMDItemFSSize"
    case fsCreationDate = "kMDItemFSCreationDate"
    case fsContentChangeDate = "kMDItemFSContentChangeDate"
    case isUbiquitous = "NSMetadataItemIsUbiquitousKey"
    case hasUnresolvedConflicts = "NSMetadataUbiquitousItemHasUnresolvedConflictsKey"
    case isDownloading = "NSMetadataUbiquitousItemIsDownloadingKey"
    case isUploaded = "NSMetadataUbiquitousItemIsUploadedKey"
    case isUploading = "NSMetadataUbiquitousItemIsUploadingKey"
    case percentDownloaded = "NSMetadataUbiquitousItemPercentDownloadedKey"
    case percentUploaded = "NSMetadataUbiquitousItemPercentUploadedKey"
    case downloadingStatus = "NSMetadataUbiquitousItemDownloadingStatusKey"
    case downloadingError = "NSMetadataUbiquitousItemDownloadingErrorKey"
    case uploadingError = "NSMetadataUbiquitousItemUploadingErrorKey"
    static var allCases: [ItemKey]
    {
      return [fsName, displayName, url, path, fsSize, fsCreationDate,
              fsContentChangeDate, isUbiquitous, hasUnresolvedConflicts,
              isDownloading, isUploaded, isUploading, percentDownloaded,
              percentUploaded, downloadingStatus, downloadingError, uploadingError]
    }
  }

  /// Returns the value returned by invoking `value(forAttribute:)`.
  subscript(itemKey: ItemKey) -> Any? { value(forAttribute: itemKey.rawValue) as Any? }

  var fileSystemName: String? { self[.fsName] as? String }
  var displayName: String { self[.displayName] as? String ?? "Unnamed Item" }
  var URL: Foundation.URL { self[.url] as! Foundation.URL }
  var path: String? { self[.path] as? String }
  var size: UInt64 { (self[.fsSize] as! NSNumber).uint64Value }
  var creationDate: Date? { self[.fsCreationDate] as? Date }
  var modificationDate: Date? { self[.fsContentChangeDate] as? Date }
  var isUbiquitous: Bool? { (self[.isUbiquitous] as? NSNumber)?.boolValue }
  var hasUnresolvedConflicts: Bool? { (self[.hasUnresolvedConflicts] as? NSNumber)?.boolValue }
  var downloading: Bool? { (self[.isDownloading] as? NSNumber)?.boolValue }
  var uploaded: Bool? { (self[.isUploaded] as? NSNumber)?.boolValue }
  var uploading: Bool? { (self[.isUploading] as? NSNumber)?.boolValue }
  var percentDownloaded: Double? { (self[.percentDownloaded] as? NSNumber)?.doubleValue }
  var percentUploaded: Double? { (self[.percentUploaded] as? NSNumber)?.doubleValue }
  var downloadingStatus: String? { self[.downloadingStatus] as? String }
  var downloadingError: NSError? { self[.downloadingError] as? NSError }
  var uploadingError: NSError? { self[.uploadingError] as? NSError }

  var attributesDescription: String
  {
    var result = "NSMetadataItem {\n\t"
    result += "\n\t".join(ItemKey.allCases.compactMap
    {
      guard let value = self[$0] else { return nil }
      let key = $0.rawValue
      let name: String?
      switch key
      {
        case ~/"^kMDItem[a-zA-Z]+$":
          name = String($0.rawValue[key.index(key.startIndex, offsetBy: 7)...])
        case ~/"^NSMetadataItem[a-zA-Z]+Key$":
          name = String($0.rawValue[key.index(key.startIndex, offsetBy: 14)
                                      ..< key.index(key.endIndex, offsetBy: -3)])
        case ~/"^NSMetadataUbiquitousItem[a-zA-Z]+Key$":
          name = String($0.rawValue[key.index(key.startIndex, offsetBy: 24)
                                      ..< key.index(key.endIndex, offsetBy: -3)])
        default:
          name = nil
      }
      guard name != nil else { return nil }
      return "\(name!): \(value)"
    })
    result += "\n}"
    return result
  }
}

extension Notification
{
  /// The removed items for a notification posted by an instance of `NSMetaDataQuery`
  /// or `nil`.
  var removedMetadataItems: [NSMetadataItem]?
  {
    userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem]
  }

  /// The changed items for a notification posted by an instance of `NSMetaDataQuery`
  /// or `nil`.
  var changedMetadataItems: [NSMetadataItem]?
  {
    userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem]
  }

  /// The added items for a notification posted by an instance of `NSMetaDataQuery`
  /// or `nil`.
  var addedMetadataItems: [NSMetadataItem]?
  {
    userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem]
  }
}
