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

  /// Initialize a sound set using the file located by the specified url.
  init?(url: URL) throws { guard try url.checkResourceIsReachable() else { return nil }; self.url = url }

  static let spyro = try! SoundSet(url: Bundle.main.url(forResource: "SPYRO's Pure Oscillators",
                                                        withExtension: "sf2")!)!
}

