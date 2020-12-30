//
//  BarBeatTime
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import typealias CoreMIDI.MIDITimeStamp
import MoonKit

/// `BarBeatTime` formation operator where `lhs` becomes the bar value, the digits that
/// make up the integer part of `rhs` become the beat value, and the fractional part of
/// `rhs` becomes the subbeat value.
func ∶(lhs: UInt, rhs: Double) -> BarBeatTime {

  // Convert `rhs` into a fraction to access it's integer and fractional parts.
  let rhs = Fraction(rhs)

  // Convert the integer part to use as the beat value.
  let beat = UInt(rhs.integerPart)

  // Convert the fractional part to use as the subbeat value.
  let subbeat = UInt(rhs.fractionalPart.decimalForm.numerator)

  return BarBeatTime(bar: lhs, beat: beat, subbeat: subbeat, isNegative: lhs < 0)

}

/// A structure for expressing time as a number of bars, beats, and subbeats.
struct BarBeatTime {

  /// Flag specifiying whether the time represents a negative value.
  private(set) var isNegative = false

  /// Toggles whether or not the time represents a negative value.
  mutating func negate() {

    // Toggle the flag to negate.
    isNegative.toggle()

  }

  /// The time with negativity toggled.
  var negated: BarBeatTime {

    // Create a copy.
    var result = self

    // Negate the copy.
    result.negate()

    // Return the copy.
    return result

  }

  /// The number of complete bars.
  var bar: UInt = 0

  /// The number of complete beats. This is the numerator of the fraction used internally
  /// to represent the beat value.
  var beat: UInt {

    get {

      // Return the beat fraction's numerator convertex to `UInt`.
      return UInt(beatFraction.numerator)

    }

    set {

      // Replace the beat fraction's numerator with the new value.
      beatFraction = UInt128(newValue)╱beatFraction.denominator

      // Normalize if the beat fraction has become improper.
      if beatFraction.isImproper { normalize() }

    }

  }

  /// The number of subbeats. This is the numerator of the fraction used internally to
  /// represent the subbeat value. `1` subbeat is always equal to `1` tick of the MIDI 
  /// clock.
  var subbeat: UInt {

    get {

      // Return the numerator of the subbeat fraction converted to `UInt`.
      return UInt(subbeatFraction.numerator)

    }

    set {

      // Replace the numerator of the subbeat fraction with the new value.
      subbeatFraction = UInt128(newValue)╱subbeatFraction.denominator

      // Normalize if the subbeat fraction has become improper.
      if subbeatFraction.isImproper { normalize() }

    }

  }

  /// The number of subbeats per beat. This is the denominator of the fraction used 
  /// internally to represent the subbeat value.
  var subbeatDivisor: UInt {

    get {

      // Return the subbeat fraction's denominator converted to `UInt`.
      return UInt(subbeatFraction.denominator)

    }

    set {

      // Check that the new and old values are not the same.
      guard newValue != subbeatDivisor else { return }

      // Calculate the number of ticks.
      let currentTicks = beats * subbeatDivisor + subbeat

      // Calculate the number of beats using the new divisor.
      let newBeats = currentTicks / newValue

      // Update `bar` by dividing the new number of beats by the number of beats per bar.
      bar = newBeats / beatsPerBar

      // Update the beat fraction's numerator with the beats not consumed by `bar`.
      beatFraction = UInt128(newBeats - bar * beatsPerBar)╱beatFraction.denominator

      // Set the subbeat fraction to the ticks not consumed by `bar` and `beat` over
      // the new subbeat divisor.
      subbeatFraction = UInt128(currentTicks - newBeats * newValue)╱UInt128(newValue)

      // Update the unit subbeat fraction.
      subbeatUnit = 1╱UInt128(newValue)

    }

  }

  /// The number of beats per bar. This is the denominator of the fraction used internally
  /// to represent the beat value.
  var beatsPerBar: UInt {

    get {

      // Return the beat fraction's denominator converted to `UInt`.
      return UInt(beatFraction.denominator)

    }

    set {

      // Check that the new and old values are not the same.
      guard newValue != beatsPerBar else { return }

      // Disallow dividing by zero.
      precondition(newValue > 0, "`beatsPerBar` must be a positive value")

      // Store the current number of beats.
      let currentBeats = beats

      // Calculate `bar` by dividing the beats using the new divisor.
      bar = currentBeats / newValue

      // Set the beat fraction to the beats not consumed by `bar` over the new divisor.
      beatFraction = UInt128(currentBeats - bar * newValue)╱UInt128(newValue)

      // Update the unit beat fraction.
      beatUnit = 1╱UInt128(newValue)

    }

  }

