//
//  Logging.swift
//  MSKit
//
//  Created by Jason Cardwell on 9/18/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import Lumberjack

public struct ColorLog {
  public static let ESCAPE = "\u{001b}["

  public static let RESET_FG = ESCAPE + "fg;" // Clear any foreground color
  public static let RESET_BG = ESCAPE + "bg;" // Clear any background color
  public static let RESET = ESCAPE + ";"   // Clear any foreground or background color

  public static func red<T>(object:T) {
    print("\(ESCAPE)fg255,0,0;\(object)\(RESET)")
  }

  public static func green<T>(object:T) {
    print("\(ESCAPE)fg0,255,0;\(object)\(RESET)")
  }

  public static func blue<T>(object:T) {
    print("\(ESCAPE)fg0,0,255;\(object)\(RESET)")
  }

  public static func yellow<T>(object:T) {
    print("\(ESCAPE)fg255,255,0;\(object)\(RESET)")
  }

  public static func purple<T>(object:T) {
    print("\(ESCAPE)fg255,0,255;\(object)\(RESET)")
  }

  public static func cyan<T>(object:T) {
    print("\(ESCAPE)fg0,255,255;\(object)\(RESET)")
  }
  public static func wrapRed<T>(object:T) -> String {
    return "\(ESCAPE)fg255,0,0;\(object)\(RESET)"
  }

  public static func wrapGreen<T>(object:T) -> String {
    return "\(ESCAPE)fg0,255,0;\(object)\(RESET)"
  }

  public static func wrapBlue<T>(object:T) -> String {
    return "\(ESCAPE)fg0,0,255;\(object)\(RESET)"
  }

  public static func wrapYellow<T>(object:T) -> String {
    return "\(ESCAPE)fg255,255,0;\(object)\(RESET)"
  }

  public static func wrapPurple<T>(object:T) -> String {
    return "\(ESCAPE)fg255,0,255;\(object)\(RESET)"
  }

  public static func wrapCyan<T>(object:T) -> String {
    return "\(ESCAPE)fg0,255,255;\(object)\(RESET)"
  }

  public static func wrapColor<T>(object:T, _ r: UInt8, _ g: UInt8, _ b: UInt8) -> String {
    return "\(ESCAPE)fg\(r),\(g),\(b);\(object)\(RESET)"
  }
}

public class LogManager {

  public struct LogFlag: OptionSetType {
    public private(set) var rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public init(nilLiteral: ()) { rawValue = 0 }
    public static var allZeros: LogFlag { return LogFlag.None }
    public static var None:     LogFlag = LogFlag(rawValue: 0b00000)
    public static var Error:    LogFlag = LogFlag(rawValue: 0b00001)
    public static var Warn:     LogFlag = LogFlag(rawValue: 0b00010)
    public static var Info:     LogFlag = LogFlag(rawValue: 0b00100)
    public static var Debug:    LogFlag = LogFlag(rawValue: 0b01000)
    public static var Verbose:  LogFlag = LogFlag(rawValue: 0b10000)
  }

  public struct LogLevel: OptionSetType {
    public private(set) var rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public init(flags: LogFlag) { rawValue = flags.rawValue }
    public init(nilLiteral: ()) { rawValue = 0 }
    public static var allZeros: LogLevel { return LogLevel.Off }
    public static var Off:      LogLevel = LogLevel(flags: LogFlag.None)
    public static var Error:    LogLevel = LogLevel(flags: LogFlag.Error)
    public static var Warn:     LogLevel = LogLevel.Error.union(LogLevel(flags: LogFlag.Warn))
    public static var Info:     LogLevel = LogLevel.Warn.union(LogLevel(flags: LogFlag.Info))
    public static var Debug:    LogLevel = LogLevel.Info.union(LogLevel(flags: LogFlag.Debug))
    public static var Verbose:  LogLevel = LogLevel.Debug.union(LogLevel(flags: LogFlag.Verbose))
    public static var All:      LogLevel = [.Error, .Warn, .Info, .Debug, .Verbose]
  }



  public static var logLevel: LogLevel = .Debug

