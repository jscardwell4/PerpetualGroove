//: Playground - noun: a place where people can play
import Foundation
import MoonKit
import AudioToolbox
import Swift

enum Yo: String, CustomReflectable {
  case Mama, Papa
  static func customMirror() -> Mirror {
    let mirror = Mirror(self, unlabeledChildren: [Yo.Mama, Yo.Papa])
    return mirror
  }
  func customMirror() -> Mirror {
    let mirror = Mirror(self, unlabeledChildren: [Yo.Mama, Yo.Papa])
    return mirror
  }
}

let m = Mirror(reflecting: Yo.self).children.count
//(m.descendant(0) as? Yo)?.rawValue