  /// The number of beats per minute. This value is used when converting to/from seconds.
  var beatsPerMinute: UInt = 120

  /// The time's units. This is a property of convenience which allows accessing/mutating
  /// all of the time's values that specify some kind of ratio among the bar, beat, subbeat,
  /// subbeat values or the number of seconds they represent. This includes the beats per
  /// bar, the beats per minute, and the subbeat divisor.
  var units: Units {

    get {

      // Return an instance of `Units` initialized with time's property values.
      return Units(beatsPerBar: beatsPerBar,
                   beatsPerMinute: beatsPerMinute,
                   subbeatDivisor: subbeatDivisor)
    }

    set {

      // Update the time's property values using the specified instance of `Units`.
      beatsPerMinute = newValue.beatsPerMinute
      beatsPerBar = newValue.beatsPerBar
      subbeatDivisor = newValue.subbeatDivisor

    }

  }

  /// The beat over the beats per bar.
  fileprivate var beatFraction: Fraction

  /// The fraction representing a single beat.
  private(set) var beatUnit: Fraction

  /// A bar-beat time intialized with the beat unit.
  var beatUnitTime: BarBeatTime { return BarBeatTime(beat: 1, units: units) }

  /// The subbeat over the subbeat divisor.
  fileprivate var subbeatFraction: Fraction

  /// The fraction representing a single subbeat.
  private(set) var subbeatUnit: Fraction

  /// A bar-beat time initialized with the subbeat unit.
  var subbeatUnitTime: BarBeatTime { return BarBeatTime(subbeat: 1, units: units) }

  /// Initializing with fractions. Where the fraction denmominators do not align with
  /// their corresponding value in `units`, the provided fraction is converted to the
  /// base in `units`.
  /// - Parameters:
  /// - bar: The value for the time's `bar` property.
  /// - beatFraction: The value for the time's `beatFraction` property.
  /// - subbeatFraction: The value for the time's `subbeatFraction` property.
  /// - units: The values for the time's `beatsPerBar`, `beatsPerMinute`, and 
  ///          `subbeatDivisor` properties.
  /// - isNegative: Whether the time represents a negative value.
  fileprivate init(bar: UInt,
                   beatFraction: Fraction,
                   subbeatFraction: Fraction,
                   units: Units,
                   isNegative: Bool = false)
  {
    // Initialize `bar`.
    self.bar = bar

    // Initialize the beats per minute with the value in `units`.
    self.beatsPerMinute = units.beatsPerMinute

    // Intialize the beat fraction with the specified value converted to the base specified
    // in `units`.
    self.beatFraction = beatFraction.rebased(UInt128(units.beatsPerBar))

    // Initialize the unit beat.
    beatUnit = 1÷UInt128(units.beatsPerBar)

    // Initialize the subbeat fraction with the specified value converted to the base 
    // specified in `units`.
    self.subbeatFraction = subbeatFraction.rebased(UInt128(units.subbeatDivisor))

    // Initialize the unit subbeat.
    subbeatUnit = 1÷UInt128(units.subbeatDivisor)

    // Initialize the negativity flag.
    self.isNegative = isNegative

    // Normalize to ensure both the beat and subbeat fractions are proper.
    normalize()

  }

  /// Initializing with integers.
  /// - Parameters:
  /// - bar: The bar value for the time.
  /// - beat: The beat value for the time.
  /// - subbeat: The subbeat value for the time.
  /// - units: The values for the time's `beatsPerBar`, `beatsPerMinute`, and
  ///          `subbeatDivisor` properties.
  /// - isNegative: Whether the time represents a negative value.
  init(bar: UInt = 0,
       beat: UInt = 0,
       subbeat: UInt = 0,
       units: Units = Units(),
       isNegative: Bool = false)
  {

    // Initialize with fractions derived from `beat`, `subbeat` and `units`.
    self.init(bar: bar,
              beatFraction: UInt128(beat)╱UInt128(units.beatsPerBar),
              subbeatFraction: UInt128(subbeat)╱UInt128(units.subbeatDivisor),
              units: units,
              isNegative: isNegative)

  }

