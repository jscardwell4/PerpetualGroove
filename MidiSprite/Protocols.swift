//
//  Protocols.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import typealias AudioToolbox.AudioUnitElement
import typealias AudioToolbox.AudioUnitParameterValue
import typealias AudioToolbox.AudioUnitScope

protocol TrackType: class, CustomStringConvertible {
  var label: String { get }
  var bus: AudioUnitElement { get }
  var color: TrackColor { get }
  var volume: AudioUnitParameterValue { get set }
  var pan: AudioUnitParameterValue { get set }
}

protocol InstrumentTrackType: TrackType {
  var label: String { get set }
  var instrument: Instrument { get }
}

extension TrackType {
  var description: String {
    return "{bus: \(bus); label: \(label); volume: \(volume); pan: \(pan); color: \(color)}"
  }
}