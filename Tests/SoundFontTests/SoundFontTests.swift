//
//  SoundFontTests.swift
//  SoundFontTests
//
//  Created by Jason Cardwell on 12/30/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//

import XCTest
import Nimble
import MoonDev
@testable import Groove
@testable import SoundFont

class SoundFontTests: XCTestCase {

  static var spyroURL: URL!
  static var emax1URL: URL!
  static var emax2URL: URL!
  static var emax3URL: URL!
  static var emax4URL: URL!
  static var emax5URL: URL!
  static var emax6URL: URL!
  static var spyroImage: UIImage!
  static var emax1Image: UIImage!
  static var emax2Image: UIImage!
  static var emax3Image: UIImage!
  static var emax4Image: UIImage!
  static var emax5Image: UIImage!
  static var emax6Image: UIImage!
  static var spyroJSON: ArrayJSONValue!
  static var emax1JSON: ArrayJSONValue!
  static var emax2JSON: ArrayJSONValue!
  static var emax3JSON: ArrayJSONValue!
  static var emax4JSON: ArrayJSONValue!
  static var emax5JSON: ArrayJSONValue!
  static var emax6JSON: ArrayJSONValue!

  override static func setUp() {
    let bundle = Bundle(for: Groove.AppDelegate.self)
    guard let url0 = bundle.url(forResource: "SPYRO's Pure Oscillators", withExtension: "sf2") else {
      fatalError("Failed to locate test file")
    }
    spyroURL = url0
    guard let url1 = bundle.url(forResource: "Emax Volume 1", withExtension: "sf2") else {
      fatalError("Failed to locate test file")
    }
    emax1URL = url1
    guard let url2 = bundle.url(forResource: "Emax Volume 2", withExtension: "sf2") else {
      fatalError("Failed to locate test file")
    }
    emax2URL = url2
    guard let url3 = bundle.url(forResource: "Emax Volume 3", withExtension: "sf2") else {
      fatalError("Failed to locate test file")
    }
    emax3URL = url3
    guard let url4 = bundle.url(forResource: "Emax Volume 4", withExtension: "sf2") else {
      fatalError("Failed to locate test file")
    }
    emax4URL = url4
    guard let url5 = bundle.url(forResource: "Emax Volume 5", withExtension: "sf2") else {
      fatalError("Failed to locate test file")
    }
    emax5URL = url5
    guard let url6 = bundle.url(forResource: "Emax Volume 6", withExtension: "sf2") else {
      fatalError("Failed to locate test file")
    }
    emax6URL = url6

    guard let image0 = UIImage(named: "oscillator", in: bundle, compatibleWith: nil) else {
      fatalError("Failed to locate test file")
    }
    spyroImage = image0
    guard let image1 = UIImage(named: "brass", in: bundle, compatibleWith: nil) else {
      fatalError("Failed to locate test file")
    }
    emax1Image = image1
    guard let image2 = UIImage(named: "piano_keyboard", in: bundle, compatibleWith: nil) else {
      fatalError("Failed to locate test file")
    }
    emax2Image = image2
    guard let image3 = UIImage(named: "guitar_bass", in: bundle, compatibleWith: nil) else {
      fatalError("Failed to locate test file")
    }
    emax3Image = image3
    guard let image4 = UIImage(named: "world", in: bundle, compatibleWith: nil) else {
      fatalError("Failed to locate test file")
    }
    emax4Image = image4
    guard let image5 = UIImage(named: "percussion", in: bundle, compatibleWith: nil) else {
      fatalError("Failed to locate test file")
    }
    emax5Image = image5
    guard let image6 = UIImage(named: "orchestral", in: bundle, compatibleWith: nil) else {
      fatalError("Failed to locate test file")
    }
    emax6Image = image6

    guard let json0 = ArrayJSONValue((try? JSONSerialization.parse(resource: "SPYRO's Pure Oscillators", in: bundle)) ?? nil) else {
      fatalError("Failed to locate test file")
    }
    spyroJSON = json0
    guard let json1 = ArrayJSONValue((try? JSONSerialization.parse(resource: "Emax Volume 1", in: bundle)) ?? nil) else {
      fatalError("Failed to locate test file")
    }
    emax1JSON = json1
    guard let json2 = ArrayJSONValue((try? JSONSerialization.parse(resource: "Emax Volume 2", in: bundle)) ?? nil) else {
      fatalError("Failed to locate test file")
    }
    emax2JSON = json2
    guard let json3 = ArrayJSONValue((try? JSONSerialization.parse(resource: "Emax Volume 3", in: bundle)) ?? nil) else {
      fatalError("Failed to locate test file")
    }
    emax3JSON = json3
    guard let json4 = ArrayJSONValue((try? JSONSerialization.parse(resource: "Emax Volume 4", in: bundle)) ?? nil) else {
      fatalError("Failed to locate test file")
    }
    emax4JSON = json4
    guard let json5 = ArrayJSONValue((try? JSONSerialization.parse(resource: "Emax Volume 5", in: bundle)) ?? nil) else {
      fatalError("Failed to locate test file")
    }
    emax5JSON = json5
    guard let json6 = ArrayJSONValue((try? JSONSerialization.parse(resource: "Emax Volume 6", in: bundle)) ?? nil) else {
      fatalError("Failed to locate test file")
    }
    emax6JSON = json6
  }

