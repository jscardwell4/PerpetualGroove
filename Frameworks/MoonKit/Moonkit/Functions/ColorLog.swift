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
  public static let RESET    = ESCAPE + ";"   // Clear any foreground or background color
  public static let RED      = ESCAPE + "fg172,40,28;"
  public static let GREEN    = ESCAPE + "fg49,163,67;"
  public static let BLUE     = ESCAPE + "fg39,105,176;"
  public static let YELLOW   = ESCAPE + "fg217,108,0;"
  public static let PURPLE   = ESCAPE + "fg71,47,151;"
  public static let CYAN     = ESCAPE + "fg0,166,178;"
  public static let GRAY     = ESCAPE + "fg125,125,125;"


  public static func red   <T>(object:T) { print("\(RED)\(object)\(RESET)")    }
  public static func green <T>(object:T) { print("\(GREEN)\(object)\(RESET)")  }
  public static func blue  <T>(object:T) { print("\(BLUE)\(object)\(RESET)")   }
  public static func yellow<T>(object:T) { print("\(YELLOW)\(object)\(RESET)") }
  public static func purple<T>(object:T) { print("\(PURPLE)\(object)\(RESET)") }
  public static func cyan  <T>(object:T) { print("\(CYAN)\(object)\(RESET)")   }
  public static func gray  <T>(object:T) { print("\(GRAY)\(object)\(RESET)")   }

  public static func wrapRed<T>(object:T)    -> String { return "\(RED)\(object)\(RESET)"    }
  public static func wrapGreen<T>(object:T)  -> String { return "\(GREEN)\(object)\(RESET)"  }
  public static func wrapBlue<T>(object:T)   -> String { return "\(BLUE)\(object)\(RESET)"   }
  public static func wrapYellow<T>(object:T) -> String { return "\(YELLOW)\(object)\(RESET)" }
  public static func wrapPurple<T>(object:T) -> String { return "\(PURPLE)\(object)\(RESET)" }
  public static func wrapCyan<T>(object:T)   -> String { return "\(CYAN)\(object)\(RESET)"   }
  public static func wrapGray<T>(object:T)   -> String { return "\(GRAY)\(object)\(RESET)"   }

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

