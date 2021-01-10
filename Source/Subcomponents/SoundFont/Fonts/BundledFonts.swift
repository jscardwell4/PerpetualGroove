//
//  BundledFonts.swift
//  SoundFont
//
//  Created by Jason Cardwell on 1/7/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

/// An array of the bundled sound fonts.
public let bundledFonts: [SoundFont2] = {
  let emax1 = EmaxSoundFont(.brassAndWoodwinds)
  let emax2 = EmaxSoundFont(.keyboardsAndSynths)
  let emax3 = EmaxSoundFont(.guitarsAndBasses)
  let emax4 = EmaxSoundFont(.worldInstruments)
  let emax5 = EmaxSoundFont(.drumsAndPercussion)
  let emax6 = EmaxSoundFont(.orchestral)
  
  let url = unwrapOrDie
  {
    Bundle(identifier: "com.moondeerstudios.SoundFont")?
      .url(forResource: "SPYRO's Pure Oscillators",
           withExtension: "sf2")
  }
  
  let spyro = tryOrDie { try AnySoundFont(url: url) }
  
  return [emax1, emax2, emax3, emax4, emax5, emax6, spyro]
}()
