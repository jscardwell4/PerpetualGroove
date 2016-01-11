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
  public var prompt = ">"
  public var afterLocation = " "
  public var afterObjectName = " ::: "
  public var afterMessage = ""

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
    public static let IncludeQueueName        = Options(rawValue: 0b0100_0000_0000)

    public static let taggingOptions: Options = [
      .IncludeContext, 
      .IncludeTimeStamp, 
      .IncludeLocation,
      .IncludeObjectName,
      .IncludeQueueName
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
      if self ∋ .IncludeQueueName        { flagStrings.append("IncludeQueueName")        }
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
//    print("logMessage.context: \(LogContext(rawValue: logMessage.context))  context: \(context)")
    guard context != .Ignored && (context == .Default
       || LogContext(rawValue: logMessage.context) ∋ context) else { return nil }
    return formattedLogMessageForMessage(logMessage)
  }

  public enum Key: String, KeyType { case ClassName, ObjectName, Context, Queue }

  /**
  namesFromMessage:

  - parameter tag: [String

  - returns: (objectName: String?, className: String?, contextName: String?)
  */
  private func namesFromMessage(tag: [String:AnyObject]?) -> (String?, String?, String?, String?) {
    guard let tag = tag else { return (nil, nil, nil, nil) }
    return (
      tag[Key.ObjectName.key] as? String,
      tag[Key.ClassName.key] as? String,
      tag[Key.Context.key] as? String,
      tag[Key.Queue.key] as? String
    )
  }

  /**
  namesFromMessage:

  - parameter tag: LogManager.LogMessage.Tag?

  - returns: (String?, String?, String?)
  */
  private func namesFromMessage(tag: LogManager.LogMessage.Tag?) -> (String?, String?, String?, String?) {
    guard let tag = tag else { return (nil, nil, nil, nil) }
    return (tag.objectName, tag.className, tag.contextName, (tag.queueName == NSOperationQueue.mainQueue().name ? "main" : tag.queueName))
  }

  /**
  namesFromMessage:

  - parameter tag: AnyObject?

  - returns: (String?, String?, String?)
  */
  private func namesFromMessage(tag: AnyObject?) -> (String?, String?, String?, String?) {
    var names: (String?, String?, String?, String?)
    switch tag {
      case let tag as LogManager.LogMessage.Tag: names = namesFromMessage(tag)
      case let tag as [String:AnyObject]:        names = namesFromMessage(tag)
      default:                                   names = (nil, nil, nil, nil)
    }
    guard useColor else { return names }
    if let objectName  = names.0 { names.0 = ColorLog.wrapBlue(objectName)    }
    if let className   = names.1 { names.1 = ColorLog.wrapCyan(className)   }
    if let contextName = names.2 { names.2 = ColorLog.wrapPurple(contextName) }
    if let queueName   = names.3 { names.3 = ColorLog.wrapGreen(queueName)    }
    return names
  }

  /**
   namesFromMessage:

   - parameter message: DDLogMessage

    - returns: (String?, String?, String?, String?)
  */
  private func namesFromMessage(message: DDLogMessage) -> (String?, String?, String?, String?) {
    var names = namesFromMessage(message.tag)
    if names.2 == nil, let contextName = LogManager.logContextNames[LogContext(rawValue: message.context)] {
      names.2 = useColor ? ColorLog.wrapPurple(contextName) : contextName
    }

    return names
  }

  private var useColor: Bool { return ColorLog.colorEnabled && options ∋ .EnableColor }

  /**
  stringFromTimestamp:useColor:

  - parameter timestamp: NSDate
  - parameter useColor: Bool

  - returns: String
  */
  private func stringFromTimestamp(timestamp: NSDate) -> String {
    let stamp = LogFileManager.dateFormatter.stringFromDate(timestamp)
    return (useColor ? ColorLog.wrapGray(stamp) : stamp)
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
      case let (n, f?, c?) where options ∋ .UseFileInsteadOfSEL:  selString = "«\(n):\(message.line) - \(c)» \(f)"
      case let (n, f?, nil):                                      selString = "«\(n):\(message.line)» \(f)"
      default:                                                    selString = ""
    }
    return selString + afterLocation
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

    let (objectName, className, contextName, queueName) = namesFromMessage(msg)

    if options ∋ .IncludePrompt { result += prompt }
    if options ∋ .IncludeContext && contextName != nil { result += "(\(contextName!)) " }
    if options ∋ .IncludeLogLevel { result += "[\(msg.flag)" }
    if options ∋ .IncludeTimeStamp { result += stringFromTimestamp(msg.timestamp) }
    if options ∋ .IncludeLogLevel { result += "] " }
    if options ∋ .IncludeQueueName && queueName != nil { result += " ᛫\(queueName!)᛫ " }
    if options ∋ .IncludeLocation { result += "\(space())\(location(msg, className))" }
    if options ∋ .IncludeObjectName && objectName != nil { result += "\(space())«\(objectName!)»\(afterObjectName)" }
    if let m = msg.message where !m.isEmpty {
      if m.characters ∋ "\n" && result.characters.last != "\n" { result += "\n" }
      result += "\(options ∋ .IndentMessageBody ? m.indentedBy(4) : m)\(afterMessage)"
    }
    if options ∋ .CollapseTrailingReturns { result.subInPlace(~/"[\\n]+$", "") }

    return result
  }

}
