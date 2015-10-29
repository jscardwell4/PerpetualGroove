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

//  public private(set) var currentLogFile: String?
  public var logsDirectoryURL: NSURL

  public var fileNamePrefix: String?

  /**
  init:

  - parameter dir: NSURL
  */
  public init(directory dir: NSURL) throws {
    logsDirectoryURL = dir;
    super.init(logsDirectory: dir.absoluteURL.path!)
    let manager = NSFileManager.defaultManager()
    var error: NSError?
    if !dir.checkResourceIsReachableAndReturnError(&error) {
      if let error = error { logError(error) }
      try manager.createDirectoryAtURL(dir, withIntermediateDirectories: false, attributes: nil)
    }
  }

  /** deleteOldLogFiles */
  private func deleteOldLogFiles() throws {
    guard maximumNumberOfLogFiles > 0 else { return }
    var sortedLogFileInfos = self.sortedLogFileInfos()

    // Do we consider the first file?
    // We are only supposed to be deleting archived files.
    // The first file is likely the log file that is currently being written to.
    // So in most cases, we do not want to consider this file for deletion.
    var count = sortedLogFileInfos.count
    var excludeFirstFile = false

    if count > 0 {
      let logFileInfo = sortedLogFileInfos[0] as! DDLogFileInfo
      if !logFileInfo.isArchived { excludeFirstFile = true }
    }

    if excludeFirstFile {
      count--
      sortedLogFileInfos.removeAtIndex(0)
    }

    let manager = NSFileManager.defaultManager()
    for info in sortedLogFileInfos { try manager.removeItemAtPath(info.filePath) }

  }

  /**
  didRollAndArchiveLogFile:

  - parameter logFilePath: String!
  */
  public override func didRollAndArchiveLogFile(logFilePath: String!) {}

//  /**
//  createNewLogFile
//
//  - returns: String!
//  */
//  public override func createNewLogFile() -> String! {
//    let dateFormatter = NSDateFormatter()
//    dateFormatter.dateFormat = "M/d/yy H:mm:ss.SSS"
//    var fileName = "\(dateFormatter.stringFromDate(NSDate())).log"
//    var url = logsDirectoryURL
//    if let prefix = fileNamePrefix {
//      fileName = "\(prefix)-\(fileName)"
//    } else if let lastPathComponent = url.lastPathComponent where lastPathComponent != "Logs" {
//      fileName = "\(lastPathComponent)-\(fileName)"
//    }
//    url += fileName
//    let manager = NSFileManager.defaultManager()
//    var error: NSError?
//    if !url.checkResourceIsReachableAndReturnError(&error) {
//      if let error = error { logError(error) }
//      logVerbose("creating new log file: '\(url.path!)'")
//      manager.createFileAtPath(url.path!, contents: nil, attributes: nil)
//      _ = try? deleteOldLogFiles()
//      currentLogFile = url.path
//    }
//    return currentLogFile
//  }

  static let dateFormatter: NSDateFormatter = {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "M/d/yy H:mm:ss.SSS"
    dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    dateFormatter.timeZone = NSTimeZone.localTimeZone()
    return dateFormatter
  }()

  public override var newLogFileName: String {
    var result = "\(NSProcessInfo.processInfo().processName)"
    if let prefix = fileNamePrefix { result += "-\(prefix)" }
    result += "\(LogFileManager.dateFormatter.stringFromDate(NSDate()))"
    return result
  }

  /**
  isLogFile:

  - parameter fileName: String!

  - returns: Bool
  */
  public override func isLogFile(fileName: String!) -> Bool {
    return fileName.hasSuffix(".log")
  }
}