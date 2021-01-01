//
//  PresetHeader.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import MoonKit

// MARK: - PresetHeader

/// A structure for representing a preset header parsed while decoding a sound font file.
public struct PresetHeader {
  /// The name of the preset.
  public let name: String

  /// The program assigned to the preset.
  public let program: UInt8

  /// The bank assigned to the preset.
  public let bank: UInt8

  /// Initializing with known property values.
  public init(name: String, program: UInt8, bank: UInt8) {
    self.name = name
    self.program = program
    self.bank = bank
  }

  /// Initialize from a preset header subchunk from a pdta's phdr subchunk.
  public init?(data: Data.SubSequence) throws {
    // Check the size of the data.
    guard data.count == 38 else { throw Error.StructurallyUnsound }

    // Decode the preset's name.
    name = String(data[..<(data.firstIndex(of: UInt8(0)) ?? data.startIndex + 20)])

    // Decode the program
    program = UInt8(UInt16(data[data.startIndex + 20 ... data.startIndex + 21]).bigEndian)

    // Decode the bank.
    bank = UInt8(UInt16(data[data.startIndex + 22 ... data.startIndex + 23]).bigEndian)

    // Check that the name is valid and that it is not the end marker for a list of presets.
    guard name != "EOP", !name.isEmpty else { return nil }
  }
}

// MARK: Comparable

extension PresetHeader: Comparable {
  /// Returns `true` iff the two preset headers have equal bank and program values.
  public static func ==(lhs: PresetHeader, rhs: PresetHeader) -> Bool {
    lhs.bank == rhs.bank && lhs.program == rhs.program
  }

  /// Returns `true` iff the bank value of `lhs` is less than that of `rhs`
  /// or the bank values are equal and the program value of `lhs` is less than
  /// that of `rhs`.
  public static func <(lhs: PresetHeader, rhs: PresetHeader) -> Bool {
    lhs.bank < rhs.bank || (lhs.bank == rhs.bank && lhs.program < rhs.program)
  }
}

// MARK: CustomStringConvertible

extension PresetHeader: CustomStringConvertible {
  public var description: String {
    "PresetHeader {name: \(name); program: \(program); bank: \(bank)}"
  }
}

// MARK: JSONValueConvertible

extension PresetHeader: JSONValueConvertible {
  /// The preset header converted to a JSON object.
  public var jsonValue: JSONValue { ["name": name, "program": program, "bank": bank] }
}

// MARK: JSONValueInitializable

extension PresetHeader: JSONValueInitializable {
  /// Initializing from a JSON value. To be successful, `jsonValue` needs to be
  /// a JSON object with keys 'name', 'program', and 'bank' with values convertible
  /// to `String`, `UInt8`, and `UInt8`.
  public init?(_ jsonValue: JSONValue?) {
    // Retrieve the property values.
    guard let dict = ObjectJSONValue(jsonValue),
          let name = String(dict["name"]),
          let program = UInt8(dict["program"]),
          let bank = UInt8(dict["bank"])
    else {
      return nil
    }

    // Initialize using the retrieved property values.
    self = PresetHeader(name: name, program: program, bank: bank)
  }
}
