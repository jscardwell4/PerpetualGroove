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

  let URL: NSURL
  private let fileWrapper: NSFileWrapper

  var displayName: String {
    guard let name = fileWrapper.preferredFilename else { fatalError("file wrapper has no name") }
    return name
  }

  var size: UInt64 { return (fileWrapper.fileAttributes as NSDictionary).fileSize() }
  var modificationDate: NSDate? { return (fileWrapper.fileAttributes as NSDictionary).fileModificationDate() }
  var creationDate: NSDate? { return (fileWrapper.fileAttributes as NSDictionary).fileCreationDate() }


  /**
  init:

  - parameter URL: NSURL
  */
  init(_ fileURL: NSURL) throws {
    self.URL = fileURL
    var thrownError: ErrorType?
    let wrapper: NSFileWrapper
    do {
      wrapper = try NSFileWrapper(URL: fileURL, options: .WithoutMapping)
    } catch {
      wrapper = NSFileWrapper()
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
  init?(_ wrapper: NSFileWrapper, _ base: NSURL) {
    var isDirectory = ObjCBool(false)
    let fileManager = NSFileManager.defaultManager()
    guard let directoryPath = String(CString: base.fileSystemRepresentation, encoding: NSUTF8StringEncoding)
      where fileManager.fileExistsAtPath(directoryPath, isDirectory: &isDirectory) && isDirectory,
      let fileName = wrapper.preferredFilename else {
        return nil
    }
    let fileURL = base + fileName
    guard let filePath = String(CString: fileURL.fileSystemRepresentation, encoding: NSUTF8StringEncoding)
      where fileManager.fileExistsAtPath(filePath, isDirectory: &isDirectory) && !isDirectory else {
        return nil
    }
    self.URL = fileURL
    fileWrapper = wrapper
    super.init()
  }

}
