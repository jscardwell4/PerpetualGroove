//
//  MoonFunctions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 6/30/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

// MARK: - File paths

public var libraryURL: NSURL {
  return NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask)[0]
}

/**
libraryURLToFile:

- parameter file: String

- returns: NSURL
*/
public func libraryURLToFile(file: String) -> NSURL {
  return libraryURL.URLByAppendingPathComponent(file, isDirectory: false)
}

public var cacheURL: NSURL { return libraryURLToFile("Caches/\(NSBundle.mainBundle().bundleIdentifier)") }

/**
cacheURLToFile:

- parameter file: String

- returns: NSURL
*/
public func cacheURLToFile(file: String) -> NSURL { return cacheURL.URLByAppendingPathComponent(file, isDirectory: false) }

public var documentsURL: NSURL {
  return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
}

/** documentsDirectoryContents */
public func documentsDirectoryContents() throws -> [NSURL] {
  return try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsURL, includingPropertiesForKeys: nil, options: [])
}

/**
documentsURLToFile:

- parameter file: String

- returns: NSURL
*/
public func documentsURLToFile(file: String) -> NSURL {
  return documentsURL.URLByAppendingPathComponent(file, isDirectory: false)
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

