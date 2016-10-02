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

/// Holds the location, name, and preset info for a `SF2File`
struct SoundSet: SoundFont {
  
  let url: URL

  let presets: [SF2File.Preset]

  var image: UIImage { return #imageLiteral(resourceName: "oscillator") }

  /// Initialize a sound set using the file located by the specified url.
  init(url: URL) throws {
    presets = try SF2File.presets(from: url)
    self.url = url
  }

}

