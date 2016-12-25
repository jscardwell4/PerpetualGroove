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

struct MIDINodeHistory: Swift.Sequence, CustomStringConvertible {

  let initialSnapshot: Snapshot

  fileprivate var breadcrumbs = Tree<Breadcrumb>()

  var isEmpty: Bool { return breadcrumbs.isEmpty }

  func makeIterator() -> AnyIterator<Breadcrumb> { return breadcrumbs.makeIterator() }

  mutating func append(from: Snapshot, to: Snapshot) {
    guard !breadcrumbs.isEmpty || from == initialSnapshot else {
      fatalError("history must begin from initial snapshot")
    }
    breadcrumbs.insert(Breadcrumb(from: from, to: to))
  }

 mutating func prune(after snapshot: Snapshot) {

    guard let breadcrumb = breadcrumbs.find({$0.tickInterval.upperBound < snapshot.ticks},
                                            {$0.tickInterval.contains(snapshot.ticks)}) else
    {
      fatalError("failed to location existing breadcrumb for snapshot: \(snapshot)")
    }

    guard let predecessor = breadcrumbs.find({$0.tickInterval.upperBound < breadcrumb.tickInterval.lowerBound},
                                             {$0.tickInterval.upperBound == breadcrumb.tickInterval.lowerBound})
      else
    {
      breadcrumbs = [breadcrumb]
      return
    }
    breadcrumbs.dropAfter(predecessor)
    breadcrumbs.insert(Breadcrumb(from: breadcrumb.from, to: snapshot))

  }

  func snapshot(for ticks: MIDITimeStamp) -> Snapshot? {
    guard let breadcrumb = breadcrumbs.find({$0.tickInterval.upperBound < ticks},
                                            {$0.tickInterval.contains(ticks)})
      else
    {
      Log.warning("failed to locate breadcrumb for ticks '\(ticks)' in breadcrumbs \(breadcrumbs)",
        asynchronous: false)
      return nil
    }
    let trajectory = MIDINode.Trajectory(vector: breadcrumb.velocity, point: breadcrumb.position(for: ticks))
    return Snapshot(ticks: ticks, trajectory: trajectory)
  }

  init(initialSnapshot snapshot: Snapshot) { initialSnapshot = snapshot }


  var description: String {
    var result = "MIDINodeHistory {\n"
    result += "  initialSnapshot: \(initialSnapshot)\n"
    result += "  breadcrumbs: {\n"
    result += ",\n".join(breadcrumbs.map({$0.description.indented(by: 4)}))
    result += "\n  }"
    result += "\n}"
    return result
  }

}

extension MIDINodeHistory {

  struct Breadcrumb: Comparable, CustomStringConvertible {

    let from: Snapshot
    let to: Snapshot

    init(from: Snapshot, to: Snapshot) {
      guard from < to else { fatalError("Breadcrumb requires 'to.ticks' is greater than 'from.tricks'") }
      self.from = from
      self.to = to
      tickInterval = from.ticks ... to.ticks
      velocity = from.trajectory.v
      𝝙ticks = to.ticks - from.ticks
      𝝙seconds = CGFloat(MIDIClock.current.secondsPerTick) * CGFloat(𝝙ticks)
      𝝙meters = velocity * 𝝙seconds
      𝝙position = to.trajectory.p - from.trajectory.p
    }

    let velocity: CGVector
    let 𝝙ticks: MIDITimeStamp
    let 𝝙seconds: CGFloat
    let 𝝙meters: CGVector
    let 𝝙position: CGPoint
    let tickInterval: ClosedRange<MIDITimeStamp>

    func position(for ticks: MIDITimeStamp) -> CGPoint {
      guard tickInterval.contains(ticks) else { fatalError("\(tickInterval) ∌ \(ticks)") }
      let 𝝙ticksʹ = ticks - from.ticks
      let 𝝙metersʹ = 𝝙meters * CGFloat(Double(𝝙ticksʹ) / Double(𝝙ticks))
      var position = from.trajectory.p + (𝝙metersʹ * (𝝙position / 𝝙meters))
      if position.x.isNaN { position.x = from.trajectory.p.x }
      if position.y.isNaN { position.y = from.trajectory.p.y }
      return position
    }

    var description: String { return tickInterval.description }

    static func ==(lhs: Breadcrumb, rhs: Breadcrumb) -> Bool {
      return lhs.from.ticks == rhs.from.ticks
    }

    static func <(lhs: Breadcrumb, rhs: Breadcrumb) -> Bool {
      return lhs.from.ticks < rhs.from.ticks
    }

  }

}

extension MIDINodeHistory {

  struct Snapshot: Comparable, CustomStringConvertible {

    let ticks: MIDITimeStamp
    let trajectory: MIDINode.Trajectory

    init(ticks: MIDITimeStamp, position: CGPoint, velocity: CGVector) {
      self.init(ticks: ticks, trajectory: MIDINode.Trajectory(vector: velocity, point: position))
    }

    init(ticks: MIDITimeStamp, trajectory: MIDINode.Trajectory) {
      self.ticks = ticks
      self.trajectory = trajectory
    }

    static func ==(lhs: Snapshot, rhs: Snapshot) -> Bool {
      return lhs.ticks == rhs.ticks
    }

    static func <(lhs: Snapshot, rhs: Snapshot) -> Bool {
      return lhs.ticks < rhs.ticks
    }

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

}
