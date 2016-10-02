//
//  EmaxSoundSet.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import class UIKit.UIImage

struct EmaxSoundSet: SoundFont {

  enum Error: String, Swift.Error { case InvalidURL }

  enum Volume: Int {
    case brassAndWoodwinds  = 1
    case keyboardsAndSynths = 2
    case guitarsAndBasses   = 3
    case worldInstruments   = 4
    case drumsAndPercussion = 5
    case orchestral         = 6
  }

  var url: URL { return Bundle.main.url(forResource: fileName, withExtension: "sf2")! }

  let volume: Volume

  var presets: [SF2File.Preset] { return (try? SF2File.presets(from: url)) ?? [] }

  var displayName: String {
    switch volume {
      case .brassAndWoodwinds:  return "Brass & Woodwinds"
      case .keyboardsAndSynths: return "Keyboards & Synths"
      case .guitarsAndBasses:   return "Guitars & Basses"
      case .worldInstruments:   return "World Instruments"
      case .drumsAndPercussion: return "Drums & Percussion"
      case .orchestral:         return "Orchestral"
    }
  }

  var fileName: String { return "Emax Volume \(volume.rawValue)" }

  var image: UIImage {
    switch volume {
      case .brassAndWoodwinds:  return #imageLiteral(resourceName: "brass")
      case .keyboardsAndSynths: return #imageLiteral(resourceName: "piano_keyboard")
      case .guitarsAndBasses:   return #imageLiteral(resourceName: "guitar_bass")
      case .worldInstruments:   return #imageLiteral(resourceName: "world")
      case .drumsAndPercussion: return #imageLiteral(resourceName: "percussion")
      case .orchestral:         return #imageLiteral(resourceName: "orchestral")
    }
  }

  init(_ volume: Volume) { self.volume = volume }

  init(url: URL) throws {
    guard
      let volumeNumber = (url.path ~=> ~/"Emax Volume ([1-6])")?.1,
      let rawVolume = Int(volumeNumber),
      let volume = Volume(rawValue: rawVolume)
      else { throw Error.InvalidURL }
    self.volume = volume
  }

}
