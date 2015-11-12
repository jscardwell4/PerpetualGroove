//
//  Loggable.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/21/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

/**
nameForCurrentQueue

- returns: String?
*/
private func nameForCurrentQueue() -> String? {
  if let name = NSOperationQueue.currentQueue()?.name { return name }
  else { return NSThread.currentThread().name }
}

public protocol Loggable {
  static var defaultLogContext: LogManager.LogContext { get }
  static var defaultLogLevel: LogManager.LogLevel { get }
  var logContext: LogManager.LogContext { get }
  var logLevel: LogManager.LogLevel { get }
  var logTag: LogManager.LogMessage.Tag? { get }
}

public extension Loggable {

  static var defaultLogContext: LogManager.LogContext {
    get { return LogManager.logContextForType(self.dynamicType.self) }
    set { LogManager.setLogContext(newValue, forType: self.dynamicType.self) }
  }

  static var defaultLogLevel: LogManager.LogLevel {
    get { return LogManager.logLevelForType(self) }
    set { LogManager.setLogLevel(newValue, forType: self) }
  }

  var logLevel: LogManager.LogLevel { return self.dynamicType.defaultLogLevel }

  var logContext: LogManager.LogContext { return self.dynamicType.defaultLogContext }
  var logTag: LogManager.LogMessage.Tag? { return LogManager.LogMessage.Tag(className: "\(self.dynamicType)", queueName: nameForCurrentQueue()) }

  /**
  log:asynchronous:flag:function:line:file:tag:

  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter flag: LogManager.LogFlag
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func log(message: String,
     asynchronous: Bool = true,
             flag: LogManager.LogFlag,
         function: String = __FUNCTION__,
             line: UInt = __LINE__,
             file: String = __FILE__)
  {
    LogManager.logMessage(message,
             asynchronous: asynchronous,
                     flag: flag,
                 function: function,
                     line: line,
                     file: file,
                  context: defaultLogContext,
                      tag: LogManager.LogMessage.Tag(objectName: "\(self)", className: "\(self)", queueName: nameForCurrentQueue()))
  }

  /**
  logError:asynchronous:function:line:file:

  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func logError(@autoclosure message: () -> String,
          asynchronous: Bool = true,
              function: String = __FUNCTION__,
                  line: UInt = __LINE__,
                  file: String = __FILE__)
  {
    guard defaultLogLevel ∋ LogManager.LogFlag.Error else { return }
    log(message(), asynchronous: asynchronous, flag: .Error, function: function, line: line, file: file)
  }

  /**
  logError:message:asynchronous:function:line:file:

  - parameter error: ErrorType
  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func logError(error: ErrorType,
               message: String? = nil,
          asynchronous: Bool = true,
              function: String = __FUNCTION__,
                  line: UInt = __LINE__,
                  file: String = __FILE__)
  {
    guard defaultLogLevel ∋ LogManager.LogFlag.Error else { return }
    var errorDescription = "\(error)"
    if let e = error as? WrappedErrorType, u = e.underlyingError {
      errorDescription += "underlying error: \(u)"
    }

    var logMessage = "-Error- "
    if let message = message { logMessage += message + "\n" }
    logMessage += errorDescription

    logError(logMessage, asynchronous: asynchronous, function: function, line: line, file: file)
  }

  /**
   logError:asynchronous:

   - parameter e: ExtendedErrorType
   - parameter asynchronous: Bool = true
   */
  static func logError(error: ExtendedErrorType, asynchronous: Bool = true) {
    guard defaultLogLevel ∋ LogManager.LogFlag.Error else { return }
    logError(error,
     message: error.reason,
asynchronous: asynchronous,
    function: error.function,
        line: error.line,
        file: error.file)
  }


