//
//  Loop.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/18/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import MIDI

// TODO: Review file

/// A class that stores a sequence of MIDI events along with start and stop times for
/// beginning playback of the sequence and the total number of times the sequence should
/// be played.
final class Loop: Swift.Sequence, MIDINodeDispatch, CustomStringConvertible {

  /// The amount of time from `start` to `end` or `zero` if the loop has no end.
  var time: BarBeatTime { return Swift.min(end - start, BarBeatTime.zero) }

  /// The number of times to dispatch the loop's events. Setting the value of this 
  /// property to `0` causes the loop to repeat itself indefinitely.
  var repetitions: Int = 0

  /// The number of MIDI clock ticks that should elapse between the final event dispatch
  /// and the event dispatch that begins the next repetition.
  var repeatDelay: UInt64 = 0

  /// The collection containing the loop's events.
  var eventContainer: MIDIEventContainer

  /// The dispatch time for the first event in the loop.
  var start: BarBeatTime = BarBeatTime.zero

  /// The dispatch time for the last event in the loop.
  var end: BarBeatTime = BarBeatTime.zero

  /// Uniquely identifies the loop across application launches.
  let identifier: UUID

  /// The queue used for dispatching the loop's MIDI events.
  var eventQueue: DispatchQueue { return track.eventQueue }

  /// Manages MIDI nodes dispatched by the loop.
  private(set) var nodeManager: MIDINodeManager!

  /// The set of dispatched nodes.
  var nodes: OrderedSet<HashableTuple<BarBeatTime, MIDINodeRef>> = []

  /// The instrument track that owns the loop.
  unowned let track: InstrumentTrack

  /// The color associated with the loop. This property returns the track's color.
  var color: TrackColor { return track.color }

  var isRecording: Bool {
    return Sequencer.mode == .loop && MIDINodePlayer.currentDispatch === self
  }

  var nextNodeName: String { return "\(name) \(nodes.count + 1)" }

  /// The name of the loop, composed of the track's display name and the identifier.
  var name: String { return "\(track.displayName) (\(identifier.uuidString))" }

  /// Uses `track` to connect `node`.
  func connect(node: MIDINode) throws { try track.connect(node: node) }

  /// Uses `track` to disconnect `node`.
  func disconnect(node: MIDINode) throws { try track.disconnect(node: node) }

  /// 'Marker' meta event in the following format:<br>
  ///      `start(`*identifier*`):`*repetitions*`:`*repeatDelay*
  var beginLoopEvent: MIDIEvent {

    // Create the text to use for the marker.
    let text = "start(\(identifier.uuidString)):\(repetitions):\(repeatDelay)"

    // Return a marker meta event containing `text`.
    return .meta(MetaEvent(data: .marker(name: text)))

  }

  /// 'Marker' meta event in the following format:<br>
  ///      `end(`*identifier*`)`
  var endLoopEvent: MIDIEvent {

    // Create the text to use for the marker.
    let text = "end(\(identifier.uuidString))"

    // Return a marker meta event containing `text`.
    return .meta(MetaEvent(data: .marker(name: text)))

  }

  /// Initializing with a track. The loop is assigned to the specified track. The loop is
  /// provided a new identifier and an empty event container.
  init(track: InstrumentTrack) {

    // Initialize `track` with the specified instrument track.
    self.track = track

    // Initialize `identifier` with a new UUID.
    identifier = UUID()

    // Initialize `eventContainer` with an empty container.
    eventContainer = MIDIEventContainer()

    // Initialize `nodeManager` with a new instance owned by the loop.
    nodeManager = MIDINodeManager(owner: self)

  }

