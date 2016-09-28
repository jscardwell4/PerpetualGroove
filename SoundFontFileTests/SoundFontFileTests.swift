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

    guard case .version(.ifil, let ifilChunk) = chunk.ifil else {
      XCTFail("Unexpected value for 'chunk.ifil'")
      return
    }

    expect(ifilChunk.major) == 512
    expect(ifilChunk.minor) == 256

    guard case .text(.isng, let isngChunk) = chunk.isng else {
      XCTFail("Unexpected value for 'chunk.isng'")
      return
    }

    expect(isngChunk.text) == "SF SW Engine"

    guard case .text(.inam, let inamChunk) = chunk.inam else {
      XCTFail("Unexpected value for 'chunk.inam'")
      return
    }

    expect(inamChunk.text) == "Emax Volume 1 Brass & Woodwinds"

    guard chunk.icrd != nil, case .text(.icrd, let icrdChunk) = chunk.icrd! else {
      XCTFail("Unexpected value for 'chunk.icrd'")
      return
    }

    expect(icrdChunk.text).to(beEmpty())

    guard chunk.ieng != nil, case .text(.ieng, let iengChunk) = chunk.ieng! else {
      XCTFail("Unexpected value for 'chunk.ieng'")
      return
    }

    expect(iengChunk.text) == "www.DigitalSound Factory.com"

    guard chunk.iprd != nil, case .text(.iprd, let iprdChunk) = chunk.iprd! else {
      XCTFail("Unexpected value for 'chunk.iprd'")
      return
    }

    expect(iprdChunk.text).to(beEmpty())

    guard chunk.icop != nil, case .text(.icop, let icopChunk) = chunk.icop! else {
      XCTFail("Unexpected value for 'chunk.icop'")
      return
    }

    expect(icopChunk.text) == "DigitalSoundFactory/E-mu Systems 2007"

    guard chunk.icmt != nil, case .text(.icmt, let icmtChunk) = chunk.icmt! else {
      XCTFail("Unexpected value for 'chunk.icmt'")
      return
    }

    expect(icmtChunk.text).to(beEmpty())

    guard chunk.isft != nil, case .text(.isft, let isftChunk) = chunk.isft! else {
      XCTFail("Unexpected value for 'chunk.isft'")
      return
    }
    expect(isftChunk.text) == "SFEDT v1.29:SFEDT v1.29:"

  }

  func testSDTAChunk() {
    guard let chunk = try? SF2File.SDTAChunk(data: SoundFontFileTests.testSDTAData) else {
      XCTFail("Failed to initialize chunk using test data")
      return
    }
    expect(chunk.smpl).to(haveCount(13609232))
  }

  func testPDTAChunk() {
    XCTFail("\(#function) not yet implemented")
  }

  func testSF2File() {
    XCTFail("\(#function) not yet implemented")
  }
  
}