  /**
  logWarning:asynchronous:function:line:file:

  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func logWarning(@autoclosure message: () -> String,
   asynchronous: Bool = true,
       function: String = __FUNCTION__,
           line: UInt = __LINE__,
           file: String = __FILE__)
  {
    guard defaultLogLevel ∋ LogManager.LogFlag.Warning else { return }
    log(message(), asynchronous: asynchronous, flag: .Warning, function: function, line: line, file: file)
  }

  /**
  logDebug:asynchronous:function:line:file:

  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func logDebug(@autoclosure message: () -> String,
   asynchronous: Bool = true,
       function: String = __FUNCTION__,
           line: UInt = __LINE__,
           file: String = __FILE__)
  {
    guard defaultLogLevel ∋ LogManager.LogFlag.Debug else { return }
    log(message(), asynchronous: asynchronous, flag: .Debug, function: function, line: line, file: file)
  }

  /**
  logInfo:asynchronous:function:line:file:

  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func logInfo(@autoclosure message: () -> String,
  asynchronous: Bool = true,
      function: String = __FUNCTION__,
          line: UInt = __LINE__,
          file: String = __FILE__)
  {
    guard defaultLogLevel ∋ LogManager.LogFlag.Info else { return }
    log(message(), asynchronous: asynchronous, flag: .Info, function: function, line: line, file: file)
  }

  /**
  logVerbose:asynchronous:function:line:file:

  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func logVerbose(@autoclosure message: () -> String,
     asynchronous: Bool = true,
         function: String = __FUNCTION__,
             line: UInt = __LINE__,
             file: String = __FILE__)
  {
    guard defaultLogLevel ∋ LogManager.LogFlag.Verbose else { return }
    log(message(), asynchronous: asynchronous, flag: .Verbose, function: function, line: line, file: file)
  }

  
  /**
  log:asynchronous:flag:function:line:file:

  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter flag: LogManager.LogFlag
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func log(message: String,
           asynchronous: Bool = true,
           flag: LogManager.LogFlag,
           function: String = __FUNCTION__,
           line: UInt = __LINE__,
           file: String = __FILE__)

  {
    LogManager.logMessage(message,
             asynchronous: asynchronous,
                     flag: flag,
                 function: function,
                     line: line,
                     file: file,
                  context: logContext,
                      tag: logTag)
  }

  /**
  logError:asynchronous:function:line:file:

  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func logError(@autoclosure message: () -> String,
   asynchronous: Bool = true,
       function: String = __FUNCTION__,
           line: UInt = __LINE__,
           file: String = __FILE__)
  {
    guard logLevel ∋ LogManager.LogFlag.Error else { return }
    log(message(), asynchronous: asynchronous, flag: .Error, function: function, line: line, file: file)
  }

  /**
  logError:message:asynchronous:function:line:file:

  - parameter error: ErrorType
  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func logError(error: ErrorType,
               message: String? = nil,
          asynchronous: Bool = true,
              function: String = __FUNCTION__,
                  line: UInt = __LINE__,
                  file: String = __FILE__)
  {
    guard logLevel ∋ LogManager.LogFlag.Error else { return }
    var errorDescription = "\(error)"
    if let e = error as? WrappedErrorType, u = e.underlyingError {
      errorDescription += "underlying error: \(u)"
    }

    var logMessage = "-Error- "
    if let message = message { logMessage += message + "\n" }
    logMessage += errorDescription

    logError(logMessage, asynchronous: asynchronous, function: function, line: line, file: file)
  }

  /**
   logError:asynchronous:

   - parameter e: ExtendedErrorType
   - parameter asynchronous: Bool = true
   */
  func logError(error: ExtendedErrorType, asynchronous: Bool = true) {
    guard logLevel ∋ LogManager.LogFlag.Error else { return }
    logError(error,
     message: error.reason,
asynchronous: asynchronous,
    function: error.function,
        line: error.line,
        file: error.file)
  }