  /// This method balances the distrubtion of the measured time to ensure that the fractions
  /// used internally to represent the beat and subbeat values are both proper fractions.
  /// This behaves like a series of carry operations from right to left on the bar,
  /// beat fraction, and subbeat fraction. The subbeat fraction, when converted to a mixed
  /// fraction, can be viewed as some number of beats and the remaining subbeats. To
  /// normalize these beats are added to the beat fraction's numerator and the remaining
  /// subbeats become the new subbeat fraction value. In the same way, converting the beat
  /// fraction to a mixed fraction yields a number of bars and the remaining beats. These
  /// bars are added to the bar value and the remaining beats become the new beat fraction.
  /// With both fractions proper, the time has been normalized.
  mutating func normalize() {

    // Check that at least one of the fractions is improper.
    guard !(beatFraction.isProper && subbeatFraction.isProper) else { return }

    // Carry over subbeats to beat if the subbeat fraction is improper.
    if !subbeatFraction.isProper {

      // Add the integer part to the beat fraction.
      beatFraction += subbeatFraction.integerPart * beatUnit

      // Update the subbeat fraction.
      subbeatFraction = subbeatFraction.fractionalPart

    }

    // Carry over the beats to bar if the beat fraction is improper.
    if beatFraction.isImproper {

      // Add the integer part to the bar.
      bar += UInt(beatFraction.integerPart.numerator.low)

      // Update the beat fraction.
      beatFraction = beatFraction.fractionalPart

    }

  }

  /// Whether the time is equivalent ot `0`. This is `true` iff `bar`, `beat`, and `subbeat`
  /// are all `0`.
  var isZero: Bool { return bar == 0 && beatFraction == 0 && subbeatFraction == 0 }

  /// A bar-beat time for representing a null value.
  /// - TODO: Find out if properties like these are better derived or stored to memory.
  static var null: BarBeatTime {

    // Return a bar-beat time with zero-valued divisors.
    return BarBeatTime(units: Units(beatsPerBar: 0, beatsPerMinute: 0, subbeatDivisor: 0))

  }

  /// A bar-beat time representing `0`.
  static var zero: BarBeatTime { return BarBeatTime() }

  /// Initializing by converting an existing time to use the specified units.
  init(time: BarBeatTime, units: Units) {

    // Initialize with the existing time.
    self = time

    // Update `units` to perform unit conversions.
    self.units = units

  }

  /// Initializing with a tick value. `tickValue`, `units.subbeatDivisor`, and `isNegative`
  /// are used to calculate the total number of beats. The calculated value and `units` are
  /// then used to initialize the time via `init(totalBeats:units:)`.
  init(tickValue: MIDITimeStamp, units: Units = Units(), isNegative: Bool = false) {

    // Calculate the total beats in decimal form.
    let totalBeats = Double(tickValue) / Double(units.subbeatDivisor)

    // Initialize with the total beats and `units`, negating `totalBeats` if `isNegative`.
    self.init(totalBeats: isNegative ? -totalBeats : totalBeats, units: units)

  }

  /// Initialize with the total number of seconds. `seconds`, `units.beatsPerMinute`, and
  /// `isNegative` are used to calculate the total number of beats. The calculated value 
  /// and `units` are then used to initialize the time via `init(totalBeats:units:)`.
  init(seconds: TimeInterval, units: Units = Units(), isNegative: Bool = false) {

    // Calculate the total beats in decimal form.
    let totalBeats = seconds * (TimeInterval(units.beatsPerMinute) / 60)

    // Initialize with the total beats and `units`, negating `totalBeats` if `isNegative`.
    self.init(totalBeats: isNegative ? -totalBeats : totalBeats, units: units)

  }

  /// Initializing with a decimal representation of total beats and the units. The sign of
  /// `totalBeats` is respected so that passing a negative value creates a negative time
  /// and passing a positive value creates a positive time.
  init(totalBeats: Double, units: Units = Units()) {

    // Set the negativity flag according to the sign of `totalBeats`.
    let isNegative = totalBeats.sign == .minus

    // Use the absolute value of `totalBeats` in calculations.
    let totalBeats = abs(totalBeats)

    // Divide by beats per bar to calculate the bar value.
    let bar = UInt(totalBeats) / units.beatsPerBar

    // Calculate the beat value as the total beats modulo beats per bar.
    let beat = UInt(totalBeats) % units.beatsPerBar

    // Calculate the subbeat by multipying the fractional part of `totalBeats` by the 
    // subbeat divisor.
    let subbeat = UInt(round(modf(totalBeats).1 * Double(units.subbeatDivisor)))

    // Initialize using the calculated values.
    self.init(bar: bar, beat: beat, subbeat: subbeat, units: units, isNegative: isNegative)

  }

