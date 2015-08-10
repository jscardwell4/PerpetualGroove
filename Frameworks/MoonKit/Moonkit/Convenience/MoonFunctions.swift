//
//  MoonFunctions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 6/30/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

private let fileManager = NSFileManager.defaultManager()

public class MoonFunctions {

  // MARK: - File paths



  /**
  libraryPath

  - returns: String?
  */
  @objc public class func libraryPath() -> String! {
    let urls = fileManager.URLsForDirectory(NSSearchPathDirectory.LibraryDirectory,
                                  inDomains: NSSearchPathDomainMask.UserDomainMask)
    return urls.first?.path
  }

  /**
  libraryPathToFile:

  - parameter file: String

  - returns: String?
  */
  @objc public class func libraryPathToFile(file: String) -> String {
    return (libraryPath() as NSString).stringByAppendingPathComponent(file)
  }

  /**
  cachePath

  - returns: String?
  */
  @objc public class func cachePath() -> String {
    return libraryPathToFile("Caches/\(NSBundle.mainBundle().bundleIdentifier)")
  }

  /**
  cachePathToFile:

  - parameter file: String

  - returns: String?
  */
  @objc public class func cachePathToFile(file: String) -> String {
    return (cachePath() as NSString).stringByAppendingPathComponent(file)
  }

  /**
  documentsPath

  - returns: String?
  */
  @objc public class func documentsPath() -> String! {
    let urls = fileManager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory,
                                                     inDomains: NSSearchPathDomainMask.UserDomainMask)
    return urls.first?.path
  }

  /**
  documentsDirectoryContents

  - returns: [String]
  */
  @objc public class func documentsDirectoryContents() -> [String] {
    do {
      let directoryContents = try fileManager.contentsOfDirectoryAtPath(documentsPath())
      return directoryContents
    } catch {
      logError(error)
    }
    return []
  }

  /**
  documentsPathToFile:

  - parameter file: String

  - returns: String?
  */
  @objc public class func documentsPathToFile(file: String) -> String? {
    return (documentsPath() as NSString).stringByAppendingPathComponent(file)
  }

}
// MARK: - Exceptions



public func MSRaiseException(name:String, reason:String, userinfo:[NSObject:AnyObject]? = nil) {
  NSException(name: name, reason: reason, userInfo: userinfo).raise()
}

public func MSRaiseInvalidArgumentException(name:String, reason:String, userinfo:[NSObject:AnyObject]? = nil) {
  MSRaiseException(NSInvalidArgumentException, reason: reason, userinfo: userinfo)
}

public func MSRaiseInvalidNilArgumentException(name:String, arg:String, userinfo:[NSObject:AnyObject]? = nil) {
  MSRaiseException(NSInvalidArgumentException, reason: "\(arg) must not be nil", userinfo: userinfo)
}

public func MSRaiseInvalidIndexException(name:String, arg:String, userinfo:[NSObject:AnyObject]? = nil) {
  MSRaiseException(NSRangeException, reason: "\(arg) out of range", userinfo: userinfo)
}

public func MSRaiseInternalInconsistencyException(name:String, reason:String, userinfo:[NSObject:AnyObject]? = nil) {
  MSRaiseException(NSInternalInconsistencyException, reason: reason, userinfo: userinfo)
}

