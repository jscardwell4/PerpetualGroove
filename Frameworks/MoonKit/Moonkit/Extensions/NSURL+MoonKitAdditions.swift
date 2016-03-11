//
//  NSURL+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/28/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public func +(lhs: NSURL, rhs: String) -> NSURL { return lhs.URLByAppendingPathComponent(rhs) }
public func +=(inout lhs: NSURL, rhs: String) { lhs = lhs + rhs }
public func +<S:SequenceType where S.Generator.Element == String>(lhs: NSURL, rhs: S) -> NSURL {
  guard let urlComponents = NSURLComponents(URL: lhs, resolvingAgainstBaseURL: false) else { return lhs }
  var path = urlComponents.path ?? ""
  for string in rhs { path += "/\(string)" }
  urlComponents.path = path
  guard let url = urlComponents.URL else { return lhs }
  return url
}

extension NSURL {
  public func isEqualToFileURL(other: NSURL) -> Bool {
    assert(fileURL, "\(#function) requires that `self` is a file URL")
    assert(other.fileURL, "\(#function) requires that `other` is a file URL")

    guard let url1 = filePathURL, url2 = other.filePathURL else { return false }

    var reference1: AnyObject?, reference2: AnyObject?
    do {
      try url1.getResourceValue(&reference1, forKey: NSURLFileResourceIdentifierKey)
      try url2.getResourceValue(&reference2, forKey: NSURLFileResourceIdentifierKey)
    } catch {
      logError(error)
      return false
    }
    guard reference1 != nil && reference2 != nil else { return false }
    return reference1!.isEqual(reference2!)
  }

  public var pathBaseName: String? {
    guard let lastPathComponent = lastPathComponent, pathExtension = pathExtension else { return nil }
    let extensionCount = pathExtension.characters.count
    guard extensionCount > 0 else { return lastPathComponent }
    return lastPathComponent[..<lastPathComponent.endIndex.advancedBy(-(extensionCount + 1))]
  }
}
