//
//  LoggingFunctions.swift
//  MSKit
//
//  Created by Jason Cardwell on 9/18/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import Lumberjack

/**
logDebug:asynchronous:function:line:file:

- parameter message: String
- parameter asynchronous: Bool = true
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logDebug(message: String,
        asynchronous: Bool = true,
            function: String = __FUNCTION__,
                line: UInt = __LINE__,
                file: String = __FILE__)
{
  LogManager.logMessage(message, asynchronous: asynchronous, flag: .Debug, function: function, file: file, line: line)
}

/**
logDebug:function:line:file:

- parameter asynchronous: Bool = true
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logDebug(asynchronous: Bool = true, function: String = __FUNCTION__, line: UInt = __LINE__, file: String = __FILE__) {
  logDebug("", asynchronous: asynchronous, function: function, line: line, file: file)
}

/**
logDebug:separator:terminator:asynchronous:function:line:file:

- parameter items: Any...
- parameter separator: String = " "
- parameter terminator: String = "
"
- parameter asynchronous: Bool = true
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logDebug(items: Any...,
                     separator: String = " ",
                     terminator: String = "\n",
                     asynchronous: Bool = true,
                     function: String = __FUNCTION__,
                     line: UInt = __LINE__,
                     file: String = __FILE__)
{
  logDebug(
    String(items: items, separator: separator, terminator: terminator),
    asynchronous: asynchronous,
    function: function,
    line: line,
    file: file
  )
}

/**
logError:asynchronous:function:line:file:

- parameter message: String
- parameter asynchronous: Bool = true
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logError(message: String,
        asynchronous: Bool = true,
            function: String = __FUNCTION__,
                line: UInt = __LINE__,
                file: String = __FILE__)
{
  LogManager.logMessage(message, asynchronous: asynchronous, flag: .Error, function: function, file: file, line: line)
}

/**
logError:separator:terminator:asynchronous:function:line:file:

- parameter items: Any...
- parameter separator: String = " "
- parameter terminator: String = "
"
- parameter asynchronous: Bool = true
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logError(items items: Any...,
                     separator: String = " ",
                     terminator: String = "\n",
                     asynchronous: Bool = true,
                     function: String = __FUNCTION__,
                     line: UInt = __LINE__,
                     file: String = __FILE__)
{
  logError(
    String(items: items, separator: separator, terminator: terminator),
    asynchronous: asynchronous,
    function: function,
    line: line,
    file: file
  )
}

/**
logInfo:asynchronous:function:line:file:

- parameter message: String
- parameter asynchronous: Bool = true
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logInfo(message: String,
       asynchronous: Bool = true,
           function: String = __FUNCTION__,
               line: UInt = __LINE__,
               file: String = __FILE__)
{
  LogManager.logMessage(message, asynchronous: asynchronous, flag: .Info, function: function, file: file, line: line)
}

/**
logInfo:separator:terminator:asynchronous:function:line:file:

- parameter items: Any...
- parameter separator: String = " "
- parameter terminator: String = "
"
- parameter asynchronous: Bool = true
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logInfo(items: Any...,
          separator: String = " ",
         terminator: String = "\n",
       asynchronous: Bool = true,
           function: String = __FUNCTION__,
               line: UInt = __LINE__,
               file: String = __FILE__)
{
  logInfo(
    String(items: items, separator: separator, terminator: terminator),
    asynchronous: asynchronous,
    function: function,
    line: line,
    file: file
  )
}

/**
logWarning:asynchronous:function:line:file:

- parameter message: String
- parameter asynchronous: Bool = true
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logWarning(message: String,
          asynchronous: Bool = true,
              function: String = __FUNCTION__,
                  line: UInt = __LINE__,
                  file: String = __FILE__)
{
  LogManager.logMessage(message, asynchronous: asynchronous, flag: .Warning, function: function, file: file, line: line)
}

/**
logWarning:separator:terminator:asynchronous:function:line:file:

- parameter items: Any...
- parameter separator: String = " "
- parameter terminator: String = "
"
- parameter asynchronous: Bool = true
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logWarning(items: Any...,
             separator: String = " ",
            terminator: String = "\n",
          asynchronous: Bool = true,
              function: String = __FUNCTION__,
                  line: UInt = __LINE__,
                  file: String = __FILE__)
{
  logWarning(
    String(items: items, separator: separator, terminator: terminator),
    asynchronous: asynchronous,
    function: function,
    line: line,
    file: file
  )
}

/**
logVerbose:asynchronous:function:line:file:

- parameter message: String
- parameter asynchronous: Bool = true
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logVerbose(message: String,
          asynchronous: Bool = true,
              function: String = __FUNCTION__,
                  line: UInt = __LINE__,
                  file: String = __FILE__)
{
  LogManager.logMessage(message, asynchronous: asynchronous, flag: .Verbose, function: function, file: file, line: line)
}

/**
logVerbose:separator:terminator:asynchronous:function:line:file:

- parameter items: Any...
- parameter separator: String = " "
- parameter terminator: String = "
"
- parameter asynchronous: Bool = true
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logVerbose(items: Any...,
             separator: String = " ",
            terminator: String = "\n",
          asynchronous: Bool = true,
              function: String = __FUNCTION__,
                  line: UInt = __LINE__,
                  file: String = __FILE__)
{
  logVerbose(
    String(items: items, separator: separator, terminator: terminator),
    asynchronous: asynchronous,
    function: function,
    line: line,
    file: file
  )
}

/**
logIB:function:line:file:

- parameter message: String
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logIB(message: String,
         function: String = __FUNCTION__,
             line: UInt = __LINE__,
             file: String = __FILE__,
             flag: LogManager.LogFlag = .Debug)
{
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
logError:message:asynchronous:function:line:file:

- parameter e: ErrorType
- parameter message: String? = nil
- parameter asynchronous: Bool = true
- parameter function: String = __FUNCTION__
- parameter line: UInt = __LINE__
- parameter file: String = __FILE__
*/
public func logError(e: ErrorType,
                     message: String? = nil,
                     asynchronous: Bool = true,
                     function: String = __FUNCTION__,
                     line: UInt = __LINE__,
                     file: String = __FILE__)
{
  var errorDescription = "\(e)"
  if let e = e as? WrappedErrorType, u = e.underlyingError { errorDescription += "underlying error: \(u)" }

  var logMessage = ColorLog.wrapRed("-Error- ")
  if let message = message { logMessage += message + "\n" }
  logMessage += errorDescription

  logError(logMessage, asynchronous: asynchronous, function: function, line: line, file: file)
}

/**
logError:asynchronous:

- parameter e: ExtendedErrorType
- parameter asynchronous: Bool = true
*/
public func logError(e: ExtendedErrorType, asynchronous: Bool = true) {
  logError(e, message: e.reason, asynchronous: asynchronous, function: e.function, line: e.line, file: e.file)
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
