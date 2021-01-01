//
//  Storage.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import Foundation

/// An enumeration for wrapping the source of a sound font file.
public enum Storage {
  /// The data for the file is located on disk.
  case url(URL)

  /// The data for the file is located in memory.
  case memory(Data)

  /// Returns the wrapped file data.
  /// 
  /// - Throws: Any error thrown attempting to retrieve the contents of a url.
  public func data() throws -> Data {
    switch self {
      case let .url(url):
        return try Data(contentsOf: url, options: [.uncached, .alwaysMapped])
      case let .memory(data):
        return data
    }
  }

}

extension Storage: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .url(url):
        return ".url(\(url.path))"
      case let .memory(data):
        return ".data(\(data.count) bytes)"
    }
  }
}