  /**
  logWarning:asynchronous:function:line:file:

  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func logWarning(@autoclosure message: () -> String,
   asynchronous: Bool = true,
       function: String = __FUNCTION__,
           line: UInt = __LINE__,
           file: String = __FILE__)
  {
    guard logLevel ∋ LogManager.LogFlag.Warning else { return }
    log(message(), asynchronous: asynchronous, flag: .Warning, function: function, line: line, file: file)
  }

  /**
  logDebug:asynchronous:function:line:file:

  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func logDebug(@autoclosure message: () -> String,
   asynchronous: Bool = true,
       function: String = __FUNCTION__,
           line: UInt = __LINE__,
           file: String = __FILE__)
  {
    guard logLevel ∋ LogManager.LogFlag.Debug else { return }
    log(message(), asynchronous: asynchronous, flag: .Debug, function: function, line: line, file: file)
  }

  /**
  logInfo:asynchronous:function:line:file:

  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func logInfo(@autoclosure message: () -> String,
  asynchronous: Bool = true,
      function: String = __FUNCTION__,
          line: UInt = __LINE__,
          file: String = __FILE__)
  {
    guard logLevel ∋ LogManager.LogFlag.Info else { return }
    log(message(), asynchronous: asynchronous, flag: .Info, function: function, line: line, file: file)
  }

  /**
  logVerbose:asynchronous:function:line:file:

  - parameter message: String
  - parameter asynchronous: Bool = true
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func logVerbose(@autoclosure message: () -> String,
     asynchronous: Bool = true,
         function: String = __FUNCTION__,
             line: UInt = __LINE__,
             file: String = __FILE__)
  {
    guard logLevel ∋ LogManager.LogFlag.Verbose else { return }
    log(message(), asynchronous: asynchronous, flag: .Verbose, function: function, line: line, file: file)
  }

  /**
  logSyncError:function:line:file:

  - parameter message: String
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func logSyncError(@autoclosure message: () -> String,
              function: String = __FUNCTION__,
                  line: UInt = __LINE__,
                  file: String = __FILE__)
  {
    guard defaultLogLevel ∋ LogManager.LogFlag.Error else { return }
    log(message(), asynchronous: false, flag: .Error, function: function, line: line, file: file)
  }

  /**
  logError:messageSync:function:line:file:

  - parameter error: ErrorType
  - parameter message: String
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func logSyncError(error: ErrorType,
               message: String? = nil,
              function: String = __FUNCTION__,
                  line: UInt = __LINE__,
                  file: String = __FILE__)
  {
    guard defaultLogLevel ∋ LogManager.LogFlag.Error else { return }
    var errorDescription = "\(error)"
    if let e = error as? WrappedErrorType, u = e.underlyingError {
      errorDescription += "underlying error: \(u)"
    }

    var logMessage = "-Error- "
    if let message = message { logMessage += message + "\n" }
    logMessage += errorDescription

    logError(logMessage, asynchronous: false, function: function, line: line, file: file)
  }

  /**
   logError:asynchronous:

   - parameter e: ExtendedErrorType
   */
  static func logSyncError(error: ExtendedErrorType) {
    guard defaultLogLevel ∋ LogManager.LogFlag.Error else { return }
    logError(error,
     message: error.reason,
asynchronous: false,
    function: error.function,
        line: error.line,
        file: error.file)
  }


