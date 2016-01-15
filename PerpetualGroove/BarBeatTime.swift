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

struct BarBeatTime {
  var bar = 0
  var beat = 0
  var subbeat = 0
  var subbeatDivisor = Sequencer.partsPerQuarter
  var beatsPerBar = Sequencer.timeSignature.beatsPerBar

  /**
   initWithBar:beat:subbeat:subbeatDivisor:beatsPerBar:

   - parameter bar: Int = 0
   - parameter beat: Int = 0
   - parameter subbeat: Int = 0
   - parameter subbeatDivisor: Int = Sequencer.partsPerQuarter
   - parameter beatsPerBar: Int = Sequencer.timeSignature.beatsPerBar
  */
  init(bar: Int = 0,
       beat: Int = 0,
       subbeat: Int = 0,
       subbeatDivisor: Int = Sequencer.partsPerQuarter,
       beatsPerBar: Int = Sequencer.timeSignature.beatsPerBar)
  {
    self.bar = bar
    self.beat = beat
    self.subbeat = subbeat
    self.subbeatDivisor = subbeatDivisor
    self.beatsPerBar = beatsPerBar
  }

  var isNormal: Bool {
    return subbeatDivisor > 0
      && beatsPerBar > 0 && bar > 0
      && (1 ... beatsPerBar).contains(beat)
      && (1 ... subbeatDivisor).contains(subbeat)
  }

  static let start = BarBeatTime(bar: 1, beat: 1, subbeat: 1)
  static let zero  = BarBeatTime(bar: 0, beat: 0, subbeat: 0)
  static let null  = BarBeatTime(bar: -1, beat: 0, subbeat: 0)
  
  /**
   addedToBarBeatTime:beatsPerBar:

   - parameter time: BarBeatTime
   - parameter beatsPerBar: UInt16

   - returns: BarBeatTime
   */
//  func addedToBarBeatTime(time: BarBeatTime, beatsPerBar: Int) -> BarBeatTime {
//    var bars = bar + time.bar
//    var beats = beat + time.beat
//    let subbeatsSum = (subbeat╱subbeatDivisor + time.subbeat╱time.subbeatDivisor).fractionWithBase(subbeatDivisor)
//    var subbeats = subbeatsSum.numerator
//    if subbeats > subbeatDivisor { beats += subbeats / subbeatDivisor; subbeats %= subbeatDivisor }
//    if beats > beatsPerBar { bars += beats / beatsPerBar; beats %= beatsPerBar }
//    return BarBeatTime(bar: bars, beat: beats, subbeat: subbeats, subbeatDivisor: subbeatDivisor)
//  }

  /**
   init:beatsPerBar:subbeatDivisor:

   - parameter tickValue: UInt64
   - parameter beatsPerBar: UInt8 = Sequencer.timeSignature.beatsPerBar
   - parameter subbeatDivisor: UInt16 = Sequencer.time.partsPerQuarter
   */
  init(var tickValue: UInt64,
    beatsPerBar: Int = Sequencer.timeSignature.beatsPerBar,
    subbeatDivisor: Int = Sequencer.partsPerQuarter)
  {
    let subbeat = Int(tickValue % UInt64(subbeatDivisor)) + 1
    guard tickValue > UInt64(subbeat) else {
      self = BarBeatTime(bar: 1, beat: 1, subbeat: subbeat, subbeatDivisor: subbeatDivisor, beatsPerBar: beatsPerBar)
      return
    }
    tickValue -= UInt64(subbeat)
    let totalBeats = tickValue / UInt64(subbeatDivisor)
    let beat = Int(totalBeats % UInt64(beatsPerBar)) + 1
    let bar = Int(totalBeats / UInt64(beatsPerBar)) + 1
    self = BarBeatTime(bar: bar, beat: beat, subbeat: subbeat, subbeatDivisor: subbeatDivisor, beatsPerBar: beatsPerBar)
  }

  var doubleValue: Double {
    let bar = Double(max(Int(self.bar) - 1, 0))
    let beat = Double(max(Int(self.beat) - 1, 0))
    let subbeat = Double(max(Int(self.subbeat) - 1, 0))
    return bar * Double(beatsPerBar) + beat + subbeat / Double(subbeatDivisor)
  }

  var ticks: UInt64 {
    let bar = UInt64(max(Int(self.bar) - 1, 0))
    let beat = UInt64(max(Int(self.beat) - 1, 0))
    let subbeat = UInt64(max(Int(self.subbeat) - 1, 0))
    return (bar * UInt64(beatsPerBar) + beat) * UInt64(subbeatDivisor) + subbeat
  }
}

