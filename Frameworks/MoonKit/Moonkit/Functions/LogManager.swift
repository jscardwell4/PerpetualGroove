//
//  LogManager.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/21/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import Lumberjack

public class LogManager {

  public typealias LogFlag = DDLogFlag

  public typealias LogLevel = DDLogLevel

  public struct LogContext: OptionSetType {
    public let rawValue: Int
    public init(rawValue: Int) {
      if rawValue != Int.min && rawValue < 0 { self = .Ignored }
      else { self.rawValue = rawValue }
    }
    public static let Ignored  = LogContext(rawValue: Int.min)
    public static let Default  = LogContext(rawValue: 0b0000_0000)
    public static let File     = LogContext(rawValue: 0b0000_1000)
    public static let TTY      = LogContext(rawValue: 0b0000_1000)
    public static let ASL      = LogContext(rawValue: 0b0000_1000)
    public static let MoonKit  = LogContext(rawValue: 0b0000_1000)
    public static let UnitTest = LogContext(rawValue: 0b0001_0000)
    
    public static let Test     = LogContext.UnitTest ∪ LogContext.Console ∪ LogContext.File
    public static let Console  = LogContext.TTY ∪ LogContext.ASL
    public static let Any      = LogContext(rawValue: Int.max)
  }

  public static var defaultLogDirectory: NSURL {
    let manager = NSFileManager.defaultManager()
    let cache = cacheURL
    var error: NSError?
    if !cache.checkResourceIsReachableAndReturnError(&error) {
      if let error = error { logError(error) }
      do {
        try manager.createDirectoryAtURL(cache, withIntermediateDirectories: false, attributes: nil)
      } catch {
        logError(error)
        fatalError("Failed to create cache directory: '\(cache)'")
      }
    }
    let logs = cache + "Logs"
    error = nil
    if !logs.checkResourceIsReachableAndReturnError(&error) {
      if let error = error { logError(error) }
      do {
        try manager.createDirectoryAtURL(logs, withIntermediateDirectories: false, attributes: nil)
      } catch {
        logError(error)
        fatalError("Failed to create logs directory: '\(logs)'")
      }
    }

    return logs
  }

  public static var logLevel: LogLevel = .Debug

  static var logLevelsByFile: [String:LogLevel] = [:]
  static var logLevelsByType: [ObjectIdentifier:LogLevel] = [:]

  /**
  logLevelForFile:

  - parameter file: String

  - returns: LogLevel
  */
  public static func logLevelForFile(file: String) -> LogLevel { return logLevelsByFile[file] ?? logLevel }

  /**
  setLogLevel:forFile:

  - parameter level: LogManager.LogLevel
  - parameter file: String = __FILE__
  */
  public static func setLogLevel(level: LogManager.LogLevel, forFile file: String = __FILE__) {
    logLevelsByFile[file] = level
  }

  /**
  logLevelForType:

  - parameter type: Any.Type

  - returns: LogLevel
  */
  public static func logLevelForType(type: Any.Type) -> LogLevel {
    return logLevelsByType[ObjectIdentifier(type.dynamicType.self)] ?? logLevel
  }


  public static var logContext: LogContext = .Console

  static var logContextsByFile: [String:LogContext] = [:]
  static var logContextsByType: [ObjectIdentifier:LogContext] = [:]

  /**
  logContextForFile:

  - parameter file: String

  - returns: LogContext
  */
  public static func logContextForFile(file: String) -> LogContext { return logContextsByFile[file] ?? logContext }

  /**
  setLogContext:forFile:

  - parameter context: LogManager.LogContext
  - parameter file: String = __FILE__
  */
  public static func setLogContext(context: LogManager.LogContext, forFile file: String = __FILE__) {
    logContextsByFile[file] = context
  }

  /**
  logContextForType:

  - parameter type: Any.Type

  - returns: LogContext
  */
  public static func logContextForType(type: Any.Type) -> LogContext {
    return logContextsByType[ObjectIdentifier(type.dynamicType.self)] ?? logContext
  }

  /**
  setLogContext:forType:

  - parameter context: LogContext
  - parameter type: Any.Type
  */
  public static func setLogContext(context: LogContext, forType type: Any.Type) {
    logContextsByType[ObjectIdentifier(type.dynamicType.self)] = context
  }

