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

struct EmaxSoundSet: SoundSetType {
  enum Volume: Int {
    case brassAndWoodwinds  = 1
    case keyboardsAndSynths = 2
    case guitarsAndBasses   = 3
    case worldInstruments   = 4
    case drumsAndPercussion = 5
    case orchestral         = 6

    var fileName: String { return "Emax Volume \(rawValue)" }

    var url: URL {
      // ???: Why did we need to us the reference URL?
      return Bundle.main.url(forResource: fileName, withExtension: "sf2")!
    }

    var image: UIImage {
      switch self {
        case .brassAndWoodwinds:  return UIImage(named: "brass")!
        case .keyboardsAndSynths: return UIImage(named: "piano_keyboard")!
        case .guitarsAndBasses:   return UIImage(named: "guitar_bass")!
        case .worldInstruments:   return UIImage(named: "world")!
        case .drumsAndPercussion: return UIImage(named: "percussion")!
        case .orchestral:         return UIImage(named: "orchestral")!
      }
    }

    var displayName: String {
      switch self {
        case .brassAndWoodwinds:  return "Brass & Woodwinds"
        case .keyboardsAndSynths: return "Keyboards & Synths"
        case .guitarsAndBasses:   return "Guitars & Basses"
        case .worldInstruments:   return "World Instruments"
        case .drumsAndPercussion: return "Drums & Percussion"
        case .orchestral:         return "Orchestral"
      }
    }

    /**
    initWithUrl:

    - parameter url: NSURL
    */
    init?(url: URL) {
      guard let name = (url as NSURL).filePathURL?.deletingPathExtension().lastPathComponent else { return nil }
      switch name {
        case Volume.brassAndWoodwinds.fileName:  self = .brassAndWoodwinds
        case Volume.keyboardsAndSynths.fileName: self = .keyboardsAndSynths
        case Volume.guitarsAndBasses.fileName:   self = .guitarsAndBasses
        case Volume.worldInstruments.fileName:   self = .worldInstruments
        case Volume.drumsAndPercussion.fileName: self = .drumsAndPercussion
        case Volume.orchestral.fileName:         self = .orchestral
        default:                                 return nil
      }
    }
  }

  var url: URL { return volume.url }
  let volume: Volume
  let presets: [SF2File.Preset]
  var displayName: String { return volume.displayName }
  var fileName: String { return volume.fileName }
  var image: UIImage { return volume.image }

  /**
  init:

  - parameter vol: Volume
  */
  init(_ vol: Volume) {
    volume = vol
    presets = try! SF2File(file: vol.url).presets.sorted()
  }

  /**
  init:

  - parameter u: NSURL
  */
  init(url u: URL) throws {
    guard let vol = Volume(url: u) else { throw Error.InvalidURL }
    self.init(vol)
  }

}

extension EmaxSoundSet {
  enum Error: String, Swift.Error { case InvalidURL }
}
