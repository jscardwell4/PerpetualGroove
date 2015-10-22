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
  public var prompt: String = ""

  public var options: Options = []

  public struct Options: OptionSetType, CustomStringConvertible {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let IncludeLogLevel         = Options(rawValue: 0b0000_0000_0000_0001)
    public static let IncludeContext          = Options(rawValue: 0b0000_0000_0000_0010)
    public static let IncludeTimeStamp        = Options(rawValue: 0b0000_0000_0000_0100)
    public static let AddReturnAfterPrefix    = Options(rawValue: 0b0000_0000_0000_1000)
    public static let AddReturnAfterObject    = Options(rawValue: 0b0000_0000_0001_0000)
    public static let AddReturnAfterMessage   = Options(rawValue: 0b0000_0000_0010_0000)
    public static let AddReturnAfterSEL       = Options(rawValue: 0b0000_0000_0100_0000)
    public static let CollapseTrailingReturns = Options(rawValue: 0b0000_0000_1000_0000)
    public static let IndentMessageBody       = Options(rawValue: 0b0000_0001_0000_0000)
    public static let IncludeSEL              = Options(rawValue: 0b0000_0010_0000_0000)
    public static let UseFileInsteadOfSEL     = Options(rawValue: 0b0000_0100_0000_0000)
    public static let IncludeObjectName       = Options(rawValue: 0b0000_1000_0000_0000)
    public static let IncludePrompt           = Options(rawValue: 0b0001_0000_0000_0000)
    public static let EnableColor             = Options(rawValue: 0b0010_0000_0000_0000)

    public static let taggingOptions: Options = [
      .IncludeContext, 
      .IncludeTimeStamp, 
      .IncludeSEL, 
      .AddReturnAfterSEL, 
      .AddReturnAfterMessage
    ]

    public var description: String {
      var result = "LogFormatter.Options { "
      var flagStrings: [String] = []
      if self ∋ .IncludeLogLevel         { flagStrings.append("IncludeLogLevel")         }
      if self ∋ .IncludeContext          { flagStrings.append("IncludeContext")          }
      if self ∋ .IncludeTimeStamp        { flagStrings.append("IncludeTimeStamp")        }
      if self ∋ .AddReturnAfterPrefix    { flagStrings.append("AddReturnAfterPrefix")    }
      if self ∋ .AddReturnAfterObject    { flagStrings.append("AddReturnAfterObject")    }
      if self ∋ .AddReturnAfterMessage   { flagStrings.append("AddReturnAfterMessage")   }
      if self ∋ .AddReturnAfterSEL       { flagStrings.append("AddReturnAfterSEL")       }
      if self ∋ .CollapseTrailingReturns { flagStrings.append("CollapseTrailingReturns") }
      if self ∋ .IndentMessageBody       { flagStrings.append("IndentMessageBody")       }
      if self ∋ .IncludeSEL              { flagStrings.append("IncludeSEL")              }
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
    guard context != .Ignored && (context == .Default || LogContext(rawValue: logMessage.context) ∋ context) else {
      return nil
    }
    return formattedLogMessageForMessage(logMessage)
  }

  public enum Key: String, KeyType { case ClassName, ObjectName, Object, Context }

  /**
  formattedLogMessageForMessage:

  - parameter logMessage: DDLogMessage

  - returns: String
  */
  public func formattedLogMessageForMessage(logMessage: DDLogMessage) -> String {
    var result = ""

    let useColor = ColorLog.colorEnabled && options ∋ .EnableColor

    if options ∋ .IncludePrompt { result += prompt }

    let objectName: String?, className: String?, contextName: String?

    if let dict = logMessage.tag as? [String:AnyObject] {
      let object  = dict[Key.Object.key]
      objectName  = (dict[Key.ObjectName.key] as? String) ?? object?.shortDescription
      contextName = dict[Key.Context.key] as? String
      className   = (dict[Key.ClassName.key] as? String) ?? (object != nil ? "\(object!.dynamicType)" : nil)
    } else { 
      objectName  = nil
      className   = nil
      contextName = nil 
    }

    if options ∋ .IncludeContext, let contextName = contextName { result += "(\(contextName))" }

    if options ∋ .IncludeLogLevel {
      switch logMessage.flag {
        case LogFlag.Error:   result += "[E"
        case LogFlag.Warning: result += "[W"
        case LogFlag.Info:    result += "[I"
        case LogFlag.Debug:   result += "[D"
        case LogFlag.Verbose: result += "[V"
        default:              result += "[?"
      } 
    }

    if options ∋ .IncludeTimeStamp {
      let dateFormatter = NSDateFormatter()
      dateFormatter.dateFormat = "M/d/yy H:mm:ss.SSS"
      let stamp = dateFormatter.stringFromDate(logMessage.timestamp)
      result += (useColor ? ColorLog.wrapColor(stamp, 125, 125, 125) : stamp)
    }

    if options ∋ .IncludeLogLevel { result += "]" }

    if options ∋ .AddReturnAfterPrefix && !result.isEmpty { result += "\n" } else { result += " " }
 
    if options ∋ .IncludeSEL {
      if let lastCharacter = result.characters.last
        where NSCharacterSet.whitespaceAndNewlineCharacterSet() ∌ lastCharacter { result += " " }

      let selString: String
      if options ∋ .UseFileInsteadOfSEL {
        let fileName = (logMessage.file as NSString).lastPathComponent
        let functionName = logMessage.function
        selString = "«\(fileName)» \(functionName)"
      } else if let className = className {
        selString = "[\(className) \(logMessage.function)]"
      } else {
        selString = "[\(logMessage.function)]"
      }
      result += (useColor ? ColorLog.wrapColor(selString, 171, 101, 38) : selString)
      if options ∋ .AddReturnAfterSEL { result += "\n" } else { result += " "}
    }

    if let objectName = objectName where options ∋ .IncludeObjectName {
      if let lastCharacter = result.characters.last where NSCharacterSet.whitespaceAndNewlineCharacterSet() ∌ lastCharacter {
        result += " "
      }
      result += "\u{00AB}\(objectName)\u{00BB}"
      if options ∋ .AddReturnAfterObject { result += " \n" } else { result += " " }
    }

    if let message = logMessage.message where !message.isEmpty {
      if options ∋ .IndentMessageBody { result = message.indentedBy(4) } else { result += message }
      if options ∋ .AddReturnAfterMessage { result += "\n\n" }
      if options ∋ .CollapseTrailingReturns { result.subInPlace(~/"[\\n]+$", "") }
    }
    return result
  }

}