  /**
  setLogLevel:forType:

  - parameter context: LogLevel
  - parameter type: Any.Type
  */
  public static func setLogLevel(context: LogLevel, forType type: Any.Type) {
    logLevelsByType[ObjectIdentifier(type.dynamicType.self)] = context
  }

  /** addConsoleLoggers */
  public class func addConsoleLoggers() {
    ColorLog.colorEnabled = true
    addTaggingTTYLogger()
    addTaggingASLLogger()
  }

  /** addTTYLogger */
  public class func addTTYLogger() {
    let formatter = LogFormatter(context: .TTY, options: [.UseFileInsteadOfSEL, .EnableColor])
    formatter.prompt = ">"
    let tty = DDTTYLogger.sharedInstance()
    tty.logFormatter = formatter
    tty.colorsEnabled = true
    DDLog.addLogger(tty)
  }

  /** addASLLogger */
  public class func addASLLogger() {
    let formatter = LogFormatter(context: .ASL, options: [.UseFileInsteadOfSEL])
    formatter.prompt = ">"
    let asl = DDASLLogger.sharedInstance()
    asl.logFormatter = formatter
    DDLog.addLogger(asl)
  }

  /** addTaggingTTYLogger */
  public class func addTaggingTTYLogger() {
    let formatter = LogFormatter(context: .TTY, options: [.UseFileInsteadOfSEL, .EnableColor], tagging: true)
    let tty = DDTTYLogger.sharedInstance()
    tty.logFormatter = formatter
    tty.colorsEnabled = true
    DDLog.addLogger(tty)
  }

  /** addTaggingASLLogger */
  public class func addTaggingASLLogger() {
    let formatter = LogFormatter(context: .ASL, options: [.UseFileInsteadOfSEL], tagging: true)
    let asl = DDASLLogger.sharedInstance()
    asl.logFormatter = formatter
    DDLog.addLogger(asl)
  }

  /**
  logMessage:flag:function:line:file:className:context:

  - parameter message: String
  - parameter flag: LogManager.LogFlag
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  - parameter className: String? = nil
  - parameter context: Int = Int(LOG_CONTEXT_CONSOLE)
  */
  public static func logMessage(message: String,
                  asynchronous: Bool,
                          flag: LogFlag,
                      function: String = __FUNCTION__,
                          line: UInt = __LINE__,
                          file: String = __FILE__,
                       context: LogContext? = nil)
  {
    let level = logLevelForFile(file)
    let context = context ?? logContextForFile(file)
    
    guard flag.rawValue & level.rawValue != 0 else { return }
    let logMessage = DDLogMessage(
      message: message,
      level: level,
      flag: flag,
      context: context.rawValue,
      file: file,
      function: function,
      line: line,
      tag: nil,
      options: [.CopyFile, .CopyFunction],
      timestamp: nil
    )
    DDLog.log(asynchronous, message: logMessage)

    #if TARGET_INTERFACE_BUILDER
      logIB(message, function: function, line: line, file: file, flag: flag)
    #endif

  }

  /**
  defaultFileLoggerForContext:directory:

  - parameter context: LogContext
  - parameter directory: NSURL

  - returns: DDFileLogger
  */
  public class func defaultFileLoggerForContext(context: LogContext, directory: NSURL) -> DDFileLogger {
    let fileManager = DDLogFileManagerDefault(logsDirectory: directory.path)
    fileManager.maximumNumberOfLogFiles = 5
    let fileLogger = DDFileLogger(logFileManager: fileManager)
    fileLogger.rollingFrequency = 60 * 60 * 24
    fileLogger.maximumFileSize = 0
    fileLogger.logFormatter = LogFormatter(context: context, options: [.UseFileInsteadOfSEL], tagging: true)
    return fileLogger
  }

  /**
  addDefaultFileLoggerForContext:directory:

  - parameter context: LogContext
  - parameter directory: NSURL
  */
  public class func addDefaultFileLoggerForContext(context: LogContext, directory: NSURL) {
    DDLog.addLogger(defaultFileLoggerForContext(context, directory: directory))
  }

}

