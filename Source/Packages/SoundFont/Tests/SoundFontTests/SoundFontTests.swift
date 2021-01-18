import MoonDev
import Nimble
@testable import SoundFont
import XCTest
import struct SwiftUI.Image

@available(iOS 14.0, *)
@available(OSX 11.0, *)
class SoundFontTests: XCTestCase
{
  static var spyroURL: URL!
  static var emax1URL: URL!
  static var emax2URL: URL!
  static var emax3URL: URL!
  static var emax4URL: URL!
  static var emax5URL: URL!
  static var emax6URL: URL!
  static var spyroImage: Image!
  static var emax1Image: Image!
  static var emax2Image: Image!
  static var emax3Image: Image!
  static var emax4Image: Image!
  static var emax5Image: Image!
  static var emax6Image: Image!
  #if os(iOS)
  static var spyroJSON: ArrayJSONValue!
  static var emax1JSON: ArrayJSONValue!
  static var emax2JSON: ArrayJSONValue!
  static var emax3JSON: ArrayJSONValue!
  static var emax4JSON: ArrayJSONValue!
  static var emax5JSON: ArrayJSONValue!
  static var emax6JSON: ArrayJSONValue!
  #endif

  override static func setUp()
  {
    spyroURL = SoundFont.bundle.url(forResource: "SPYRO's Pure Oscillators", withExtension: "sf2")!
    emax1URL = SoundFont.bundle.url(forResource: "Emax Volume 1", withExtension: "sf2")!
    emax2URL = SoundFont.bundle.url(forResource: "Emax Volume 2", withExtension: "sf2")!
    emax3URL = SoundFont.bundle.url(forResource: "Emax Volume 3", withExtension: "sf2")!
    emax4URL = SoundFont.bundle.url(forResource: "Emax Volume 4", withExtension: "sf2")!
    emax5URL = SoundFont.bundle.url(forResource: "Emax Volume 5", withExtension: "sf2")!
    emax6URL = SoundFont.bundle.url(forResource: "Emax Volume 6", withExtension: "sf2")!

    spyroImage = Image("oscillator", bundle: SoundFont.bundle)
    emax1Image = Image("brass", bundle: SoundFont.bundle)
    emax2Image = Image("piano_keyboard", bundle: SoundFont.bundle)
    emax3Image = Image("guitar_bass", bundle: SoundFont.bundle)
    emax4Image = Image("world", bundle: SoundFont.bundle)
    emax5Image = Image("percussion", bundle: SoundFont.bundle)
    emax6Image = Image("orchestral", bundle: SoundFont.bundle)

    #if os(iOS)
    guard let json0 =
      ArrayJSONValue((try? JSONSerialization
                        .parse(resource: "SPYRO's Pure Oscillators", in: SoundFont.bundle)) ?? nil)
    else
    {
      fatalError("Failed to locate test file")
    }
    spyroJSON = json0
    guard let json1 =
      ArrayJSONValue((try? JSONSerialization
                        .parse(resource: "Emax Volume 1", in: SoundFont.bundle)) ??
        nil)
    else
    {
      fatalError("Failed to locate test file")
    }
    emax1JSON = json1
    guard let json2 =
      ArrayJSONValue((try? JSONSerialization
                        .parse(resource: "Emax Volume 2", in: SoundFont.bundle)) ??
        nil)
    else
    {
      fatalError("Failed to locate test file")
    }
    emax2JSON = json2
    guard let json3 =
      ArrayJSONValue((try? JSONSerialization
                        .parse(resource: "Emax Volume 3", in: SoundFont.bundle)) ??
        nil)
    else
    {
      fatalError("Failed to locate test file")
    }
    emax3JSON = json3
    guard let json4 =
      ArrayJSONValue((try? JSONSerialization
                        .parse(resource: "Emax Volume 4", in: SoundFont.bundle)) ??
        nil)
    else
    {
      fatalError("Failed to locate test file")
    }
    emax4JSON = json4
    guard let json5 =
      ArrayJSONValue((try? JSONSerialization
                        .parse(resource: "Emax Volume 5", in: SoundFont.bundle)) ??
        nil)
    else
    {
      fatalError("Failed to locate test file")
    }
    emax5JSON = json5
    guard let json6 =
      ArrayJSONValue((try? JSONSerialization
                        .parse(resource: "Emax Volume 6", in: SoundFont.bundle)) ??
        nil)
    else
    {
      fatalError("Failed to locate test file")
    }
    emax6JSON = json6
    #endif
  }

  static var allTests = [
    ("testImages", testImages),
    ("testPresets", testPresets),
    ("testURLs", testURLs),
    ("testSubscript", testSubscript),
    ("testEquality", testEquality)
  ]

  func testImages()
  {
    expect(AnySoundFont.spyro.image) == SoundFontTests.spyroImage
    expect(EmaxSoundFont(.brassAndWoodwinds).image) == SoundFontTests.emax1Image
    expect(EmaxSoundFont(.keyboardsAndSynths).image) == SoundFontTests.emax2Image
    expect(EmaxSoundFont(.guitarsAndBasses).image) == SoundFontTests.emax3Image
    expect(EmaxSoundFont(.worldInstruments).image) == SoundFontTests.emax4Image
    expect(EmaxSoundFont(.drumsAndPercussion).image) == SoundFontTests.emax5Image
    expect(EmaxSoundFont(.orchestral).image) == SoundFontTests.emax6Image
  }

  func testPresets()
  {
    #if os(iOS)
    let spyroPresets = SoundFontTests.spyroJSON.value.compactMap(PresetHeader.init)
    expect(AnySoundFont.spyro.presetHeaders) == spyroPresets
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
    #endif
  }

  func testURLs()
  {
    expect(AnySoundFont.spyro.url) == SoundFontTests.spyroURL
    expect(EmaxSoundFont(.brassAndWoodwinds).url) == SoundFontTests.emax1URL
    expect(EmaxSoundFont(.keyboardsAndSynths).url) == SoundFontTests.emax2URL
    expect(EmaxSoundFont(.guitarsAndBasses).url) == SoundFontTests.emax3URL
    expect(EmaxSoundFont(.worldInstruments).url) == SoundFontTests.emax4URL
    expect(EmaxSoundFont(.drumsAndPercussion).url) == SoundFontTests.emax5URL
    expect(EmaxSoundFont(.orchestral).url) == SoundFontTests.emax6URL
  }

  func testSubscript()
  {
    let SoundFont = EmaxSoundFont(.brassAndWoodwinds)
    let preset = PresetHeader(name: "D Trumpet", program: 4, bank: 0)
    expect(SoundFont[4]) == preset
    expect(SoundFont[program: 4, bank: 0]) == preset
  }

  func testEquality()
  {
    expect(
      EmaxSoundFont(.brassAndWoodwinds).isEqualTo(EmaxSoundFont(.brassAndWoodwinds))
    ) ==
      true
    expect(EmaxSoundFont(.brassAndWoodwinds)
      .isEqualTo(EmaxSoundFont(.keyboardsAndSynths))) == false
    expect(AnySoundFont.spyro.isEqualTo(AnySoundFont.spyro)) == true
  }
}
