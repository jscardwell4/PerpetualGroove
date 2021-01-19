//
// SoundFont.swift
// SoundFont
//
// Created by Jason Cardwell on 1/16/21
// Copyright © 2021 Moondeer Studios. All rights reserved.
import Foundation
import MoonDev

@available(iOS 14.0, *)
@available(OSX 10.15, *)
public enum SoundFont
{
  /// Property of convenience for the module's bundle.
  public static let bundle = Bundle.module

  /// Derived array holding all the fonts stored as static properties below.
  public static var bundledFonts: [AnySoundFont]
  {
    [
      SoundFont.brassAndWoodwinds,
      SoundFont.keyboardsAndSynths,
      SoundFont.guitarsAndBasses,
      SoundFont.worldInstruments,
      SoundFont.drumsAndPercussions,
      SoundFont.orchestral,
      SoundFont.spyro
    ]
  }

  /// Emax Volume 1
  public static let brassAndWoodwinds: AnySoundFont =
    .emax(EmaxSoundFont(.brassAndWoodwinds))

  /// Emax Volume 2
  public static let keyboardsAndSynths: AnySoundFont =
    .emax(EmaxSoundFont(.keyboardsAndSynths))

  /// Emax Volume 3
  public static let guitarsAndBasses: AnySoundFont =
    .emax(EmaxSoundFont(.guitarsAndBasses))

  /// Emax Volume 4
  public static let worldInstruments: AnySoundFont =
    .emax(EmaxSoundFont(.worldInstruments))

  /// Emax Volume 5
  public static let drumsAndPercussions: AnySoundFont =
    .emax(EmaxSoundFont(.drumsAndPercussion))

  /// Emax Volume 6
  public static let orchestral: AnySoundFont = .emax(EmaxSoundFont(.orchestral))

  /// SPYRO's Pure Oscillators
  public static let spyro: AnySoundFont = tryOrDie
  {
    .custom(
      try CustomSoundFont(
        url: unwrapOrDie(
          Bundle.module
            .url(forResource: "SPYRO's Pure Oscillators", withExtension: "sf2")
        )
      )
    )
  }
}
