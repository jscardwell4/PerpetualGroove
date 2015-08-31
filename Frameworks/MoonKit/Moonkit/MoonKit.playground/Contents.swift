//: Playground - noun: a place where people can play
import Foundation
import MoonKit

struct State: OptionSetType, CustomStringConvertible {
  let rawValue: Int
  static let Default           = State(rawValue: 0b0000_0000)
  static let PopoverActive     = State(rawValue: 0b0000_0001)
  static let PlayerPlaying     = State(rawValue: 0b0000_0010)
  static let PlayerFieldActive = State(rawValue: 0b0000_0100)
  static let MIDINodeAdded     = State(rawValue: 0b0000_1000)
  static let TrackAdded        = State(rawValue: 0b0001_0000)

  var description: String { return String(binaryBytes: rawValue) }
}

var state: State = [.PopoverActive]

state ∪= .TrackAdded
state ∪= .MIDINodeAdded
state ⊻= .PopoverActive
state ⊻= .PopoverActive
