//
//  ColorLog.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/20/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public struct ColorLog {
  public static let ESCAPE = "\u{001b}["

  public static let RESET_FG = ESCAPE + "fg;" // Clear any foreground color
  public static let RESET_BG = ESCAPE + "bg;" // Clear any background color
  public static let RESET = ESCAPE + ";"   // Clear any foreground or background color

  public static func red   <T>(object:T) { print("\(ESCAPE)fg255,0,0;\(object)\(RESET)")   }
  public static func green <T>(object:T) { print("\(ESCAPE)fg0,255,0;\(object)\(RESET)")   }
  public static func blue  <T>(object:T) { print("\(ESCAPE)fg0,0,255;\(object)\(RESET)")   }
  public static func yellow<T>(object:T) { print("\(ESCAPE)fg255,255,0;\(object)\(RESET)") }
  public static func purple<T>(object:T) { print("\(ESCAPE)fg255,0,255;\(object)\(RESET)") }
  public static func cyan  <T>(object:T) { print("\(ESCAPE)fg0,255,255;\(object)\(RESET)") }

  public static func wrapRed<T>(object:T)    -> String { return "\(ESCAPE)fg255,0,0;\(object)\(RESET)"  }
  public static func wrapGreen<T>(object:T)  -> String { return "\(ESCAPE)fg0,255,0;\(object)\(RESET)"  }
  public static func wrapBlue<T>(object:T)   -> String { return "\(ESCAPE)fg0,0,255;\(object)\(RESET)"  }
  public static func wrapYellow<T>(object:T) -> String { return "\(ESCAPE)fg255,255,0;\(object)\(RESET)"}
  public static func wrapPurple<T>(object:T) -> String { return "\(ESCAPE)fg255,0,255;\(object)\(RESET)"}
  public static func wrapCyan<T>(object:T)   -> String { return "\(ESCAPE)fg0,255,255;\(object)\(RESET)"}
  
  public static func wrapColor<T>(object:T, _ r: UInt8, _ g: UInt8, _ b: UInt8) -> String {
    return "\(ESCAPE)fg\(r),\(g),\(b);\(object)\(RESET)"
  }

  private static var enabled = NSProcessInfo.processInfo().environment["XCODE_COLORS"] == "YES"
  public static var colorEnabled: Bool {
    get { return enabled }
    set {
      guard newValue != enabled else { return }
      enabled = newValue
      (newValue ? "YES" : "NO").withCString { setenv("XCODE_COLORS", $0, 0) }
    }
  }
}

