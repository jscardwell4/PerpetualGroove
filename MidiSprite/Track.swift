//
//  Track.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/14/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import typealias AudioToolbox.AudioUnitElement
import typealias AudioToolbox.AudioUnitParameterValue

// MARK: - Enumeration for specifying the color attached to a `TrackType`
enum TrackColor: UInt32, EnumerableType {
  case White      = 0xffffff
  case Portica    = 0xf7ea64
  case MonteCarlo = 0x7ac2a5
  case FlamePea   = 0xda5d3a
  case Crimson    = 0xd6223e
  case HanPurple  = 0x361aee
  case MangoTango = 0xf88242
  case Viking     = 0x6bcbe1
  case Yellow     = 0xfde97e
  case Conifer    = 0x9edc58
  case Apache     = 0xce9f58

  var value: UIColor { return UIColor(RGBHex: rawValue) }

  /// `White` case is left out so that it is harder to assign the color used by `MasterTrack`
  static let allCases: [TrackColor] = [.Portica, .MonteCarlo, .FlamePea, .Crimson, .HanPurple,
                                       .MangoTango, .Viking, .Yellow, .Conifer, .Apache]
}

// MARK: - TrackType to represent the "Master" track

final class MasterTrack: TrackType {
  static let sharedInstance = MasterTrack()

  private init() {
    guard let mixer = AudioManager.mixer else { return }
    do {
      volume = try mixer.masterVolume()
      pan = try mixer.masterPan()
    } catch { logError(error) }
  }
  
  let bus: AudioUnitElement = 0
  let color = TrackColor.White
  let label = "MASTER"
  var volume: AudioUnitParameterValue = 1 {
    didSet {
      volume %= 1
      do { try AudioManager.mixer?.setMasterVolume(volume) }
      catch { logError(error) }
    }
  }
  var pan: AudioUnitParameterValue = 0 {
    didSet {
      pan %= 1
      do { try AudioManager.mixer?.setMasterPan(pan) }
      catch { logError(error) }
    }
  }

}

// MARK: - TrackType for user-created instrument tracks
final class InstrumentTrack: InstrumentTrackType, Equatable {
  let instrument: Instrument
  lazy var label: String = {"bus \(self.bus)"}()
  let bus: AudioUnitElement
  let color: TrackColor

  var volume: AudioUnitParameterValue = 1  {
    didSet {
      volume %= 1
      do { try AudioManager.mixer?.setVolume(volume, onBus: bus) }
      catch { logError(error) }
    }
  }
  var pan: AudioUnitParameterValue = 0 {
    didSet {
      pan %= 1
      do { try AudioManager.mixer?.setPan(pan, onBus: bus) }
      catch { logError(error) }
    }
  }

  /**
  init:bus:

  - parameter i: Instrument
  - parameter b: AudioUnitElement
  */
  init(instrument i: Instrument, bus b: AudioUnitElement) {
    instrument = i
    bus = b
    color = TrackColor.allCases[Int(bus) % 10]
    guard let mixer = AudioManager.mixer else { return }
    do {
      let currentVolume = try mixer.volumeOnBus(bus)
      let currentPan = try mixer.panOnBus(bus)
      volume = currentVolume
      pan = currentPan
    } catch { logError(error) }
  }

}


func ==(lhs: InstrumentTrack, rhs: InstrumentTrack) -> Bool { return lhs.instrument == rhs.instrument && lhs.bus == rhs.bus }