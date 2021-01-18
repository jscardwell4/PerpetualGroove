//
//  LocalDocumentItem.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/7/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev

// MARK: - LocalDocumentItem

/// A class for wrapping a document whose file is located on the local disk.
@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
public final class LocalDocumentItem: NSObject
{
  // MARK: Stored Properties
  
  /// The document's file url.
  public let url: URL
  
  /// Wrapper for the document's file.
  private let wrapper: FileWrapper
  
  // MARK: Computed Properties
  
  /// The name of the document shown in the user interface.
  public var displayName: String { wrapper.preferredFilename ?? "Local Document" }
  
  /// The size of the document's file on disk or `0` if no such file exists.
  public var size: UInt64
  {
    wrapper.fileAttributes[FileAttributeKey.size.rawValue] as? UInt64 ?? 0
  }
  
  /// The date the document's file was last modified.
  public var modificationDate: Date?
  {
    wrapper.fileAttributes[FileAttributeKey.modificationDate.rawValue] as? Date
  }
  
  /// The date the  document's file was created.
  public var creationDate: Date?
  {
    wrapper.fileAttributes[FileAttributeKey.creationDate.rawValue] as? Date
  }
  
  // MARK: Initializing
  
  /// Default initializer for `LocalDocumentItem`.
  ///
  /// - Parameter url: The document's file url.
  /// - Throws: Any error encountered by `FileWrapper` intializing with `url`.
  public init(url: URL) throws
  {
    self.url = url
    wrapper = try FileWrapper(url: url, options: .withoutMapping)
    super.init()
  }
  
  /// Initialize from an existing file wrapper.
  ///
  /// - Parameter fileWrapper: The wrapper for the document's file.
  ///
  /// - Requires: `fileWrapper.preferredFilename != nil` and the wrapped file
  ///             is located in the local documents directory
  ///
  /// - Throws: `Error.invalidFileWrapper` or any error thrown
  ///            by `LocalDocumentItem.init(url:)`.
  public convenience init(_ fileWrapper: FileWrapper) throws
  {
    guard let baseURL = DocumentManager.StorageLocation.local.root
    else
    {
      fatalError("Failed to get root directory for local document storage")
    }
    
    guard let preferredFileName = fileWrapper.preferredFilename
    else
    {
      throw Error.invalidFileWrapper
    }
    
    let url = baseURL + preferredFileName
    
    guard fileWrapper.matchesContents(of: url)
    else
    {
      throw Error.invalidFileWrapper
    }
    
    try self.init(url: url)
  }
}

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
public extension LocalDocumentItem
{
  /// Enumeration of the possible errors thrown by `LocalDocumentItem`.
  enum Error: String, Swift.Error
  {
    case invalidFileWrapper
  }
}
