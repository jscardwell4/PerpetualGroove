//
//  SoundFontFileTests.swift
//  SoundFontFileTests
//
//  Created by Jason Cardwell on 9/26/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import XCTest
import MoonKit
import MoonKitTest
@testable import Groove

final class SoundFontFileTests: XCTestCase {

  static var testURL: URL!
  static var testData: Data!
  static var testINFOData: Data.SubSequence!
  static var testSDTAData: Data.SubSequence!
  static var testPDTAData: Data.SubSequence!

  override static func setUp() {
    guard let url = Bundle(for: Groove.AppDelegate.self).url(forResource: "Emax Volume 1",
                                                             withExtension: "sf2") else
    {
      fatalError("Failed to locate test file")
    }

    testURL = url

    do {
      testData = try Data(contentsOf: testURL)
      testINFOData = testData[0x14..<0xfe]
      testSDTAData = testData[0xfe..<0xcfaa22]
      testPDTAData = testData[0xcfaa22..<testData.endIndex]
    } catch {
      logError(error)
      fatalError("Failed to populate test data from url: '\(testURL)'")
    }
  }

  func testINFOChunk() {
    guard let chunk = try? SF2File.INFOChunk(data: SoundFontFileTests.testINFOData) else {
      XCTFail("Failed to initialize chunk using test data")
      return
    }

    guard case .version(let major, let minor) = chunk.ifil.data else {
      XCTFail("Unexpected value for 'chunk.ifil'")
      return
    }

    expect(major) == 512
    expect(minor) == 256

    guard case .text(let isngChunk) = chunk.isng.data else {
      XCTFail("Unexpected value for 'chunk.isng'")
      return
    }

    expect(isngChunk) == "SF SW Engine"

    guard case .text(let inamChunk) = chunk.inam.data else {
      XCTFail("Unexpected value for 'chunk.inam'")
      return
    }

    expect(inamChunk) == "Emax Volume 1 Brass & Woodwinds"

    guard case .text(let icrdChunk)? = chunk.icrd?.data else {
      XCTFail("Unexpected value for 'chunk.icrd'")
      return
    }

    expect(icrdChunk).to(beEmpty())

    guard case .text(let iengChunk)? = chunk.ieng?.data else {
      XCTFail("Unexpected value for 'chunk.ieng'")
      return
    }

    expect(iengChunk) == "www.DigitalSound Factory.com"

    guard case .text(let iprdChunk)? = chunk.iprd?.data else {
      XCTFail("Unexpected value for 'chunk.iprd'")
      return
    }

    expect(iprdChunk).to(beEmpty())

    guard case .text(let icopChunk)? = chunk.icop?.data else {
      XCTFail("Unexpected value for 'chunk.icop'")
      return
    }

    expect(icopChunk) == "DigitalSoundFactory/E-mu Systems 2007"

    guard case .text(let icmtChunk)? = chunk.icmt?.data else {
      XCTFail("Unexpected value for 'chunk.icmt'")
      return
    }

    expect(icmtChunk).to(beEmpty())

    guard case .text(let isftChunk)? = chunk.isft?.data else {
      XCTFail("Unexpected value for 'chunk.isft'")
      return
    }
    expect(isftChunk) == "SFEDT v1.29:SFEDT v1.29:"

  }

  func testSDTAChunk() {
    guard let chunk = try? SF2File.SDTAChunk(data: SoundFontFileTests.testSDTAData) else {
      XCTFail("Failed to initialize chunk using test data")
      return
    }

    guard case .data(let smplChunk)? = chunk.smpl?.data else {
      XCTFail("Unexpected value for 'chunk.pmod'")
      return
    }
    expect(smplChunk).to(haveCount(13609232))
  }

  func testLazyPDTAChunk() {
    guard let chunk = try? SF2File.LazyPDTAChunk(data: SoundFontFileTests.testPDTAData,
                                                 url: SoundFontFileTests.testURL)
      else
    {
      XCTFail("Failed to initialize chunk using test data")
      return
    }
    expect(chunk.phdr.range.count) == 6536
    expect(chunk.pbag.range.count) == 1364
    expect(chunk.pmod.range.count) == 15220
    expect(chunk.pgen.range.count) == 2720
    expect(chunk.inst.range.count) == 3784
    expect(chunk.ibag.range.count) == 8220
    expect(chunk.imod.range.count) == 10
    expect(chunk.igen.range.count) == 81568
    expect(chunk.shdr.range.count) == 11178
    
  }

  func testPDTAChunk() {
    guard let chunk = try? SF2File.PDTAChunk(data: SoundFontFileTests.testPDTAData) else {
      XCTFail("Failed to initialize chunk using test data")
      return
    }

    guard case .presets(let phdrChunk) = chunk.phdr.data else {
      XCTFail("Unexpected value for 'chunk.phdr'")
      return
    }
    expect(phdrChunk).to(haveCount(171))

    guard case .data(let pbagChunk) = chunk.pbag.data else {
      XCTFail("Unexpected value for 'chunk.pbag'")
      return
    }
    expect(pbagChunk).to(haveCount(1364))

    guard case .data(let pmodChunk) = chunk.pmod.data else {
      XCTFail("Unexpected value for 'chunk.pmod'")
      return
    }
    expect(pmodChunk).to(haveCount(15220))

    guard case .data(let pgenChunk) = chunk.pgen.data else {
      XCTFail("Unexpected value for 'chunk.pgen'")
      return
    }
    expect(pgenChunk).to(haveCount(2720))

    guard case .data(let instChunk) = chunk.inst.data else {
      XCTFail("Unexpected value for 'chunk.inst'")
      return
    }
    expect(instChunk).to(haveCount(3784))

    guard case .data(let ibagChunk) = chunk.ibag.data else {
      XCTFail("Unexpected value for 'chunk.ibag'")
      return
    }
    expect(ibagChunk).to(haveCount(8220))

    guard case .data(let imodChunk) = chunk.imod.data else {
      XCTFail("Unexpected value for 'chunk.imod'")
      return
    }
    expect(imodChunk).to(haveCount(10))

    guard case .data(let igenChunk) = chunk.igen.data else {
      XCTFail("Unexpected value for 'chunk.igen'")
      return
    }
    expect(igenChunk).to(haveCount(81568))

    guard case .data(let shdrChunk) = chunk.shdr.data else {
      XCTFail("Unexpected value for 'chunk.shdr'")
      return
    }
    expect(shdrChunk).to(haveCount(11178))

  }

  func testPresets() {
    guard let presets = try? SF2File.presetHeaders(from: SoundFontFileTests.testURL) else {
      XCTFail("Failed to get presets from url")
      return
    }
    expect(presets.count).to(beGreaterThan(0))
  }

  func testSF2File() {
    guard (try? SF2File(fileURL: SoundFontFileTests.testURL)) != nil else {
      XCTFail("Failed to initialize file structure from test url")
      return
    }
  }
  
}
