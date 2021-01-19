//
//  ElementalComponents.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/21/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev


// MARK: - PitchModifier

/// An enumeration of the modifiers that lower or raise a note/chord by a number of half
/// steps.
public enum PitchModifier: String
{
  case flat = "♭", sharp = "♯", doubleFlat = "𝄫"
}

// MARK: - Natural

/// An enumeration of the seven 'natural' note names in western tonal music.
public enum Natural: String, CaseIterable, Strideable
{
  case a = "A", b = "B", c = "C", d = "D", e = "E", f = "F", g = "G"
  
  /// The scalar representation of `rawValue`.
  public var scalar: UnicodeScalar { return rawValue.unicodeScalars.first! }
  
  /// An array of all enumeration cases.
  public static let allCases: [Natural] = [.a, .b, .c, .d, .e, .f, .g]
  
  /// Returns the natural note obtained by advancing the natural by `amount`. Traversal
  /// wraps in either direction.
  public func advanced(by amount: Int) -> Natural
  {
    // Get the scalar's numeric value.
    let value = scalar.value
    
    // Determine the offset based on whether traversal moves forward or backward.
    let offset = amount < 0 ? 7 + amount % 7 : amount % 7
    
    // Calculate the value of the scalar at `offset`.
    let advancedValue = (value.advanced(by: offset) - 65) % 7 + 65
    
    // Create a scalar with the calculated value.
    let advancedScalar = UnicodeScalar(advancedValue)!
    
    // Return a natural intialized with the scalar converted to a string.
    return Natural(rawValue: String(advancedScalar))!
  }
  
  /// Returns the distance to `other` in an array of all natural cases.
  public func distance(to other: Natural) -> Int
  {
    // Calculate and return the distance by utilizing their scalar values.
    return Int(other.scalar.value) - Int(scalar.value)
  }
}

// MARK: - Octave

/// An enumeration of the octaves representable with MIDI values.
public enum Octave: Int, LosslessJSONValueConvertible, CaseIterable
{
  case negativeOne = -1, zero, one, two, three, four, five, six, seven, eight, nine
  
  /// All octaves in ascending order.
  public static let allCases: [Octave] = [
    .negativeOne, .zero, .one, .two, .three, .four, .five, .six, .seven, .eight, .nine
  ]
  
  /// The lowest octave.
  public static var minOctave: Octave { return .negativeOne }
  
  /// The hightest octave.
  public static var maxOctave: Octave { return .nine }
}

// MARK: - Velocity

/// An enumeration for musical dynamics.
public enum Velocity: String, CaseIterable, CustomStringConvertible
{
  case 𝑝𝑝𝑝, 𝑝𝑝, 𝑝, 𝑚𝑝, 𝑚𝑓, 𝑓, 𝑓𝑓, 𝑓𝑓𝑓
  
  /// All velocities ordered from softest to loudest.
  public static let allCases: [Velocity] = [.𝑝𝑝𝑝, .𝑝𝑝, .𝑝, .𝑚𝑝, .𝑚𝑓, .𝑓, .𝑓𝑓, .𝑓𝑓𝑓]
  
  /// The velocity expressed as a MIDI value.
  public var midi: UInt8
  {
    switch self
    {
      case .𝑝𝑝𝑝: return 16
      case .𝑝𝑝: return 33
      case .𝑝: return 49
      case .𝑚𝑝: return 64
      case .𝑚𝑓: return 80
      case .𝑓: return 96
      case .𝑓𝑓: return 112
      case .𝑓𝑓𝑓: return 126
    }
  }
  
  /// Initializing with a MIDI value. The velocity is intialized with the case whose raw
  /// value is nearest to `value`.
  public init(midi value: UInt8)
  {
    switch value
    {
      case 0 ... 22: self = .𝑝𝑝𝑝
      case 23 ... 40: self = .𝑝𝑝
      case 41 ... 51: self = .𝑝
      case 52 ... 70: self = .𝑚𝑝
      case 71 ... 88: self = .𝑚𝑓
      case 81 ... 102: self = .𝑓
      case 103 ... 119: self = .𝑓𝑓
      default: self = .𝑓𝑓𝑓
    }
  }
  
  public var description: String { return rawValue }
}

// MARK: LosslessJSONValueConvertible, ImageAssetLiteralType

extension Velocity: LosslessJSONValueConvertible, ImageAssetLiteralType {}

// MARK: - Duration

/// An enumeration for expressing the duration of musical note.
public enum Duration: String, CaseIterable
{
  case doubleWhole, dottedWhole, whole, dottedHalf, half, dottedQuarter, quarter,
       dottedEighth, eighth, dottedSixteenth, sixteenth, dottedThirtySecond, thirtySecond,
       dottedSixtyFourth, sixtyFourth, dottedHundredTwentyEighth, hundredTwentyEighth,
       dottedTwoHundredFiftySixth, twoHundredFiftySixth
  
  public func seconds(withBPM bpm: Double) -> Double
  {
    let secondsPerBeat = 60 / bpm
    switch self
    {
      case .doubleWhole: return secondsPerBeat * 8
      case .dottedWhole: return secondsPerBeat * 6
      case .whole: return secondsPerBeat * 4
      case .dottedHalf: return secondsPerBeat * 3
      case .half: return secondsPerBeat * 2
      case .dottedQuarter: return secondsPerBeat * 3 / 2
      case .quarter: return secondsPerBeat
      case .dottedEighth: return secondsPerBeat * 3 / 4
      case .eighth: return secondsPerBeat * 1 / 2
      case .dottedSixteenth: return secondsPerBeat * 3 / 8
      case .sixteenth: return secondsPerBeat * 1 / 4
      case .dottedThirtySecond: return secondsPerBeat * 3 / 16
      case .thirtySecond: return secondsPerBeat * 1 / 8
      case .dottedSixtyFourth: return secondsPerBeat * 3 / 32
      case .sixtyFourth: return secondsPerBeat * 1 / 16
      case .dottedHundredTwentyEighth: return secondsPerBeat * 3 / 64
      case .hundredTwentyEighth: return secondsPerBeat * 1 / 32
      case .dottedTwoHundredFiftySixth: return secondsPerBeat * 3 / 128
      case .twoHundredFiftySixth: return secondsPerBeat * 1 / 64
    }
  }
  
  /// All durations ordered from longest to shortest.
  public static let allCases: [Duration] = [
    .doubleWhole, .dottedWhole, .whole, .dottedHalf, .half, .dottedQuarter, .quarter,
    .dottedEighth, .eighth, .dottedSixteenth, .sixteenth, .dottedThirtySecond,
    .thirtySecond, .dottedSixtyFourth, .sixtyFourth, .dottedHundredTwentyEighth,
    .hundredTwentyEighth, .dottedTwoHundredFiftySixth, .twoHundredFiftySixth
  ]
}

// MARK: LosslessJSONValueConvertible, ImageAssetLiteralType

extension Duration: LosslessJSONValueConvertible, ImageAssetLiteralType {}