  /// Derived property converting beats per minute into beats per second.
  var secondsPerBeat: TimeInterval { return 1 / (TimeInterval(beatsPerMinute) / 60) }

  /// The total number of seconds represented by the time.
  var seconds: TimeInterval { return totalBeats * secondsPerBeat }

  /// The total number of whole beats represented by the time.
  var beats: UInt { return bar * beatsPerBar + beat }

  /// The total number of whole or partial beats represented by the time as a decimal 
  /// number.
  var totalBeats: Double {

    // Calculate the total beats using the bar, beatFraction and subbeatFraction values.
    let totalBeats = Fraction(bar * beatsPerBar) + beatFraction / beatUnit + subbeatFraction

    // Return the calculated value converted to a `Double`, negated if the time is negative.
    return Double(isNegative ? -totalBeats : totalBeats)

  }

  /// The total number of MIDI clock ticks represented by the time.
  var ticks: MIDITimeStamp {

    // Return the sum of the number of whole beats multiplied by the subbeat divisor with
    // the subbeat converted to a `MIDITimeStamp`.
    return MIDITimeStamp(beats * subbeatDivisor + subbeat)

  }

  /// A string describing the time formatted for display in a transport. The format used is
  /// **-**`?`*bar*
  /// **:**
  /// *beat*
  /// **.**
  /// *subbeat*
  ///
  /// where **bar** equals `bar + 1` padded with leading zeros to a length of `3`,
  ///
  /// **beat** equals `beat + 1`,
  /// 
  /// and **subbeat** equals `subbeat + 1` padded with leading zeros to a length equaling
  /// the number of digits in the subbeat divisor.
  /// 
  /// The *leading dash* is included only when the time is *negative*.
  var display: String {

    // Get the zero-padded string value of `bar + 1`.
    let barString = String(bar + 1, radix: 10, minCount: 3)

    // Get the string value of `beat + 1`.
    let beatString = String(beat + 1)

    // Calculate the pad value for the subbeat string.
    let pad = String(subbeatDivisor).utf8.count

    // Get the zero-padded string value of `subbeat + 1`.
    let subbeatString = String(subbeat + 1, radix: 10, minCount: pad)

    // Put it all together
    let result = "\(barString):\(beatString).\(subbeatString)"

    // Return the result prefixed with '-' if the time is negative.
    return isNegative ? "-\(result)" : result

  }

  /// A simple structure for specifying property values for an instance of `BarBeatTime`.
  struct Units: Equatable {

    /// The number of beats per bar. Defaults to `4`.
    var beatsPerBar: UInt = 4

    /// The number of beats per minute. Defaults to `120`.
    var beatsPerMinute: UInt = 120

    /// The number of subbeats per beat. Defaults to `480`.
    var subbeatDivisor: UInt = 480

    /// Returns `true` iff all property values are equal.
    static func ==(lhs: Units, rhs: Units) -> Bool {
      return lhs.beatsPerBar == rhs.beatsPerBar
          && lhs.beatsPerMinute == rhs.beatsPerMinute
          && lhs.subbeatDivisor == rhs.subbeatDivisor
    }
  }

}

extension BarBeatTime: LosslessStringConvertible {

  /// The bar-beat time's raw value.
  var description: String { return rawValue }

  /// Initializes via `init?(rawValue:)`.
  init?(_ description: String) { self.init(rawValue: description) }

}

extension BarBeatTime: RawRepresentable, LosslessJSONValueConvertible {

  /// The raw value of the time is a string composed of the time's value in the following 
  /// format:
  /// **-**`?bar`
  /// **:**
  /// `beatFraction`
  /// **.**
  /// `subbeatFraction`
  /// **@**
  /// `beatsPerMinute`
  var rawValue: String {
    return "\(isNegative ? "-" : "")\(bar):\(beatFraction).\(subbeatFraction)@\(beatsPerMinute)"
  }

