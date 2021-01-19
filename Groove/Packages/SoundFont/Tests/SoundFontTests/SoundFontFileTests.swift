//
//  SoundFontFileTests.swift
//  SoundFontFileTests
//
//  Created by Jason Cardwell on 9/26/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import MoonDev
import Nimble
@testable import SoundFont
import XCTest

@available(iOS 14.0, *)
@available(OSX 11.0, *)
final class SoundFontFileTests: XCTestCase
{
  static var testURL: URL!
  static var testData: Data!
  static var testINFOData: Data.SubSequence!
  static var testSDTAData: Data.SubSequence!
  static var testPDTAData: Data.SubSequence!

  override static func setUp()
  {
    guard let url = SoundFont.bundle.url(forResource: "Emax Volume 1",
                                         withExtension: "sf2")
    else
    {
      fatalError("Failed to locate test file")
    }

    testURL = url

    do
    {
      testData = try Data(contentsOf: testURL)
      testINFOData = testData[0x14 ..< (0xFE - 4)]
      testSDTAData = testData[0xFE ..< 0xCFAA22]
      testPDTAData = testData[0xCFAA22 ..< testData.endIndex]
    }
    catch
    {
      fatalError("Failed to populate test data from url: '\(String(describing: testURL))'")
    }
  }

  func testINFOChunk()
  {
    guard let chunk = try? INFOChunk(data: SoundFontFileTests.testINFOData)
    else
    {
      XCTFail("Failed to initialize chunk using test data")
      return
    }

    expect(chunk.ifil.major) == 2
    expect(chunk.ifil.minor) == 1
    expect(chunk.isng.value) == "SF SW Engine"
    expect(chunk.inam.value) == "Emax Volume 1 Brass & Woodwinds"
    expect(chunk.icrd?.value).to(beEmpty())
    expect(chunk.ieng?.value) == "www.DigitalSound Factory.com"
    expect(chunk.iprd?.value).to(beEmpty())
    expect(chunk.icop?.value) == "DigitalSoundFactory/E-mu Systems 2007"
    expect(chunk.icmt?.value).to(beEmpty())
    expect(chunk.isft?.value) == "SFEDT v1.29:SFEDT v1.29:"
  }

  func testSDTAChunk()
  {
    guard let chunk = try? SDTAChunk(data: SoundFontFileTests.testSDTAData)
    else
    {
      XCTFail("Failed to initialize chunk using test data")
      return
    }

    guard let smplChunk = chunk.smpl
    else
    {
      XCTFail("Unexpected value for 'chunk.pmod'")
      return
    }
    expect(smplChunk).to(haveCount(13_609_232))
  }

  func testPDTAChunk()
  {
    guard let chunk = try? PDTAChunk(data: SoundFontFileTests.testPDTAData)
    else
    {
      XCTFail("Failed to initialize chunk using test data")
      return
    }
    expect(chunk.phdr).to(haveCount(171))
    expect(chunk.pbag).to(haveCount(1_364))
    expect(chunk.pmod).to(haveCount(15_220))
    expect(chunk.pgen).to(haveCount(2_720))
    expect(chunk.inst).to(haveCount(3_784))
    expect(chunk.ibag).to(haveCount(8_220))
    expect(chunk.imod).to(haveCount(10))
    expect(chunk.igen).to(haveCount(81_568))
    expect(chunk.shdr).to(haveCount(11_178))
  }

  func testPresets()
  {
    guard let presets = try? File.presetHeaders(from: SoundFontFileTests.testData)
    else
    {
      XCTFail("Failed to get presets from url")
      return
    }
    expect(presets.count).to(beGreaterThan(0))
  }

  func testFile()
  {
    guard (try? File(fileURL: SoundFontFileTests.testURL)) != nil
    else
    {
      XCTFail("Failed to initialize file structure from test url")
      return
    }
  }
}