func +(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
  let beatsPerBar = lcm(lhs.beatsPerBar, rhs.beatsPerBar)
  let lhsBeat = (lhs.beat╱lhs.beatsPerBar).fractionWithBase(beatsPerBar)
  let rhsBeat = (rhs.beat╱rhs.beatsPerBar).fractionWithBase(beatsPerBar)
  let subbeatDivisor = lcm(lhs.subbeatDivisor, rhs.subbeatDivisor)
  let lhsSubbeat = (lhs.subbeat╱lhs.subbeatDivisor).fractionWithBase(subbeatDivisor)
  let rhsSubbeat = (rhs.subbeat╱rhs.subbeatDivisor).fractionWithBase(subbeatDivisor)
  var result = BarBeatTime(bar: lhs.bar + rhs.bar,
                           beat: (lhsBeat + rhsBeat).numerator,
                           subbeat: (lhsSubbeat + rhsSubbeat).numerator,
                           subbeatDivisor: subbeatDivisor,
                           beatsPerBar: beatsPerBar)

  if result.subbeat > subbeatDivisor { result.beat++; result.subbeat -= subbeatDivisor }
  if result.beat > beatsPerBar { result.bar++; result.beat -= beatsPerBar }

  return result
}

func -(lhs: BarBeatTime, rhs: BarBeatTime) -> BarBeatTime {
  let beatsPerBar = lcm(lhs.beatsPerBar, rhs.beatsPerBar)
  let lhsBeat = (lhs.beat╱lhs.beatsPerBar).fractionWithBase(beatsPerBar)
  let rhsBeat = (rhs.beat╱rhs.beatsPerBar).fractionWithBase(beatsPerBar)
  let subbeatDivisor = lcm(lhs.subbeatDivisor, rhs.subbeatDivisor)
  let lhsSubbeat = (lhs.subbeat╱lhs.subbeatDivisor).fractionWithBase(subbeatDivisor)
  let rhsSubbeat = (rhs.subbeat╱rhs.subbeatDivisor).fractionWithBase(subbeatDivisor)
  var result = BarBeatTime(bar: lhs.bar - rhs.bar,
                           beat: (lhsBeat - rhsBeat).numerator,
                           subbeat: (lhsSubbeat - rhsSubbeat).numerator,
                           subbeatDivisor: subbeatDivisor,
                           beatsPerBar: beatsPerBar)

  if result.subbeat < 1 { result.beat--; result.subbeat += subbeatDivisor }
  if result.beat < 1 { result.bar--; result.beat += beatsPerBar }

  return result
}

// MARK: - CustomStringConvertible
extension BarBeatTime: CustomStringConvertible {
  var description: String {
    let barString = String(bar, radix: 10, pad: 3)
    let beatString = String(beat)
    let subbeatString = String(subbeat, radix: 10, pad: String(subbeatDivisor).utf8.count)
    return "\(barString):\(beatString).\(subbeatString)"
  }
}

// MARK: - CustomDebugStringConvertible
extension BarBeatTime: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

// MARK: - Hashable
extension BarBeatTime: Hashable {
  var hashValue: Int { return rawValue.hashValue }
}

extension BarBeatTime: RawRepresentable {
  var rawValue: String { return "\(bar):\(beat)╱\(beatsPerBar).\(subbeat)╱\(subbeatDivisor)" }

  init?(rawValue: String) {
    guard let match = (~/"^([0-9]+):([0-9]+)╱([0-9]+)\\.([0-9]+)╱([0-9]+)$").firstMatch(rawValue),
              barString = match.captures[1]?.string,
              beatString = match.captures[2]?.string,
              beatsPerBarString = match.captures[3]?.string,
              subbeatString = match.captures[4]?.string,
              subbeatDivisorString = match.captures[5]?.string,
              bar = Int(barString),
              beat = Int(beatString),
              beatsPerBar = Int(beatsPerBarString),
              subbeat = Int(subbeatString),
              subbeatDivisor = Int(subbeatDivisorString) else { return nil }
    self.init(bar: bar, beat: beat, subbeat: subbeat, subbeatDivisor: subbeatDivisor, beatsPerBar: beatsPerBar)
  }
}

extension BarBeatTime: JSONValueConvertible {
  var jsonValue: JSONValue { return rawValue.jsonValue }
}

extension BarBeatTime: JSONValueInitializable {
  init?(_ jsonValue: JSONValue?) {
    guard let rawValue = String(jsonValue) else { return nil }
    self.init(rawValue: rawValue)
  }
}

func ==(lhs: BarBeatTime, rhs: BarBeatTime) -> Bool { return lhs.rawValue == rhs.rawValue }

// MARK: - Comparable
extension BarBeatTime: Comparable {}

func <(lhs: BarBeatTime, rhs: BarBeatTime) -> Bool {
  guard lhs.bar == rhs.bar else { return lhs.bar < rhs.bar }
  guard lhs.beat == rhs.beat else { return lhs.beat < rhs.beat }
  guard lhs.subbeatDivisor != rhs.subbeatDivisor else { return lhs.subbeat < rhs.subbeat }
  return lhs.subbeat╱lhs.subbeatDivisor < rhs.subbeat╱rhs.subbeatDivisor
}

