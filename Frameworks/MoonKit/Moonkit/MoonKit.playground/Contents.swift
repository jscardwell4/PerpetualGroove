//
//  Slider.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/2/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//
import Foundation
import UIKit
import MoonKit

struct State: OptionSetType {
  let rawValue: Int
  static let Default           = State(rawValue: 0b0000_0000)
  static let PopoverActive     = State(rawValue: 0b0000_0001)
  static let PlayerPlaying     = State(rawValue: 0b0000_0010)
  static let PlayerFieldActive = State(rawValue: 0b0000_0100)
  static let MIDINodeAdded     = State(rawValue: 0b0000_1000)
  static let TrackAdded        = State(rawValue: 0b0001_0000)
  static let PlayerRecording   = State(rawValue: 0b0010_0000)
}

var currentState: State = []
var previousState = currentState


currentState ∪= .PopoverActive
currentState ∪= .PlayerPlaying

(previousState ⊻ currentState).rawValue

previousState = currentState

currentState ∪= .MIDINodeAdded

(previousState ⊻ currentState).rawValue
(currentState ⊻ previousState).rawValue