  /// Initializing with a raw string representation of a time.
  /// - Parameter rawValue: To be successful, `rawValue` must match the regular expression
  ///                       `[-]?[0-9]+:[0-9]+(/[0-9])?[.][0-9]+(/[0-9]+)?([@][0-9]+)?`
  ///                       where default values are substituted for missing optional 
  ///                       groups.
  init?(rawValue: String) {

    // Create the pattern for the regular expression to match.
    let pattern = [
      "^",
      "(?<negative>-)?",
      "(?<bar>[0-9]+)",
      ":",
      "(?<beat>[0-9]+)",
      "(?:",
        "[╱/]",
        "(?<beatsPerBar>[0-9]+)",
      ")?",
      "[.]",
      "(?<subbeat>[0-9]+)",
      "(?:",
        "[╱/]",
        "(?<subbeatDivisor>[0-9]+)",
      ")?",
      "(?:",
        "@",
        "(?<beatsPerMinute>[0-9]+)",
      ")?",
      "$"
    ].joined(separator: "")

    // Create the regular expression to match.
    let re = ~/pattern

    // Match the specified string, retrieving the non-optional groups matched text
    // converted to unsigned integers.
    guard let match = re.firstMatch(in: rawValue),
              let barString = match["bar"]?.substring,
              let beatString = match["beat"]?.substring,
              let subbeatString = match["subbeat"]?.substring,
              let bar = UInt(barString),
              let beat = UInt(beatString),
              let subbeat = UInt(subbeatString) else { return nil }

    // Create a units structure intialized with default values.
    var units = Units()

    // Update units if the beats per bar is specifed in the raw value.
    if let beatsPerBarString = match["beatsPerBar"]?.substring,
       let beatsPerBarUInt = UInt(beatsPerBarString)
    {
      units.beatsPerBar = beatsPerBarUInt
    }

    // Update units if the subbeat divisor is specified in the raw value.
    if let subbeatDivisorString = match["subbeatDivisor"]?.substring,
      let subbeatDivisorUInt = UInt(subbeatDivisorString)
    {
      units.subbeatDivisor = subbeatDivisorUInt
    }

    // Update units if the beats per minute is specified in the raw value.
    if let beatsPerMinuteString = match["beatsPerMinute"]?.substring,
       let beatsPerMinuteUInt = UInt(beatsPerMinuteString)
    {
      units.beatsPerMinute = beatsPerMinuteUInt
    }

    // Initialize using the values obtained from the raw value.
    self.init(bar: bar,
              beat: beat,
              subbeat: subbeat,
              units: units,
              isNegative: match["negative"] != nil)


  }

}

extension BarBeatTime: ExpressibleByStringLiteral {

  /// Initializing with a string literal. `value` is interpretted as a raw value and the
  /// time initialized via `init?(rawValue:)`. If initialization fails then the time
  /// set to equal `null`.
  init(stringLiteral value: String) { self = BarBeatTime(rawValue: value) ?? .null }

  /// Initializes via `init(stringLiteral:)`.
  init(unicodeScalarLiteral value: String) { self.init(stringLiteral: value) }

  /// Initializes via `init(stringLiteral:)`.
  init(extendedGraphemeClusterLiteral value: String) { self.init(stringLiteral: value) }

}

extension BarBeatTime: ExpressibleByFloatLiteral {

  /// Initializng with a float literal value. The value is interpretted as the time's total
  /// beats and the time is initialized via `init(totalBeats:units:)` using default units.
  init(floatLiteral value: Double) {
    self.init(totalBeats: value)
  }

}

extension BarBeatTime: SignedInteger {

  /// Initializing with builtin max integer value. Initializes via `init(_:)` with `value`
  /// converted to `IntMax`.
//  init(_builtinIntegerLiteral value: Int) {
//    self.init(Int(_builtinIntegerLiteral: value))
//  }

  /// Returns `value` negated.
  static prefix func -(value: BarBeatTime) -> BarBeatTime { return value.negated }

  /// Returns the bar-beat time resulting from subtracting `rhs` from `lhs`.
  static func -(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
    return BarBeatTime.subtractWithOverflow(lhs, rhs).0
  }

  /// Initializing with an integer literal value. The value is interpretted as the time's
  /// total ticks and the time is initialized via `init(tickValue:units:isNegative:)` using
  /// defaults for `units` and `isNegative`.
  init(integerLiteral value: MIDITimeStamp) { self.init(tickValue: value) }