  static var registeredLogLevels: [String:LogLevel] = [:]

  /**
  logLevelForFile:

  - parameter file: String

  - returns: LogLevel
  */
  public class func logLevelForFile(file: String) -> LogManager.LogLevel {
    return registeredLogLevels[file] ?? logLevel
  }

  /**
  setLogLevel:forFile:

  - parameter level: LogManager.LogLevel
  - parameter file: String = __FILE__
  */
  public class func setLogLevel(level: LogManager.LogLevel, forFile file: String = __FILE__) {
    registeredLogLevels[file] = level
  }

  public class func setDefaultLogLevel(level: LogManager.LogLevel) {
    logLevel = level
  }

  public static func addConsoleLoggers() {
    addTTYLogger()
    addASLLogger()
  }

  public static func addTTYLogger() {
    MSLog.enableColor()
    MSLog.addTaggingTTYLogger()
    (DDTTYLogger.sharedInstance().logFormatter as! MSLogFormatter).useFileInsteadOfSEL = true
  }

  public static func addASLLogger() {
    MSLog.enableColor()
    MSLog.addTaggingASLLogger()
    (DDASLLogger.sharedInstance().logFormatter as! MSLogFormatter).useFileInsteadOfSEL = true
  }

}

/**
MSLogMessage:flag:function:line:file:className:context:

- parameter message: String
- parameter flag: LogManager.LogFlag
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
- parameter className: String? = nil
- parameter context: Int = Int(LOG_CONTEXT_CONSOLE)
*/
public func MSLogMessage(message: String,
            asynchronous: Bool,
                    flag: LogManager.LogFlag,
                function: String = __FUNCTION__,
                    line: UInt = __LINE__,
                    file: String = __FILE__,
                 context: Int = Int(LOG_CONTEXT_CONSOLE))
{

  SwiftLogMacro(
    asynchronous,
    level: DDLogLevel(rawValue: LogManager.logLevelForFile(file).rawValue)!,
    flag: DDLogFlag(rawValue: flag.rawValue),
    context: Int(context),
    file: file,
    function: function,
    line: line,
    tag: nil,
    string: message
  )

  #if TARGET_INTERFACE_BUILDER
    logIB(message, function: function, line: line, file: file, flag: flag)
  #endif

}