  /**
  logSyncWarning:function:line:file:

  - parameter message: String
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func logSyncWarning(@autoclosure message: () -> String,
       function: String = __FUNCTION__,
           line: UInt = __LINE__,
           file: String = __FILE__)
  {
    guard defaultLogLevel ∋ LogManager.LogFlag.Warning else { return }
    log(message(), asynchronous: false, flag: .Warning, function: function, line: line, file: file)
  }

  /**
  logSyncDebug:function:line:file:

  - parameter message: String
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func logSyncDebug(@autoclosure message: () -> String,
       function: String = __FUNCTION__,
           line: UInt = __LINE__,
           file: String = __FILE__)
  {
    guard defaultLogLevel ∋ LogManager.LogFlag.Debug else { return }
    log(message(), asynchronous: false, flag: .Debug, function: function, line: line, file: file)
  }

  /**
  logSyncInfo:function:line:file:

  - parameter message: String
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func logSyncInfo(@autoclosure message: () -> String,
      function: String = __FUNCTION__,
          line: UInt = __LINE__,
          file: String = __FILE__)
  {
    guard defaultLogLevel ∋ LogManager.LogFlag.Info else { return }
    log(message(), asynchronous: false, flag: .Info, function: function, line: line, file: file)
  }

  /**
  logSyncVerbose:function:line:file:

  - parameter message: String
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  static func logSyncVerbose(@autoclosure message: () -> String,
         function: String = __FUNCTION__,
             line: UInt = __LINE__,
             file: String = __FILE__)
  {
    guard defaultLogLevel ∋ LogManager.LogFlag.Verbose else { return }
    log(message(), asynchronous: false, flag: .Verbose, function: function, line: line, file: file)
  }

  
  /**
  logSyncError:function:line:file:

  - parameter message: String
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func logSyncError(@autoclosure message: () -> String,
       function: String = __FUNCTION__,
           line: UInt = __LINE__,
           file: String = __FILE__)
  {
    guard logLevel ∋ LogManager.LogFlag.Error else { return }
    log(message(), asynchronous: false, flag: .Error, function: function, line: line, file: file)
  }

  /**
  logSyncError:messageSync:function:line:file:

  - parameter error: ErrorType
  - parameter message: String
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func logSyncError(error: ErrorType,
               message: String? = nil,
              function: String = __FUNCTION__,
                  line: UInt = __LINE__,
                  file: String = __FILE__)
  {
    guard logLevel ∋ LogManager.LogFlag.Error else { return }
    var errorDescription = "\(error)"
    if let e = error as? WrappedErrorType, u = e.underlyingError {
      errorDescription += "underlying error: \(u)"
    }

    var logMessage = "-Error- "
    if let message = message { logMessage += message + "\n" }
    logMessage += errorDescription

    logError(logMessage, asynchronous: false, function: function, line: line, file: file)
  }

  /**
   logSyncError:

   - parameter e: ExtendedErrorType
   */
  func logSyncError(error: ExtendedErrorType) {
    guard logLevel ∋ LogManager.LogFlag.Error else { return }
    logError(error,
     message: error.reason,
asynchronous: false,
    function: error.function,
        line: error.line,
        file: error.file)
  }


  /**
  logSyncWarning:function:line:file:

  - parameter message: String
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func logSyncWarning(@autoclosure message: () -> String,
       function: String = __FUNCTION__,
           line: UInt = __LINE__,
           file: String = __FILE__)
  {
    guard logLevel ∋ LogManager.LogFlag.Warning else { return }
    log(message(), asynchronous: false, flag: .Warning, function: function, line: line, file: file)
  }

  /**
  logSyncDebug:function:line:file:

  - parameter message: String
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func logSyncDebug(@autoclosure message: () -> String,
       function: String = __FUNCTION__,
           line: UInt = __LINE__,
           file: String = __FILE__)
  {
    guard logLevel ∋ LogManager.LogFlag.Debug else { return }
    log(message(), asynchronous: false, flag: .Debug, function: function, line: line, file: file)
  }

  /**
  logSyncInfo:function:line:file:

  - parameter message: String
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func logSyncInfo(@autoclosure message: () -> String,
      function: String = __FUNCTION__,
          line: UInt = __LINE__,
          file: String = __FILE__)
  {
    guard logLevel ∋ LogManager.LogFlag.Info else { return }
    log(message(), asynchronous: false, flag: .Info, function: function, line: line, file: file)
  }

  /**
  logSyncVerbose:function:line:file:

  - parameter message: String
  - parameter function: String = __FUNCTION__
  - parameter line: UInt = __LINE__
  - parameter file: String = __FILE__
  */
  func logSyncVerbose(@autoclosure message: () -> String,
         function: String = __FUNCTION__,
             line: UInt = __LINE__,
             file: String = __FILE__)
  {
    guard logLevel ∋ LogManager.LogFlag.Verbose else { return }
    log(message(), asynchronous: false, flag: .Verbose, function: function, line: line, file: file)
  }

}

public extension Loggable where Self:Named {
  var logTag: LogManager.LogMessage.Tag? {
    return LogManager.LogMessage.Tag(objectName: name, className: "\(self.dynamicType)", queueName: nameForCurrentQueue())
  }
}

public extension Loggable where Self:Nameable {
  var logTag: LogManager.LogMessage.Tag? {
    return LogManager.LogMessage.Tag(objectName: name, className: "\(self.dynamicType)", queueName: nameForCurrentQueue())
  }
}