  /// Iniitializing with a loop from a Groove file and a track. The loop is assigned to the
  /// specified track. The values for `identifier`, `repetitions`, `repeatDelay`, and 
  /// `start` are retrieved from `grooveLoop`.
  init(grooveLoop: GrooveFile.Loop, track: InstrumentTrack) {

    // Initialize `track` with the specified instrument track.
    self.track = track

    // Initialize `identifier` with the value provided by `grooveLoop`.
    identifier = grooveLoop.identifier

    // Initialize `repetitions` with the value provided by `grooveLoop`.
    repetitions = grooveLoop.repetitions

    // Initialize `repeatDelay` with the value provided by `grooveLoop`.
    repeatDelay = grooveLoop.repeatDelay

    // Initialize `start` with the value provided by `grooveLoop`.
    start = grooveLoop.start

    // Create an array for accumulating the loop's MIDI events.
    fatalError("\(#fileID) \(#function) Not yet implemented")
    var events: [MIDIEvent] = []


    // Iterate the nodes in `grooveLoop`.
//    for node in grooveLoop.nodes.values {
//
//      // Append a `MIDINodeEvent` that adds the node.
//      events.append(.node(node.addEvent))
//
//      // Get the node's remove event.
//      if let removeEvent = node.removeEvent {
//
//        // Append a `MIDINodeEvent` that removes the node.
//        events.append(.node(removeEvent))
//
//      }
//
//    }

    // Initialize `eventContainer` with the array of node events.
    self.eventContainer = MIDIEventContainer(events: events)

    // Initialize `nodeManager` with a new instance owned by the loop.
    nodeManager = MIDINodeManager(owner: self)

  }

  /// Returns the bar beat times to register with the transport's time for dispatching
  /// `events`.
  func registrationTimes<Source>(forAdding events: Source) -> [BarBeatTime]
    where Source:Swift.Sequence, Source.Iterator.Element == MIDIEvent
  {
    fatalError("\(#fileID) \(#function) Not yet implemented")
    // Return the times for the MIDI node events found in `events`.
//    return events.filter({
//      if case .node(_) = $0 { return true }
//      else { return false }
//    }).map({$0.time})

  }

  /// Dispatches `event` via the loop's node manager.
  func dispatch(event: MIDIEvent) {

    fatalError("\(#fileID) \(#function) Not yet implemented")

    // Get the node event wrapped by `event`.
//    guard case .node(let nodeEvent) = event else { return }

    // Delegate to the node manager to perform actual event handling.
//    nodeManager.handle(event: nodeEvent)

  }

  /// Returns an iterator over the loop's MIDI events.
  func makeIterator() -> AnyIterator<MIDIEvent> {

    var startEventInserted = false
    var endEventInserted = false

    var iteration = 0
    var offset: UInt64 = 0

    var currentGenerator = eventContainer.makeIterator()

    return AnyIterator {
      [
        startTicks = start.ticks,
        repeatCount = repetitions,
        totalTicks = time.ticks,
        delay = repeatDelay,
        beginEvent = beginLoopEvent,
        endEvent = endLoopEvent
      ]
      () -> MIDIEvent? in

      if !startEventInserted {
        startEventInserted = true
        var event = beginEvent
        event.time = BarBeatTime(tickValue: startTicks)
        return event
      }

      else if var event = currentGenerator.next() {
        event.time = BarBeatTime(tickValue: startTicks + event.time.ticks + offset)
        return event
      }

      else if    repeatCount >= {let i = iteration; iteration += 1; return i}()
              || repeatCount < 0
      {
        offset += delay + totalTicks
        currentGenerator = self.eventContainer.makeIterator()

        if var event = currentGenerator.next() {

          event.time = BarBeatTime(tickValue: startTicks + event.time.ticks + offset)
          return event

        }

        else if !endEventInserted {

          endEventInserted = true
          var event = endEvent
          event.time = BarBeatTime(tickValue: startTicks + event.time.ticks + offset)
          return event

        }

        else {

          return nil

        }

      }

      else if !endEventInserted {

        endEventInserted = true
        var event = endEvent
        event.time = BarBeatTime(tickValue: startTicks + event.time.ticks + offset)
        return event

      }

      else {

        return nil

      }

    }

  }

  var description: String {

    return [
      "time: \(time)",
      "repetitions: \(repetitions)",
      "repeatDelay: \(repeatDelay)",
      "start: \(start)",
      "end: \(end)",
      "identifier: \(identifier)",
      "color: \(color)",
      "isRecording: \(isRecording)",
      "name: \(name)",
      "nodes: \(nodes)",
      "events: \(eventContainer)"
    ].joined(separator: "\n")

  }
  
}