/**
logDebug:function:line:file:

- parameter message: String
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logDebug(message: String, function: String = __FUNCTION__, line: UInt = __LINE__, file: String = __FILE__) {
  MSLogMessage(message, asynchronous: true, flag: .Debug, function: function, file: file, line: line)
}
public func logDebug(function: String = __FUNCTION__, line: UInt = __LINE__, file: String = __FILE__) {
  logDebug("", function: function, line: line, file: file)
}


/**
logError:function:line:file:

- parameter message: String
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logError(message: String, function: String = __FUNCTION__, line: UInt = __LINE__, file: String = __FILE__) {
  MSLogMessage(message, asynchronous: false, flag: .Error, function: function, file: file, line: line)
}

/**
logInfo:function:line:file:

- parameter message: String
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logInfo(message: String, function: String = __FUNCTION__, line: UInt = __LINE__, file: String = __FILE__) {
  MSLogMessage(message, asynchronous: true, flag: .Info, function: function, file: file, line: line)
}

/**
logWarning:function:line:file:

- parameter message: String
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logWarning(message: String, function: String = __FUNCTION__, line: UInt = __LINE__, file: String = __FILE__) {
  MSLogMessage(message, asynchronous: true, flag: .Warn, function: function, file: file, line: line)
}


/**
logVerbose:function:line:file:

- parameter message: String
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logVerbose(message: String, function: String = __FUNCTION__, line: UInt = __LINE__, file: String = __FILE__) {
  MSLogMessage(message, asynchronous: true, flag: .Verbose, function: function, file: file, line: line)
}

/**
logIB:function:line:file:

- parameter message: String
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logIB(message: String, function: String = __FUNCTION__, line: UInt = __LINE__, file: String = __FILE__, flag: LogManager.LogFlag = .Debug) {
  #if TARGET_INTERFACE_BUILDER
    guard LogManager.logLevelForFile(file) ∋ LogManager.LogLevel(flags: flag) else { return }
    backgroundDispatch {
      guard let sourceDirectory = NSProcessInfo.processInfo().environment["IB_PROJECT_SOURCE_DIRECTORIES"] else { return }
      let text = "\(NSDate()) [\(mach_absolute_time())] <\((file as NSString).lastPathComponent):\(line)> \(function)  \(message)"
      let _ = try? text.appendToFile("\(sourceDirectory)/IB.log")
    }
  #endif
}

/**
detailedDescriptionForError:depth:

- parameter error: NSError
- parameter depth: Int = 0

- returns: String
*/
public func detailedDescriptionForError(error: NSError, depth: Int = 0) -> String {

  let depthIndent = "  " * depth

  var message = "\(depthIndent)domain: \(error.domain)\n\(depthIndent)code: \(error.code)\n"
  if let coreDataErrorDescription = coreDataErrorCodeDescriptions[error.code] {
    message += "\(depthIndent)description: \(coreDataErrorDescription)\n"
    if let key: AnyObject = error.userInfo[NSValidationKeyErrorKey] {
      message += "\(depthIndent)key: \(key)\n"
    }
    if let value: AnyObject = error.userInfo[NSValidationValueErrorKey] {
      message += "\(depthIndent)value: \(value)\n"
    }
    if let predicate: AnyObject = error.userInfo[NSValidationPredicateErrorKey] {
      message += "\(depthIndent)predicate: \(predicate)\n"
    }
    if let object: AnyObject = error.userInfo[NSValidationObjectErrorKey] {
      message += "\(depthIndent)object: \(object)\n"
    }
  }

  if let reason = error.localizedFailureReason { message += "\(depthIndent)reason: \(reason)\n" }

  if let recoveryOptions = error.localizedRecoveryOptions {
    let joinString = ",\n" + (" " * 18) + depthIndent
    message += "\(depthIndent)recovery options: \(joinString.join(recoveryOptions))\n"
  }

  if let suggestion = error.localizedRecoverySuggestion { message += "\(depthIndent)suggestion: \(suggestion)\n" }

  // Check for any undelrying errors
  if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
    // Add information gathered from the underlying error
    message += "\(depthIndent)underlyingError:\n\(detailedDescriptionForError(underlyingError, depth: depth + 1))\n"
  } else if let underlyingErrors = error.userInfo[NSUnderlyingErrorKey] as? [NSError] {
      // Add information gathered from each underlying error
      message += "\(depthIndent)underlyingErrors:\n"
      message += ",\n".join(underlyingErrors.map{detailedDescriptionForError($0, depth: depth + 1)}) + "\n"
  } else if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
    // Add information gathered from each underlying error
    message += "\(depthIndent)detailedErrors:\n"
    message += ",\n".join(detailedErrors.map{detailedDescriptionForError($0, depth: depth + 1)})// + "\n"
  }

  return message

}

/**
descriptionForError:

- parameter error: NSError?

- returns: String?
*/
public func descriptionForError(error: NSError?) -> String? {
  if let e = error { return detailedDescriptionForError(e, depth: 0) } else { return nil }
}

/**
logError:message:function:line:

- parameter e: ErrorType
- parameter message: String? = nil
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
*/
public func logError(e: ErrorType,
                     message: String? = nil,
                     function: String = __FUNCTION__,
                     line: UInt = __LINE__,
                     file: String = __FILE__)
{
  var errorDescription = "\(e)"
  if let e = e as? WrappedErrorType, u = e.underlyingError { errorDescription += "underlying error: \(u)" }

  var logMessage = ColorLog.wrapRed("-Error- ")
  if let message = message { logMessage += message + "\n" }
  logMessage += errorDescription

  logError(logMessage, function: function, line: line, file: file)
}

/**
logError:

- parameter e: ExtendedErrorType
*/
public func logError(e: ExtendedErrorType) {
  logError(e, message: e.reason, function: e.function, line: e.line, file: e.file)
}