  /// Initializing with an `IntMax` value. `value` is interpretted as the signed total
  /// number of ticks, initialzing the time via `init(tickValue:units:isNegative:)` using
  /// the absolute value of `value`, the default units, and a boolean value that properly
  /// propagates the sign of `value`.
  init(_ value: Int) {
    self = BarBeatTime(tickValue: MIDITimeStamp(abs(value)), isNegative: value < 0)
  }

  /// Returns the time represented as a total number of MIDI clock ticks. The result 
  /// is signed according to whether the time represents a negative value.
  func toInt() -> Int {

    // Convert the time's ticks to `IntMax`.
    let ticks = Int(self.ticks)

    // Return `ticks` negating when the time represents a negative value.
    return isNegative ? -ticks : ticks

  }

  /// Returns the hash value for the bar-beat time's `rawValue`.
  var hashValue: Int { return rawValue.hashValue }

  /// Returns `true` iff `lhs` and `rhs` have equal values for `isNegative`, `bar`, 
  /// `beatFraction`, and `subbeatFraction`.
  static func ==(lhs: BarBeatTime, rhs: BarBeatTime) -> Bool {

    return lhs.isNegative == rhs.isNegative
        && lhs.bar == rhs.bar
        && lhs.beatFraction == rhs.beatFraction
        && lhs.subbeatFraction == rhs.subbeatFraction

  }

  /// Returns `true` iff `lhs` represents a smaller amount of time. The negativity of each
  /// value is respected and behaves exactly as it would in signed integer comparisons.
  static func <(lhs: BarBeatTime, rhs: BarBeatTime) -> Bool {

    // Consider negativity of the two values.
    switch (lhs.isNegative, rhs.isNegative) {

      case (true, false)
        where lhs.isZero && rhs.isZero:
        // Both values are zero even though `lhs` is negative, return `false`.

        return false

      case (true, false):
        // `lhs` is negative and `rhs` is positive. Return `true`.

        return true

      case (false, true):
        // `lhs` is positive and `rhs` is negative. Return `false`.

        return false

      case (true, true):
        // Both values are negative. Consider the bar values.

        switch (lhs.bar, rhs.bar) {

          case let (bar1, bar2)
            where bar1 > bar2:
            // `lhs` has a greater bar value. Since these are both negative values this 
            // means `lhs < rhs`. Return `true`.

            return true

          case let (bar1, bar2)
            where bar1 < bar2:
            // `lhs` has a smaller bar value. Since these are both negative values this
            // means `lhs > rhs`. Return `false`.

            return false

          default:
            // The two bar values are equal. Consider the two beat fractions.

            switch (lhs.beatFraction, rhs.beatFraction) {

              case let (beat1, beat2)
                where beat1 > beat2:
                // `lhs` has a greater beat fraction. Since these are both negative values
                // this means `lhs < rhs`. Return `true`.
                return true

              case let (beat1, beat2)
                where beat1 < beat2:
                // `lhs` has a smaller beat fraction. Since these are both negative values
                // this means `lhs > rhs`. Return `false`.

                return false

              default:
                // The two beat fraction values are equal. Return `true` when `lhs` has
                // a greater subbeat fraction than `rhs`.

                return lhs.subbeatFraction > rhs.subbeatFraction

            }

        }

      case (false, false):
        // Both values are positive. Consider the bar values.

        switch (lhs.bar, rhs.bar) {

          case let (bar1, bar2)
            where bar1 < bar2:
            // `lhs` has a smaller bar value than `rhs`. Return `true`.

            return true

          case let (bar1, bar2)
            where bar1 > bar2:
            // `lhs` has a greater bar value than `rhs`. Return `false`.

            return false

          default:
            // The two bar values are equal. Consider the beat fraction values.

            switch (lhs.beatFraction, rhs.beatFraction) {

              case let (beat1, beat2)
                where beat1 < beat2:
                // `lhs` has a smaller beat fraction than value `rhs`. Return `true`.

                return true

              case let (beat1, beat2)
                where beat1 > beat2:
                // `lhs` has a greater beat fraction value than `rhs`. Return `false`.

                return false

              default:
                // The two beat fraction values are equal. Return `true` when `lhs` has
                // a smaller subbeat fraction value than `rhs`.

                return lhs.subbeatFraction < rhs.subbeatFraction

            }

        }

    }

  }

