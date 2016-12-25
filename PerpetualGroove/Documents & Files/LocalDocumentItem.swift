//
//  LocalDocumentItem.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/7/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

// TODO: Review file

final class LocalDocumentItem: NSObject {

  let url: URL
  
  private let wrapper: FileWrapper

  var displayName: String { return wrapper.preferredFilename! }

  var size: UInt64 {
    return wrapper.fileAttributes[FileAttributeKey.size.rawValue] as? UInt64 ?? 0
  }

  var modificationDate: Date? {
    return wrapper.fileAttributes[FileAttributeKey.modificationDate.rawValue] as? Date
  }

  var creationDate: Date? {
    return wrapper.fileAttributes[FileAttributeKey.creationDate.rawValue] as? Date
  }


  init(url: URL) throws {
    self.url = url
    wrapper = try FileWrapper(url: url, options: .withoutMapping)
    super.init()
  }

}
