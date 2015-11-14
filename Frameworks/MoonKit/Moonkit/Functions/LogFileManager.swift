//
//  LogFileManager.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/20/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import Lumberjack

public class LogFileManager: DDLogFileManagerDefault {

  public let directory: LogsDirectory

  static let dateFormatter: NSDateFormatter = {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "M/d/yy H:mm:ss.SSS"
    dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    dateFormatter.timeZone = NSTimeZone.localTimeZone()
    return dateFormatter
  }()

  /**
  Convenience initializer for a subdirectory of the logs directory

  - parameter subdirectory: String
  */
  public init(subdirectory: String? = nil) {
    let directory = LogsDirectory(subdirectory: subdirectory)
    guard let path = directory.URL.path else { fatalError("URL must be a valid file reference (i.e. URL.path != nil)") }
    self.directory = directory
    super.init(logsDirectory: path)
  }

}

public struct LogsDirectory: CustomStringConvertible {

  public let URL: NSURL
  private let wrapper: NSFileWrapper

  public var subdirectories: [NSFileWrapper] { return wrapper.fileWrappers?.values.filter({$0.directory}) ?? [] }
  public var logs: [NSFileWrapper] { return wrapper.fileWrappers?.values.filter({$0.regularFile}) ?? [] }
  public var latestLog: NSFileWrapper? {
    return logs.maxElement({
      switch (($0.fileAttributes[NSFileModificationDate] as? NSDate), ($1.fileAttributes[NSFileModificationDate] as? NSDate)) {
        case let (date1?, date2?) where date1.earlierDate(date2) === date1: return true
        default: return false
      }

    })
  }

  public var latestLogContent: String {
    guard let fileContent = latestLog?.regularFileContents else { return "" }
    return String(data: fileContent, encoding: NSUTF8StringEncoding) ?? ""
  }

  /**
  initWithSubdirectory:

  - parameter subdirectory: String? = nil
  */
  public init(subdirectory: String? = nil, createIfNeeded: Bool = true) {
    URL = NSURL(string: subdirectory ?? "", relativeToURL: LogManager.logsDirectory)!
    if !URL.checkResourceIsReachableAndReturnError(nil) {
      do {
        try NSFileManager.defaultManager().createDirectoryAtURL(URL,
                                    withIntermediateDirectories: true,
                                                     attributes: nil)
      } catch {
        logError(error)
      }
    }
    wrapper = try! NSFileWrapper(URL: URL, options: [.Immediate, .WithoutMapping])
  }

  public var description: String { return "\(URL.path!)" }
}