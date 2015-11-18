//
//  SF2File.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/7/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
#if os(iOS)
  import MoonKit
  #else
  import MoonKitOSX
#endif

/** Parses the data from a SoundFont file, which consists of three chunks: info, sdta, and pdta */
struct SF2File {

  let url: NSURL

  private let info: INFOChunk
  private let sdta: SDTAChunk
  private let pdta: PDTAChunk

  /**
  Initializer that takes a file url

  - parameter file: NSURL
  */
  init(file: NSURL) throws {

    // Grab the url and data
    url = file
    guard let fileData = NSData(contentsOfURL: file) else { throw Error.ReadFailure }

    // Check the data length
    let totalBytes = fileData.length
    guard totalBytes > 8 else { throw Error.FileStructurallyUnsound }

    // Get a pointer to the underlying memory buffer
    let bytes = UnsafeBufferPointer<Byte>(start: UnsafePointer<Byte>(fileData.bytes), count: totalBytes)

    guard String(bytes[bytes.startIndex ..< bytes.startIndex + 4]).lowercaseString == "riff" else {
      throw Error.FileHeaderInvalid
    }

    // Get the size specified by the file and make sure it is long enough to get to the first chunk size
    let riffSize = Int(Byte4(bytes[bytes.startIndex + 4 ..< bytes.startIndex + 8]).bigEndian)
    guard riffSize + 8 == totalBytes && riffSize > 20 else {
      throw Error.FileStructurallyUnsound
    }

    // Check the bytes up to info size and get the info size
    guard String(Array(bytes[bytes.startIndex + 8 ..< bytes.startIndex + 16])) == "sfbkLIST" else {
      throw Error.FileStructurallyUnsound
    }

    let infoSize = Int(Byte4(bytes[bytes.startIndex + 16 ..< bytes.startIndex + 20]).bigEndian)

    // Check that there are enough bytes for the info chunk size
    guard totalBytes >= bytes.startIndex + infoSize + 20 else {
      throw Error.StructurallyUnsound
    }

    // Create a reference slice of the info chunk
    let infoBytes = bytes[bytes.startIndex + 20 ..< bytes.startIndex + infoSize + 20]


    // Check for sdta list
    guard bytes[infoBytes.endIndex ..< infoBytes.endIndex + 4].elementsEqual("LIST".utf8) else {
      throw Error.StructurallyUnsound
    }

    // Get the sdta chunk size
    let sdtaSize = Int(Byte4(bytes[infoBytes.endIndex + 4 ..< infoBytes.endIndex + 8]).bigEndian)

    // Check size against total bytes
    guard totalBytes >= infoBytes.endIndex + sdtaSize + 8 else {
      throw Error.StructurallyUnsound
    }

    // Create a reference slice of the sdta chunk
    let sdtaBytes = bytes[infoBytes.endIndex + 8 ..< infoBytes.endIndex + sdtaSize + 8]

    // Check for pdta list
    guard bytes[sdtaBytes.endIndex ..< sdtaBytes.endIndex + 4].elementsEqual("LIST".utf8) else {
      throw Error.StructurallyUnsound
    }

    // Get the sdta chunk size
    let pdtaSize = Int(Byte4(bytes[sdtaBytes.endIndex + 4 ..< sdtaBytes.endIndex + 8]).bigEndian)

    // Check size against total bytes
    guard totalBytes >= sdtaBytes.endIndex + pdtaSize + 8 else {
      throw Error.StructurallyUnsound
    }

    // Create a reference slice of the sdta chunk
    let pdtaBytes = bytes[sdtaBytes.endIndex + 8 ..< sdtaBytes.endIndex + pdtaSize + 8]

    // Parse the chunks
    info = try INFOChunk(bytes: infoBytes)
    sdta = try SDTAChunk(bytes: sdtaBytes, url: url)
    pdta = try PDTAChunk(bytes: pdtaBytes, url: url)
    logVerbose(description)
  }

  var bytes: [Byte] {
    var result: [Byte] = "RIFF".bytes

    let listBytes = "LIST".bytes

    let infoBytes = info.bytes
    result += listBytes
    result += Byte4(infoBytes.count).bytes
    result += infoBytes

    let sdtaBytes = sdta.bytes
    result += listBytes
    result += Byte4(sdtaBytes.count).bytes
    result += sdtaBytes

    let pdtaBytes = pdta.bytes
    result += listBytes
    result += Byte4(pdtaBytes.count).bytes
    result += pdtaBytes

    return result
  }

}

// MARK: - Error

extension SF2File {

  enum Error: String, ErrorType, CustomStringConvertible {
    case ReadFailure             = "Failed to obtain data from the file specified"
    case FileStructurallyUnsound = "The specified file is not structurally sound"
    case FileHeaderInvalid       = "The specified file does not contain a valid RIFF header"
    case FileOnDiskModified      = "The referenced file has been modified"
    case StructurallyUnsound     = "Invalid chunk"
    case PresetHeaderInvalid     = "Invalid preset header detected in PDTA chunk"
    case ParseError              = "Failed to parse chunk"
  }

}


// MARK: - Preset

extension SF2File {

  struct Preset: Comparable, CustomStringConvertible {
    let name: String
    let program: Byte
    let bank: Byte
    var description: String { return "Preset {name: \(name); program: \(program); bank: \(bank)}" }
  }

  var presets: [Preset] {
    guard case let .Presets(_, chunk) = pdta.phdr else { return [] }
    return chunk.headers.map { Preset(name: $0.name, program: Byte($0.preset), bank: Byte($0.bank))}
  }

}

extension SF2File: CustomStringConvertible {

  var description: String {
    return "\n".join(
      "url: '\(url.path!)'",
      "info:\n\(info.description.indentedBy(1, useTabs: true))",
      "sdta:\n\(sdta.description.indentedBy(1, useTabs: true))",
      "pdta:\n\(pdta.description.indentedBy(1, useTabs: true))"
    )
  }

}

extension SF2File: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

func ==(lhs: SF2File.Preset, rhs: SF2File.Preset) -> Bool {
  return lhs.bank == rhs.bank && lhs.program == rhs.program
}

func <(lhs: SF2File.Preset, rhs: SF2File.Preset) -> Bool {
  return lhs.bank < rhs.bank || (lhs.bank == rhs.bank && lhs.program < rhs.program)
}