/**
recursiveDescription<T>:description:subelements:

- parameter base: [T]
- parameter description: (T) -> String
- parameter subelements: (T) -> [T]
*/
public func recursiveDescription<T>(base: [T], level: Int = 0, description: (T) -> String, subelements:(T) -> [T]) -> String {
  var result = ""
  let indent = "\t" * level
  for object in base {
    result += indent + description(object) + "\n"
    for subelement in subelements(object) {
      result += recursiveDescription([subelement], level: level + 1, description: description, subelements: subelements)
    }
  }
  return result
}

let coreDataErrorCodeDescriptions = [
  NSManagedObjectValidationError: "generic validation error",
  NSValidationMultipleErrorsError: "generic message for error containing multiple validation errors",
  NSValidationMissingMandatoryPropertyError: "non-optional property with a nil value",
  NSValidationRelationshipLacksMinimumCountError: "to-many relationship with too few destination objects",
  NSValidationRelationshipExceedsMaximumCountError: "bounded, to-many relationship with too many destination objects",
  NSValidationRelationshipDeniedDeleteError: "some relationship with NSDeleteRuleDeny is non-empty",
  NSValidationNumberTooLargeError: "some numerical value is too large",
  NSValidationNumberTooSmallError: "some numerical value is too small",
  NSValidationDateTooLateError: "some date value is too late",
  NSValidationDateTooSoonError: "some date value is too soon",
  NSValidationInvalidDateError: "some date value fails to match date pattern",
  NSValidationStringTooLongError: "some string value is too long",
  NSValidationStringTooShortError: "some string value is too short",
  NSValidationStringPatternMatchingError  : "some string value fails to match some pattern",
  NSManagedObjectContextLockingError: "can't acquire a lock in a managed object context",
  NSPersistentStoreCoordinatorLockingError: "can't acquire a lock in a persistent store coordinator",
  NSManagedObjectReferentialIntegrityError: "attempt to fire a fault pointing to an object that does not exist (we can see the store, we can't see the object)",
  NSManagedObjectExternalRelationshipError: "an object being saved has a relationship containing an object from another store",
  NSManagedObjectMergeError: "merge policy failed - unable to complete merging",
  NSPersistentStoreInvalidTypeError: "unknown persistent store type/format/version",
  NSPersistentStoreTypeMismatchError: "returned by persistent store coordinator if a store is accessed that does not match the specified type",
  NSPersistentStoreIncompatibleSchemaError: "store returned an error for save operation (database level errors ie missing table, no permissions)",
  NSPersistentStoreSaveError: "unclassified save error - something we depend on returned an error",
  NSPersistentStoreIncompleteSaveError: "one or more of the stores returned an error during save (stores/objects that failed will be in userInfo)",
  NSPersistentStoreSaveConflictsError: "an unresolved merge conflict was encountered during a save.  userInfo has NSPersistentStoreSaveConflictsErrorKey",
  NSCoreDataError: "general Core Data error",
  NSPersistentStoreOperationError: "the persistent store operation failed ",
  NSPersistentStoreOpenError: "an error occurred while attempting to open the persistent store",
  NSPersistentStoreTimeoutError: "failed to connect to the persistent store within the specified timeout (see NSPersistentStoreTimeoutOption)",
  NSPersistentStoreUnsupportedRequestTypeError: "an NSPersistentStore subclass was passed an NSPersistentStoreRequest that it did not understand",
  NSPersistentStoreIncompatibleVersionHashError: "entity version hashes incompatible with data model",
  NSMigrationError: "general migration error",
  NSMigrationCancelledError: "migration failed due to manual cancellation",
  NSMigrationMissingSourceModelError: "migration failed due to missing source data model",
  NSMigrationMissingMappingModelError: "migration failed due to missing mapping model",
  NSMigrationManagerSourceStoreError: "migration failed due to a problem with the source data store",
  NSMigrationManagerDestinationStoreError: "migration failed due to a problem with the destination data store",
  NSEntityMigrationPolicyError: "migration failed during processing of the entity migration policy ",
  NSSQLiteError: "general SQLite error ",
  NSInferredMappingModelError: "inferred mapping model creation error",
  NSExternalRecordImportError: "general error encountered while importing external records"
]
