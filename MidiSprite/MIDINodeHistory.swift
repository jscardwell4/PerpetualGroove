//
//  MIDINodeHistory.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import typealias AudioToolbox.MIDITimeStamp

struct MIDINodeHistory: SequenceType {

  let initialSnapshot: Snapshot

  private var breadcrumbs = Tree<Breadcrumb>()

  var isEmpty: Bool { return breadcrumbs.isEmpty }

  /**
  generate

  - returns: IndexingGenerator<[Breadcrumb]>
  */
  func generate() -> AnyGenerator<Breadcrumb> { return breadcrumbs.generate() }

  /**
  append:to:velocity:ticks:

  - parameter from: CGPoint
  - parameter to: CGPoint
  - parameter velocity: CGVector
  - parameter ticks: MIDITimeStamp
  */
  mutating func append(from from: Snapshot, to: Snapshot) {
    guard !breadcrumbs.isEmpty || from == initialSnapshot else {
      fatalError("history must begin from initial snapshot")
    }
    breadcrumbs.insert(Breadcrumb(from: from, to: to))
  }

  /**
  pruneAfter:

  - parameter breadcrumb: Breadcrumb
  */
  mutating func pruneAfter(snapshot: Snapshot) {

    guard let breadcrumb = breadcrumbs.find({$0.tickInterval.end < snapshot.ticks},
                                            {$0.tickInterval ∋ snapshot.ticks}) else
    {
      fatalError("failed to location existing breadcrumb for snapshot: \(snapshot)")
    }

    guard let predecessor = breadcrumbs.find({$0.tickInterval.end < breadcrumb.tickInterval.start},
                                             {$0.tickInterval.end == breadcrumb.tickInterval.start}) else
    {
      breadcrumbs = [breadcrumb]
      return
    }
    breadcrumbs.dropAfter(predecessor)
    breadcrumbs.insert(Breadcrumb(from: breadcrumb.from, to: snapshot))

  }

  /**
  snapshotForTicks:

  - parameter ticks: MIDITimeStamp

  - returns: Snapshot
  */
  func snapshotForTicks(ticks: MIDITimeStamp) -> Snapshot {
    guard let breadcrumb = breadcrumbs.find({$0.tickInterval.end < ticks}, {$0.tickInterval ∋ ticks}) else {
      fatalError("failed to retrieve breadcrumb for ticks = \(ticks)")
    }
    return Snapshot(ticks: ticks, placement: Placement(position: breadcrumb.positionForTicks(ticks), vector: breadcrumb.velocity))
  }

  /**
  init:

  - parameter snapshot: Snapshot
  */
  init(initialSnapshot snapshot: Snapshot) { initialSnapshot = snapshot }
}

// MARK: - Breadcrumb
extension MIDINodeHistory {

  struct Breadcrumb {

    let from: Snapshot
    let to: Snapshot

    /**
    init:to:

    - parameter f: MIDINode.Snapshot
    - parameter t: MIDINode.Snapshot
    */
    init(from f: Snapshot, to t: Snapshot) {
      guard f < t else { fatalError("Breadcrumb requires 'to.ticks' is greater than 'from.tricks'") }
      from = f
      to = t
      tickInterval = from.ticks ... to.ticks
      velocity = f.velocity
      𝝙ticks = t.ticks - f.ticks
      𝝙seconds = CGFloat(Sequencer.secondsPerTick) * CGFloat(𝝙ticks)
      𝝙meters = velocity * 𝝙seconds
      𝝙position = t.position - f.position
    }

    let velocity: CGVector
    let 𝝙ticks: MIDITimeStamp
    let 𝝙seconds: CGFloat
    let 𝝙meters: CGVector
    let 𝝙position: CGPoint
    let tickInterval: ClosedInterval<MIDITimeStamp>

    /**
    positionForTicks:

    - parameter ticks: MIDITimeStamp

    - returns: CGPoint
    */
    func positionForTicks(ticks: MIDITimeStamp) -> CGPoint {
      guard tickInterval ∋ ticks else { fatalError("\(tickInterval) ∌ \(ticks)") }
      let 𝝙ticksʹ = ticks - from.ticks
      let 𝝙metersʹ = 𝝙meters * CGFloat(Double(𝝙ticksʹ) / Double(𝝙ticks))
      var position = from.position + (𝝙metersʹ * (𝝙position / 𝝙meters))
      if isnan(position.x) { position.x = from.position.x }
      if isnan(position.y) { position.y = from.position.y }
      return position
    }
  }

}

// MARK: - Snapshot
extension MIDINodeHistory {

  struct Snapshot {
    let ticks: MIDITimeStamp
    let placement: Placement
    var position: CGPoint { return placement.position }
    var velocity: CGVector { return placement.vector }

    /**
    init:position:velocity:

    - parameter t: MIDITimeStamp
    - parameter p: CGPoint
    - parameter v: CGVector
    */
    init(ticks t: MIDITimeStamp, position p: CGPoint, velocity v: CGVector) {
      ticks = t; placement = Placement(position: p, vector: v)
    }

    /**
    init:placement:

    - parameter t: MIDITimeStamp
    - parameter p: Placement
    */
    init(ticks t: MIDITimeStamp, placement p: Placement) { ticks = t; placement = p }
  }

}

// MARK: - Internal type protocol conformances
extension MIDINodeHistory.Breadcrumb: CustomStringConvertible {
  var description: String { return String(tickInterval) }
}
extension MIDINodeHistory.Breadcrumb: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

extension MIDINodeHistory.Breadcrumb: Comparable {}

func ==(lhs: MIDINodeHistory.Breadcrumb, rhs: MIDINodeHistory.Breadcrumb) -> Bool {
  return lhs.from.ticks == rhs.from.ticks
}

func <(lhs: MIDINodeHistory.Breadcrumb, rhs: MIDINodeHistory.Breadcrumb) -> Bool {
  return lhs.from.ticks < rhs.from.ticks
}

extension MIDINodeHistory: CustomStringConvertible {
  var description: String {
    var result = "MIDINodeHistory {\n"
    result += "  initialSnapshot: \(initialSnapshot)\n"
    result += "  breadcrumbs: {\n"
    result += ",\n".join(breadcrumbs.map({$0.description.indentedBy(4)}))
    result += "\n  }"
    result += "\n}"
    return result
  }
}

extension MIDINodeHistory: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}

extension MIDINodeHistory.Snapshot: Comparable {}

func ==(lhs: MIDINodeHistory.Snapshot, rhs: MIDINodeHistory.Snapshot) -> Bool {
  return lhs.ticks == rhs.ticks
}

func <(lhs: MIDINodeHistory.Snapshot, rhs: MIDINodeHistory.Snapshot) -> Bool {
  return lhs.ticks < rhs.ticks
}

extension MIDINodeHistory.Snapshot: CustomStringConvertible {
  var description: String {
    var result = "Snapshot { "
    result += "; ".join(
      "ticks: \(ticks)",
      "position: \(position.description(3))",
      "velocity: \(velocity.description(3))"
    )
    result += " }"
    return result
  }
}

extension MIDINodeHistory.Snapshot: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, &result); return result }
}