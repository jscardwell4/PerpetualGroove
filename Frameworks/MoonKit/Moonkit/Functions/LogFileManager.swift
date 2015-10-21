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

  public private(set) var currentLogFile: String?
  public var customLogsDirectory: String?

  public var fileNamePrefix: String?

  public override func logsDirectory() -> String { return customLogsDirectory ?? super.logsDirectory() }

  /**
  setLogsDirectory:

  - parameter directory: String
  */
  public func setLogsDirectory(directory: String) throws {
    let manager = NSFileManager.defaultManager()
    if !manager.fileExistsAtPath(directory) {
      try manager.createDirectoryAtPath(directory, withIntermediateDirectories: true, attributes: nil)
    }
    customLogsDirectory = directory
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

  /**
  createNewLogFile

  - returns: String!
  */
  public override func createNewLogFile() -> String! {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "M/d/yy H:mm:ss.SSS"
    var fileName = "\(dateFormatter.stringFromDate(NSDate())).log"
    let directory = logsDirectory()
    if let prefix = fileNamePrefix { fileName = "\(prefix)-\(fileName)"}
    else {
      let lastPathComponent = (directory as NSString).lastPathComponent
      if lastPathComponent != "Logs" { fileName = "\(lastPathComponent)-\(fileName)" }
    }
    let filePath = "\(directory)/\(fileName)"
    let manager = NSFileManager.defaultManager()
    if !manager.fileExistsAtPath(filePath) {
      logVerbose("creating new log file: '\(filePath)'")
      manager.createFileAtPath(filePath, contents: nil, attributes: nil)
      _ = try? deleteOldLogFiles()
      currentLogFile = filePath
    }
    return currentLogFile
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