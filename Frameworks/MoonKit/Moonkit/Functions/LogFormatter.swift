//
//  LogFormatter.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/20/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import Lumberjack

public class LogFormatter: NSObject, DDLogFormatter {

  public typealias LogContext = LogManager.LogContext
  public typealias LogLevel = LogManager.LogLevel
  public typealias LogFlag = LogManager.LogFlag

  public var context: LogContext = .Default
  public var prompt = ""
  public var afterPrefix = ""
  public var afterLocation = "\n"
  public var afterObjectName = " "
  public var afterMessage = "\n"

  public var options: Options = []

  public struct Options: OptionSetType, CustomStringConvertible {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let IncludeLogLevel         = Options(rawValue: 0b0000_0000_0001)
    public static let IncludeContext          = Options(rawValue: 0b0000_0000_0010)
    public static let IncludeTimeStamp        = Options(rawValue: 0b0000_0000_0100)
    public static let CollapseTrailingReturns = Options(rawValue: 0b0000_0000_1000)
    public static let IndentMessageBody       = Options(rawValue: 0b0000_0001_0000)
    public static let IncludeLocation         = Options(rawValue: 0b0000_0010_0000)
    public static let UseFileInsteadOfSEL     = Options(rawValue: 0b0000_0100_0000)
    public static let IncludeObjectName       = Options(rawValue: 0b0000_1000_0000)
    public static let IncludePrompt           = Options(rawValue: 0b0001_0000_0000)
    public static let EnableColor             = Options(rawValue: 0b0010_0000_0000)

    public static let taggingOptions: Options = [
      .IncludeContext, 
      .IncludeTimeStamp, 
      .IncludeLocation,
      .IncludeObjectName
    ]

    public var description: String {
      var result = "LogFormatter.Options { "
      var flagStrings: [String] = []
      if self ∋ .IncludeLogLevel         { flagStrings.append("IncludeLogLevel")         }
      if self ∋ .IncludeContext          { flagStrings.append("IncludeContext")          }
      if self ∋ .IncludeTimeStamp        { flagStrings.append("IncludeTimeStamp")        }
      if self ∋ .CollapseTrailingReturns { flagStrings.append("CollapseTrailingReturns") }
      if self ∋ .IndentMessageBody       { flagStrings.append("IndentMessageBody")       }
      if self ∋ .IncludeLocation         { flagStrings.append("IncludeLocation")         }
      if self ∋ .UseFileInsteadOfSEL     { flagStrings.append("UseFileInsteadOfSEL")     }
      if self ∋ .IncludeObjectName       { flagStrings.append("IncludeObjectName")       }
      if self ∋ .IncludePrompt           { flagStrings.append("IncludePrompt")           }
      if self ∋ .EnableColor             { flagStrings.append("EnableColor")             }
      result += ", ".join(flagStrings)
      result += " }"
      return result
    }
  }
  
  /**
  initWithContext:options:

  - parameter context: LogManager.LogContext = 0
  - parameter options: Options = []
  */
  public init(context: LogContext = .Default, options: Options = [], tagging: Bool = false) {
    super.init()
    self.context = context
    self.options = tagging ? Options.taggingOptions ∪ options : options
  }

  /**
  formatLogMessage:

  - parameter logMessage: DDLogMessage

  - returns: String?
  */
  @objc public func formatLogMessage(logMessage: DDLogMessage) -> String? {
    guard context != .Ignored && (context == .Default
       || LogContext(rawValue: logMessage.context) ∋ context) else { return nil }
    return formattedLogMessageForMessage(logMessage)
  }

  public enum Key: String, KeyType { case ClassName, ObjectName, Object, Context }

  /**
  namesFromTag:

  - parameter tag: [String

  - returns: (objectName: String?, className: String?, contextName: String?)
  */
  private func namesFromTag(tag: [String:AnyObject]?) -> (String?, String?, String?) {
    guard let tag = tag else { return (nil, nil, nil) }
    let objectName: String?, className: String?, contextName: String?
    let object  = tag[Key.Object.key]
    objectName  = (tag[Key.ObjectName.key] as? String) ?? object?.shortDescription
    contextName = tag[Key.Context.key] as? String
    className   = (tag[Key.ClassName.key] as? String) ?? (object != nil ? "\(object!.dynamicType)" : nil)
    return (objectName, className, contextName)
  }

