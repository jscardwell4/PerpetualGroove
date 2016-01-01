//
//  EmaxSoundSet.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

struct EmaxSoundSet: SoundSetType {
  enum Volume: Int {
    case BrassAndWoodwinds  = 1
    case KeyboardsAndSynths = 2
    case GuitarsAndBasses   = 3
    case WorldInstruments   = 4
    case DrumsAndPercussion = 5
    case Orchestral         = 6

    var fileName: String { return "Emax Volume \(rawValue)" }

    var url: NSURL {
      // ???: Why did we need to us the reference URL?
      return NSBundle.mainBundle().URLForResource(fileName, withExtension: "sf2")!
    }

    var image: UIImage {
      switch self {
        case .BrassAndWoodwinds:  return UIImage(named: "brass")!
        case .KeyboardsAndSynths: return UIImage(named: "piano_keyboard")!
        case .GuitarsAndBasses:   return UIImage(named: "guitar_bass")!
        case .WorldInstruments:   return UIImage(named: "world")!
        case .DrumsAndPercussion: return UIImage(named: "percussion")!
        case .Orchestral:         return UIImage(named: "orchestral")!
      }
    }


    var selectedImage: UIImage {
      switch self {
        case .BrassAndWoodwinds:  return UIImage(named: "brass-selected")!
        case .KeyboardsAndSynths: return UIImage(named: "piano_keyboard-selected")!
        case .GuitarsAndBasses:   return UIImage(named: "guitar_bass-selected")!
        case .WorldInstruments:   return UIImage(named: "world-selected")!
        case .DrumsAndPercussion: return UIImage(named: "percussion-selected")!
        case .Orchestral:         return UIImage(named: "orchestral-selected")!
      }
    }

    var displayName: String {
      switch self {
        case .BrassAndWoodwinds:  return "Brass & Woodwinds"
        case .KeyboardsAndSynths: return "Keyboards & Synths"
        case .GuitarsAndBasses:   return "Guitars & Basses"
        case .WorldInstruments:   return "World Instruments"
        case .DrumsAndPercussion: return "Drums & Percussion"
        case .Orchestral:         return "Orchestral"
      }
    }

    /**
    initWithUrl:

    - parameter url: NSURL
    */
    init?(url: NSURL) {
      guard let name = url.filePathURL?.URLByDeletingPathExtension?.lastPathComponent else { return nil }
      switch name {
        case Volume.BrassAndWoodwinds.fileName:  self = .BrassAndWoodwinds
        case Volume.KeyboardsAndSynths.fileName: self = .KeyboardsAndSynths
        case Volume.GuitarsAndBasses.fileName:   self = .GuitarsAndBasses
        case Volume.WorldInstruments.fileName:   self = .WorldInstruments
        case Volume.DrumsAndPercussion.fileName: self = .DrumsAndPercussion
        case Volume.Orchestral.fileName:         self = .Orchestral
        default:                                 return nil
      }
    }
  }

  var url: NSURL { return volume.url }
  let volume: Volume
  let presets: [SF2File.Preset]
  var displayName: String { return volume.displayName }
  var fileName: String { return volume.fileName }
  var image: UIImage { return volume.image }
  var selectedImage: UIImage { return volume.selectedImage }

  /**
  init:

  - parameter vol: Volume
  */
  init(_ vol: Volume) {
    volume = vol
    presets = try! SF2File(file: vol.url).presets.sort()
  }

  /**
  init:

  - parameter u: NSURL
  */
  init(url u: NSURL) throws {
    guard let vol = Volume(url: u) else { throw Error.InvalidURL }
    self.init(vol)
  }

}

extension EmaxSoundSet {
  enum Error: String, ErrorType { case InvalidURL }
}
