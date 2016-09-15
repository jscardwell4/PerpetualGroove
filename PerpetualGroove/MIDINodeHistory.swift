//
//  MIDINodeHistory.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGVector
import struct CoreGraphics.CGFloat
import typealias AudioToolbox.MIDITimeStamp

struct MIDINodeHistory: Swift.Sequence {

  let initialSnapshot: Snapshot

  fileprivate var breadcrumbs = Tree<Breadcrumb>()

  var isEmpty: Bool { return breadcrumbs.isEmpty }

  /**
  generate

  - returns: IndexingGenerator<[Breadcrumb]>
  */
  func makeIterator() -> AnyIterator<Breadcrumb> { return breadcrumbs.makeIterator() }

  /**
  append:to:velocity:ticks:

  - parameter from: CGPoint
  - parameter to: CGPoint
  - parameter velocity: CGVector
  - parameter ticks: MIDITimeStamp
  */
  mutating func append(from: Snapshot, to: Snapshot) {
    guard !breadcrumbs.isEmpty || from == initialSnapshot else {
      fatalError("history must begin from initial snapshot")
    }
    breadcrumbs.insert(Breadcrumb(from: from, to: to))
  }

  /**
  pruneAfter:

  - parameter breadcrumb: Breadcrumb
  */
  mutating func pruneAfter(_ snapshot: Snapshot) {

    guard let breadcrumb = breadcrumbs.find({$0.tickInterval.upperBound < snapshot.ticks},
                                            {$0.tickInterval.contains(snapshot.ticks)}) else
    {
      fatalError("failed to location existing breadcrumb for snapshot: \(snapshot)")
    }

    guard let predecessor = breadcrumbs.find({$0.tickInterval.upperBound < breadcrumb.tickInterval.lowerBound},
                                             {$0.tickInterval.upperBound == breadcrumb.tickInterval.lowerBound}) else
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
  func snapshotForTicks(_ ticks: MIDITimeStamp) -> Snapshot? {
    guard let breadcrumb = breadcrumbs.find({$0.tickInterval.upperBound < ticks}, {$0.tickInterval.contains(ticks)}) else {
      logSyncWarning("failed to locate breadcrumb for ticks '\(ticks)' in breadcrumbs \(breadcrumbs)")
      return nil
    }
    let trajectory = Trajectory(vector: breadcrumb.velocity, point: breadcrumb.positionForTicks(ticks))
    return Snapshot(ticks: ticks, trajectory: trajectory)
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
      velocity = f.trajectory.v
      𝝙ticks = t.ticks - f.ticks
      𝝙seconds = CGFloat(Sequencer.secondsPerTick) * CGFloat(𝝙ticks)
      𝝙meters = velocity * 𝝙seconds
      𝝙position = t.trajectory.p - f.trajectory.p
    }

    let velocity: CGVector
    let 𝝙ticks: MIDITimeStamp
    let 𝝙seconds: CGFloat
    let 𝝙meters: CGVector
    let 𝝙position: CGPoint
    let tickInterval: ClosedRange<MIDITimeStamp>

    /**
    positionForTicks:

    - parameter ticks: MIDITimeStamp

    - returns: CGPoint
    */
    func positionForTicks(_ ticks: MIDITimeStamp) -> CGPoint {
      guard tickInterval.contains(ticks) else { fatalError("\(tickInterval) ∌ \(ticks)") }
      let 𝝙ticksʹ = ticks - from.ticks
      let 𝝙metersʹ = 𝝙meters * CGFloat(Double(𝝙ticksʹ) / Double(𝝙ticks))
      var position = from.trajectory.p + (𝝙metersʹ * (𝝙position / 𝝙meters))
      if position.x.isNaN { position.x = from.trajectory.p.x }
      if position.y.isNaN { position.y = from.trajectory.p.y }
      return position
    }
  }

}

// MARK: - Snapshot
extension MIDINodeHistory {

  struct Snapshot {
    let ticks: MIDITimeStamp
    let trajectory: Trajectory

    /**
    init:position:velocity:

    - parameter t: MIDITimeStamp
    - parameter p: CGPoint
    - parameter v: CGVector
    */
    init(ticks t: MIDITimeStamp, position p: CGPoint, velocity v: CGVector) {
      ticks = t; trajectory = Trajectory(vector: v, point: p)
    }

    /**
    init:trajectory:

    - parameter t: MIDITimeStamp
    - parameter p: Trajectory
    */
    init(ticks: MIDITimeStamp, trajectory: Trajectory) { self.ticks = ticks; self.trajectory = trajectory }
  }

}

// MARK: - Internal type protocol conformances
extension MIDINodeHistory.Breadcrumb: CustomStringConvertible {
  var description: String { return String(describing: tickInterval) }
}
extension MIDINodeHistory.Breadcrumb: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
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
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
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
      "position: \(trajectory.p.description(3))",
      "velocity: \(trajectory.v.description(3))"
    )
    result += " }"
    return result
  }
}

extension MIDINodeHistory.Snapshot: CustomDebugStringConvertible {
  var debugDescription: String { var result = ""; dump(self, to: &result); return result }
}