  /**
  namesFromTag:

  - parameter tag: LogManager.LogMessage.Tag?

  - returns: (String?, String?, String?)
  */
  private func namesFromTag(tag: LogManager.LogMessage.Tag?) -> (String?, String?, String?) {
    guard let tag = tag else { return (nil, nil, nil) }
    let objectName: String?, className: String?, contextName: String?
    objectName  = tag.objectName
    contextName = tag.contextName
    className   = tag.className
    return (objectName, className, contextName)
  }

  /**
  namesFromTag:

  - parameter tag: AnyObject?

  - returns: (String?, String?, String?)
  */
  private func namesFromTag(tag: AnyObject?) -> (String?, String?, String?) {
    switch tag {
      case let tag as LogManager.LogMessage.Tag: return namesFromTag(tag)
      case let tag as [String:AnyObject]:        return namesFromTag(tag)
      default:                                   return (nil, nil, nil)
    }
  }

  private var useColor: Bool { return ColorLog.colorEnabled && options ∋ .EnableColor }

  /**
  stringFromTimestamp:useColor:

  - parameter timestamp: NSDate
  - parameter useColor: Bool

  - returns: String
  */
  private func stringFromTimestamp(timestamp: NSDate) -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "M/d/yy H:mm:ss.SSS"
    let stamp = dateFormatter.stringFromDate(timestamp)
    return (useColor ? ColorLog.wrapColor(stamp, 125, 125, 125) : stamp)
  }

  /**
  location:className:

  - parameter message: DDLogMessage
  - parameter className: String?

  - returns: String
  */
  private func location(message: DDLogMessage, _ className: String?) -> String {
    let selString: String
    switch ((message.file as NSString).lastPathComponent, message.function, className) {
      case let (_, f?, c?) where options ∌ .UseFileInsteadOfSEL:  selString = "[\(c) \(f)]"
      case let (n, f?, c?) where options ∋ .UseFileInsteadOfSEL:  selString = "«\(n) - \(c)» \(f)"
      case let (n, f?, nil):                                      selString = "«\(n)» \(f)"
      default:                                                    selString = ""
    }
    return (useColor ? ColorLog.wrapColor(selString, 171, 101, 38) : selString) + afterLocation
  }

  /**
  Formats the log message like so:
   
  \<*prompt*>__(__<*context*>__)____[__<*flag*><*timestamp*>__]__ <*after-prefix*> &nbsp;<*location*>
   <*after-location*> __«__<*object*>__»__ <*message*><*after-message*>


  - parameter logMessage: DDLogMessage

  - returns: String
  */
  public func formattedLogMessageForMessage(msg: DDLogMessage) -> String {
    var result = ""

    func space() -> String { return result.characters.last?.isWhitespace == true ? "" : " " }
    func newline(flag: Bool) -> String { return flag && !result.isEmpty ? "\n" : "" }

    let (objectName, className, contextName) = namesFromTag(msg.tag)

    if options ∋ .IncludePrompt { result += prompt }
    if options ∋ .IncludeContext && contextName != nil { result += "(\(contextName!))" }
    if options ∋ .IncludeLogLevel { result += "[\(msg.flag)" }
    if options ∋ .IncludeTimeStamp { result += stringFromTimestamp(msg.timestamp) }
    if options ∋ .IncludeLogLevel { result += "] \(afterPrefix)" }
    if options ∋ .IncludeLocation { result += "\(space())\(location(msg, className))" }
    if options ∋ .IncludeObjectName && objectName != nil { result += "\(space())«\(objectName!)»\(afterObjectName)" }
    if let m = msg.message where !m.isEmpty { result += "\(options ∋ .IndentMessageBody ? m.indentedBy(4) : m)\(afterMessage)" }
    if options ∋ .CollapseTrailingReturns { result.subInPlace(~/"[\\n]+$", "") }

    return result
  }

}