  /// Returns a tuple containing the result of adding `lhs` to `rhs` and a boolean for
  /// indicating overflow whose value is always `false`.
  static func addWithOverflow(_ lhs: BarBeatTime,
                              _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool)
  {

    // Consider the negativity of each value.
    switch (lhs.isNegative, rhs.isNegative) {

      case (false, false), // x + y
           (true, true):   // -x + -y
        // The two values have the same sign. Convert `rhs` to use the same units as `lhs`
        // and return a bar-beat time initialize with the sums of their properties. The
        // initializer will normalize the fractions.

        // Create a variable with the units that will be used.
        let units = lhs.units

        // Convert `rhs` to use `units`.
        let rhs = BarBeatTime(time: rhs, units: units)

        // Return a bar-beat time initialized using `units` and property sums.
        return (BarBeatTime(bar: lhs.bar + rhs.bar,
                            beatFraction: lhs.beatFraction + rhs.beatFraction,
                            subbeatFraction: lhs.subbeatFraction + rhs.subbeatFraction,
                            units: units,
                            isNegative: lhs.isNegative),
                false)

      case (true, false): // -x + y
        // Adding a positive value to a negative value is the same as subtracting the 
        // negative value's magnitude from the postive value, so return `rhs` minus 
        // `lhs` negated.
        return subtractWithOverflow(rhs, lhs.negated)

      case (false, true): // x + -y
        // Adding a negative value to a positive value is the same as subtracting the
        // negative value's magnitude from the positive value, so return `lhs` minus
        // `rhs` negated.
        return subtractWithOverflow(lhs, rhs.negated)

    }

  }

  /// Returns a tuple containing the result of subtracting `lhs` to `rhs` and a boolean for
  /// indicating overflow whose value is always `false`.
  static func subtractWithOverflow(_ lhs: BarBeatTime,
                                   _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool)
  {

    // Consider the negativity of each value.
    switch (lhs.isNegative, rhs.isNegative) {

      case (false, false):
        // Both values are positive. Convert `rhs` to use the same units as `lhs` and then
        // calculate their difference.

        // Create a variable with the units that will be used.
        let units = lhs.units

        // Convert `rhs` to use `units`.
        let rhs = BarBeatTime(time: rhs, units: units)

        // Consider the number of ticks for each value.
        switch (lhs.ticks, rhs.ticks) {

          case let (lhsTicks, rhsTicks)
            where lhsTicks == rhsTicks:
            // The two values are equal. Return a bar-beat time equal to zero using `units`.

            return (BarBeatTime(units: units), false)

          case let (lhsTicks, rhsTicks)
            where lhsTicks > rhsTicks:
            // `lhs` is greater than `rhs` which means `lhsTicks` - `rhsTicks` does not
            // overflow into a negative value. Return a bar-beat time intialized with
            // the tick difference and that uses `units`.

            return (BarBeatTime(tickValue: lhsTicks - rhsTicks, units: units), false)

          case let (lhsTicks, rhsTicks) /*where lhsTicks < rhsTicks*/:
            // `lhs` is smaller than `rhs` which means `lhsTicks` - `rhsTicks` would 
            // overflow into a negative value. Initialize a bar-beat time with `units`
            // by subtracting `lhsTicks` from `rhsTicks` instead and return it negated.

            return (BarBeatTime(tickValue: rhsTicks - lhsTicks, units: units).negated, false)

        }

      case(true, true): // -x - -y = -x + y = y - x
        // Both values are negative. Subtracting a negative value is the same as adding that
        // value's magnitude. Adding a positive value to a negative value is the same as
        // subtracting the negative value's magnitude from the positive value. Make each
        // value positive and return the result of subtracting `lhs` from `rhs`.

        return subtractWithOverflow(rhs.negated, lhs.negated)

      case (true, false): // -x - y = -x + -y
        // Subtracting a positive value from a negative value is the same as adding the
        // postive value negated. Return the result of adding `rhs.negated` to `lhs`.

        return addWithOverflow(lhs, rhs.negated)

      case (false, true): // x - -y = x + y
        // Subtracting a negative value from a positive value is the same as adding the
        // magnitude of the negative value to the positive value. Return the result of 
        // adding `rhs.negated` to `lhs`.

        return addWithOverflow(lhs, rhs.negated)

    }

  }