  func testImages() {
    expect(CustomSoundFont.spyro.image) == SoundFontTests.spyroImage
    expect(EmaxSoundFont(.brassAndWoodwinds).image) == SoundFontTests.emax1Image
    expect(EmaxSoundFont(.keyboardsAndSynths).image) == SoundFontTests.emax2Image
    expect(EmaxSoundFont(.guitarsAndBasses).image) == SoundFontTests.emax3Image
    expect(EmaxSoundFont(.worldInstruments).image) == SoundFontTests.emax4Image
    expect(EmaxSoundFont(.drumsAndPercussion).image) == SoundFontTests.emax5Image
    expect(EmaxSoundFont(.orchestral).image) == SoundFontTests.emax6Image
  }

  func testPresets() {
    let spyroPresets = SoundFontTests.spyroJSON.value.compactMap(PresetHeader.init)
    expect(CustomSoundFont.spyro.presetHeaders) == spyroPresets
    let emax1Presets = SoundFontTests.emax1JSON.value.compactMap(PresetHeader.init)
    expect(EmaxSoundFont(.brassAndWoodwinds).presetHeaders) == emax1Presets
    let emax2Presets = SoundFontTests.emax2JSON.value.compactMap(PresetHeader.init)
    expect(EmaxSoundFont(.keyboardsAndSynths).presetHeaders) == emax2Presets
    let emax3Presets = SoundFontTests.emax3JSON.value.compactMap(PresetHeader.init)
    expect(EmaxSoundFont(.guitarsAndBasses).presetHeaders) == emax3Presets
    let emax4Presets = SoundFontTests.emax4JSON.value.compactMap(PresetHeader.init)
    expect(EmaxSoundFont(.worldInstruments).presetHeaders) == emax4Presets
    let emax5Presets = SoundFontTests.emax5JSON.value.compactMap(PresetHeader.init)
    expect(EmaxSoundFont(.drumsAndPercussion).presetHeaders) == emax5Presets
    let emax6Presets = SoundFontTests.emax6JSON.value.compactMap(PresetHeader.init)
    expect(EmaxSoundFont(.orchestral).presetHeaders) == emax6Presets
  }

  func testURLs() {
    expect(CustomSoundFont.spyro.url) == SoundFontTests.spyroURL
    expect(EmaxSoundFont(.brassAndWoodwinds).url) == SoundFontTests.emax1URL
    expect(EmaxSoundFont(.keyboardsAndSynths).url) == SoundFontTests.emax2URL
    expect(EmaxSoundFont(.guitarsAndBasses).url) == SoundFontTests.emax3URL
    expect(EmaxSoundFont(.worldInstruments).url) == SoundFontTests.emax4URL
    expect(EmaxSoundFont(.drumsAndPercussion).url) == SoundFontTests.emax5URL
    expect(EmaxSoundFont(.orchestral).url) == SoundFontTests.emax6URL
  }

  func testSubscript() {
    let SoundFont = EmaxSoundFont(.brassAndWoodwinds)
    let preset = PresetHeader(name: "D Trumpet", program: 4, bank: 0)
    expect(SoundFont[4]) == preset
    expect(SoundFont[program: 4, bank: 0]) == preset
  }

  func testEquality() {
    expect(EmaxSoundFont(.brassAndWoodwinds).isEqualTo(EmaxSoundFont(.brassAndWoodwinds))) == true
    expect(EmaxSoundFont(.brassAndWoodwinds).isEqualTo(EmaxSoundFont(.keyboardsAndSynths))) == false
    expect(CustomSoundFont.spyro.isEqualTo(CustomSoundFont.spyro)) == true
  }

}
