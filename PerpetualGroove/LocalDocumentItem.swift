//
//  LocalDocumentItem.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/7/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

final class LocalDocumentItem: NSObject {

  let URL: Foundation.URL
  fileprivate let fileWrapper: FileWrapper

  var displayName: String {
    guard let name = fileWrapper.preferredFilename else { fatalError("file wrapper has no name") }
    return name
  }

  var size: UInt64 { return (fileWrapper.fileAttributes as NSDictionary).fileSize() }
  var modificationDate: Date? { return (fileWrapper.fileAttributes as NSDictionary).fileModificationDate() }
  var creationDate: Date? { return (fileWrapper.fileAttributes as NSDictionary).fileCreationDate() }


  /**
  init:

  - parameter URL: NSURL
  */
  init(_ fileURL: Foundation.URL) throws {
    self.URL = fileURL
    var thrownError: Error?
    let wrapper: FileWrapper
    do {
      wrapper = try FileWrapper(url: fileURL, options: .withoutMapping)
    } catch {
      wrapper = FileWrapper()
      thrownError = error
    }
    fileWrapper = wrapper
    super.init()
    guard thrownError == nil else { throw thrownError! }
  }

  /**
   init:base:

   - parameter wrapper: NSFileWrapper
   - parameter base: NSURL
   */
  init?(_ wrapper: FileWrapper, _ base: Foundation.URL) {
    var isDirectory = ObjCBool(false)
    let fileManager = FileManager.default
    guard let directoryPath = String(CString: (base as NSURL).fileSystemRepresentation, encoding: String.Encoding.utf8)
      , fileManager.fileExists(atPath: directoryPath, isDirectory: &isDirectory) && isDirectory,
      let fileName = wrapper.preferredFilename else {
        return nil
    }
    let fileURL = base + fileName
    guard let filePath = String(CString: fileURL.fileSystemRepresentation, encoding: String.Encoding.utf8)
      , fileManager.fileExistsAtPath(filePath, isDirectory: &isDirectory) && !isDirectory else {
        return nil
    }
    self.URL = fileURL
    fileWrapper = wrapper
    super.init()
  }

}