  /// Returns a tuple containing the result of multiplying `lhs` by `rhs` and a boolean for
  /// indicating overflow whose value is always `false`.
  static func multiplyWithOverflow(_ lhs: BarBeatTime,
                                   _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool)
  {

    // Return a bar-beat time intialized with the product of total beats and the units
    // used by `lhs`. Since the total beats are represented as `Double` values, no special
    // handling of the values' signs is necessary.
    return (BarBeatTime(totalBeats: lhs.totalBeats * rhs.totalBeats,
                        units: lhs.units),
            false)

  }

  /// Returns a tuple containing the remainder when dividing `lhs` by `rhs` and a boolean 
  /// for indicating overflow whose value is always `false`.
  static func remainderWithOverflow(_ lhs: BarBeatTime,
                                    _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool)
  {

    // Calculate the total beats remaining after division of `lhs` by `rhs`.
    let totalBeats = lhs.totalBeats.truncatingRemainder(dividingBy: rhs.totalBeats)

    // Return a bar-beat time intialized with the calculated value and the units used by 
    // `lhs`.
    return (BarBeatTime(totalBeats: totalBeats, units: lhs.units), false)

  }

  /// Returns a tuple containing the result of dividing `lhs` by `rhs` and a boolean for
  /// indicating overflow whose value is always `false`.
  static func divideWithOverflow(_ lhs: BarBeatTime,
                                 _ rhs: BarBeatTime) -> (BarBeatTime, overflow: Bool)
  {

    // Return a bar-beat time intialized with the quotient of total beats and the units
    // used by `lhs`. Since the total beats are represented as `Double` values, no special
    // handling of the values' signs is necessary.
    return (BarBeatTime(totalBeats: lhs.totalBeats / rhs.totalBeats, units: lhs.units),
            false)

  }

  /// Returns the result from the tuple obtained invoking 
  /// `BarBeatTime.addWithOverflow(_:_:)` with `lhs` and `rhs`.
  static func +(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {

    return BarBeatTime.addWithOverflow(lhs, rhs).0

  }

  /// Returns a bar-beat time representing a tick value equal to `lhs.ticks & rhs.ticks`.
  static func &(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {

    // Convert `rhs` to use the units of `lhs`.
    let rhs = BarBeatTime(time: rhs, units: lhs.units)

    // Return a bar-beat time initialized with a tick value equal to the bitwise AND of
    // the two tick values and using the units of `lhs`.
    return BarBeatTime(tickValue: lhs.ticks & rhs.ticks, units: lhs.units)

  }

  /// Returns a bar-beat time representing a tick value equal to `lhs.ticks ^ rhs.ticks`.
  static func ^(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {

    // Convert `rhs` to use the units of `lhs`.
    let rhs = BarBeatTime(time: rhs, units: lhs.units)

    // Return a bar-beat time initialized with a tick value equal to the bitwise XOR of
    // the two tick values and using the units of `lhs`.
    return BarBeatTime(tickValue: lhs.ticks ^ rhs.ticks, units: lhs.units)

  }

  /// Returns a bar-beat time representing a tick value equal to `lhs.ticks | rhs.ticks`.
  static func |(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {

    // Convert `rhs` to use the units of `lhs`.
    let rhs = BarBeatTime(time: rhs, units: lhs.units)

    // Return a bar-beat time initialized with a tick value equal to the bitwise OR of
    // the two tick values and using the units of `lhs`.
    return BarBeatTime(tickValue: lhs.ticks | rhs.ticks, units: lhs.units)

  }

  /// Returns a bar-beat time representing a tick value equal to `~value.ticks`.
  static prefix func ~(value: BarBeatTime) -> BarBeatTime {

    // Return a bar-beat time initialized with a tick value equal to the bitwise NOT of
    // the value's ticks.
    return BarBeatTime(tickValue: ~value.ticks, units: value.units)

  }

  /// Identical to `BarBeatTime.zero`.
  static var allZeros: BarBeatTime { return BarBeatTime.zero }

  /// Returns `self + n`.
  func advanced(by n: BarBeatTime) -> BarBeatTime { return self + n }

  /// Returns `other - self`.
  func distance(to other: BarBeatTime) -> BarBeatTime { return other - self }

}
