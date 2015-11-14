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

  public static var logLevel: LogLevel = .Debug

  static var logLevelsByFile: [String:LogLevel] = [:]
  static var logLevelsByType: [ObjectIdentifier:LogLevel] = [:]


  public static var logContext: LogContext = .Console

  static var logContextsByFile: [String:LogContext] = [:]
  static var logContextsByType: [ObjectIdentifier:LogContext] = [:]

  /**
  logMessage:asynchronous:flag:function:line:file:context:tag:

  - parameter message: String
  - parameter asynchronous: Bool
  - parameter flag: LogFlag
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  - parameter context: LogContext? = nil
  - parameter tag: AnyObject? = nil
  */
  public static func logMessage(message: String,
                  asynchronous: Bool,
                          flag: LogFlag,
                      function: String = __FUNCTION__,
                          line: UInt = __LINE__,
                          file: String = __FILE__,
                       context: LogContext? = nil,
                           tag: LogMessage.Tag? = nil)
  {
    let level = logLevelForFile(file)
    let context = context ?? logContextForFile(file)
    
    guard level ∋ flag else { return }
    let logMessage = LogMessage(
      message: message,
      level: level,
      flag: flag,
      context: context,
      file: file,
      function: function,
      line: line,
      tag: tag
    )
    DDLog.log(asynchronous, message: logMessage)

    #if TARGET_INTERFACE_BUILDER
      logIB(message, function: function, line: line, file: file, flag: flag)
    #endif

  }

  public class LogMessage: DDLogMessage {

    /**
    initWithMessage:level:flag:context:file:fileName:function:line:

    - parameter message: String = ""
    - parameter level: LogLevel = LogManager.logLevel
    - parameter flag: LogFlag = .Debug
    - parameter context: LogContext = .Console
    - parameter file: String = __FILE__
    - parameter fileName: String? = nil
    - parameter function: String = __FUNCTION__
    - parameter line: UInt = __LINE__
    */
    init(message: String = "",
         level: LogLevel = LogManager.logLevel,
         flag: LogFlag = .Debug,
         context: LogContext = .Console,
         file: String = __FILE__,
         function: String = __FUNCTION__,
         line: UInt = __LINE__,
         tag: Tag? = nil)
    {
      super.init(
        message: message,
        level: level,
        flag: flag,
        context: context.rawValue,
        file: file,
        function: function,
        line: line,
        tag: tag as? AnyObject,
        options: [.CopyFile, .CopyFunction],
        timestamp: nil
      )
    }

    public class Tag {
      var className: String?
      var objectName: String?
      var contextName: String?
      var queueName: String?

      /**
      initWithObject:objectName:className:contextName:

      - parameter object: Any? = nil
      - parameter objectName: String? = nil
      - parameter className: String? = nil
      - parameter contextName: String? = nil
      */
      init(objectName: String? = nil, className: String? = nil, contextName: String? = nil, queueName: String? = nil) {
        self.objectName = objectName
        self.className = className
        self.contextName = contextName
        self.queueName = queueName
      }
    }
    
  }

  public typealias LogLevel = DDLogLevel

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

    /**
  setLogLevel:forType:

  - parameter context: LogLevel
  - parameter type: Any.Type
  */
  public static func setLogLevel(context: LogLevel, forType type: Any.Type) {
    logLevelsByType[ObjectIdentifier(type.dynamicType.self)] = context
  }

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

  private static var _logsDirectory: NSURL?

  public static var logsDirectory: NSURL {
    guard _logsDirectory == nil else { return _logsDirectory! }

    func generateLogDirectory() -> NSURL {
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

    #if TARGET_IPHONE_SIMULATOR
      let directory: NSURL
      if let path = NSProcessInfo.processInfo().environment["MOONKIT_LOG_DIR"] {
        _logsDirectory = NSURL(fileURLWithPath: path)
      } else {
        _logsDirectory = generateLogDirectory()
      }
    #else
      _logsDirectory = generateLogDirectory()
    #endif
    guard _logsDirectory != nil else { fatalError("failed to determine suitable log directory") }
    return _logsDirectory!
  }

  /** addConsoleLoggers */
  public class func addConsoleLoggers() {
    ColorLog.colorEnabled = true
    addTaggingTTYLogger()
    addTaggingASLLogger()
  }


  public static var ttyFormatter: LogFormatter { return DDTTYLogger.sharedInstance().logFormatter as! LogFormatter }
  public static var aslFormatter: LogFormatter { return DDASLLogger.sharedInstance().logFormatter as! LogFormatter }

  /** addTTYLogger */
  public class func addTTYLogger() {
    let formatter = LogFormatter(context: .TTY, options: [.UseFileInsteadOfSEL, .EnableColor])
    let tty = DDTTYLogger.sharedInstance()
    tty.logFormatter = formatter
    tty.colorsEnabled = true
    DDLog.addLogger(tty)
  }

  /** addASLLogger */
  public class func addASLLogger() {
    let formatter = LogFormatter(context: .ASL, options: [.UseFileInsteadOfSEL])
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
  defaultFileLoggerForContext:directory:

  - parameter context: LogContext
  - parameter subdirectory: String

  - returns: DDFileLogger
  */
  public class func defaultFileLoggerForContext(context: LogContext, subdirectory: String?) -> DDFileLogger {
    let fileManager = subdirectory == nil ? LogFileManager() : LogFileManager(subdirectory: subdirectory!)
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
  - parameter subdirectory: String?
  */
  public class func addDefaultFileLoggerForContext(context: LogContext, subdirectory: String? = nil) {
    DDLog.addLogger(defaultFileLoggerForContext(context, subdirectory: subdirectory))
  }

}

extension DDLogFlag: CustomStringConvertible {
  public var description: String {
    switch self {
      case DDLogFlag.Error:   return "E"
      case DDLogFlag.Warning: return "W"
      case DDLogFlag.Debug:   return "D"
      case DDLogFlag.Info:    return "I"
      case DDLogFlag.Verbose: return "V"
      default:                return "?"
    }
  }
}

extension DDLogLevel {
  public func contains(flag: DDLogFlag) -> Bool {
    return rawValue & flag.rawValue == flag.rawValue
  }
}

public func ∋(lhs: LogManager.LogLevel, rhs: LogManager.LogFlag) -> Bool {
  return lhs.rawValue & rhs.rawValue == rhs.rawValue
}

public func ∈(lhs: LogManager.LogFlag, rhs: LogManager.LogLevel) -> Bool {
  return rhs ∋ lhs
}

public func ∌(lhs: LogManager.LogLevel, rhs: LogManager.LogFlag) -> Bool {
  return !(lhs ∋ rhs)
}

public func ∉(lhs: LogManager.LogFlag, rhs: LogManager.LogLevel) -> Bool {
  return !(lhs ∈ rhs)
}


