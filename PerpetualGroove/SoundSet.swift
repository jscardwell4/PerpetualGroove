//
//  SoundSet.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/13/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import UIKit.UIImage

/** Wrapper for a sound font file */
struct SoundSet: SoundSetType {
  
  let url: URL
  var fileName: String { return (url.lastPathComponent.baseNameExt.0) }

  let presets: [SF2File.Preset]

  var image: UIImage { return UIImage(named: "oscillator")! }

  /**
  Initialize a sound set using the file located by the specified url.

  - parameter u: NSURL
  */
  init(url u: URL) throws {
    var error: NSError?
    guard (u as NSURL).checkResourceIsReachableAndReturnError(&error) else { throw error! }
    presets = try SF2File(file: u).presets.sorted()
    url = u
  }

}

