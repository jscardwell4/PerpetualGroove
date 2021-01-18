//
//  Loop.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/18/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Common
import Foundation
import MIDI
import MoonDev

// MARK: - Loop

/// A class that stores a sequence of MIDI events along with start and stop times for
/// beginning playback of the sequence and the total number of times the sequence should
/// be played.
@available(iOS 14.0, *)
public final class Loop: NodeDispatch
{
  // MARK: Stored Properties

  /// The number of times to dispatch the loop's events. Setting the value of this
  /// property to `0` causes the loop to repeat itself indefinitely.
  public var repetitions: Int = 0

  /// The number of MIDI clock ticks that should elapse between the final event dispatch
  /// and the event dispatch that begins the next repetition.
  public var repeatDelay: UInt64 = 0

  /// The collection containing the loop's events.
  public var eventContainer: EventContainer

  /// The dispatch time for the first event in the loop.
  public var start: BarBeatTime = .zero

  /// The dispatch time for the last event in the loop.
  public var end: BarBeatTime = .zero

  /// Uniquely identifies the loop across application launches.
  public let identifier: UUID

  /// Manages MIDI nodes dispatched by the loop.
  public private(set) lazy var nodeManager = NodeManager(owner: self)

  /// The set of dispatched nodes.
  public var nodes: OrderedSet<HashableTuple<BarBeatTime, NodeRef>> = []

  /// The instrument track that owns the loop.
  public unowned let track: InstrumentTrack

  // MARK: Computed Properties

  /// The amount of time from `start` to `end` or `zero` if the loop has no end.
  public var time: BarBeatTime { Swift.min(end - start, BarBeatTime.zero) }

  /// The queue used for dispatching the loop's MIDI events.
  public var eventQueue: DispatchQueue { track.eventQueue }

  /// The color associated with the loop. This property returns the track's color.
  public var color: Track.Color { track.color }

  public var isRecording: Bool
  {
    sequencer.mode == .loop && player.currentDispatch === self
  }

  public var nextNodeName: String { "\(name) \(nodes.count + 1)" }

  /// The name of the loop, composed of the track's display name and the identifier.
  public var name: String { "\(track.displayName) (\(identifier.uuidString))" }

  /// 'Marker' meta event in the following format:<br>
  ///      `start(`*identifier*`):`*repetitions*`:`*repeatDelay*
  public var beginLoopEvent: Event
  {
    // Create the text to use for the marker.
    let text = "start(\(identifier.uuidString)):\(repetitions):\(repeatDelay)"

    // Return a marker meta event containing `text`.
    return .meta(MetaEvent(data: .marker(name: text)))
  }

  /// 'Marker' meta event in the following format:<br>
  ///      `end(`*identifier*`)`
  public var endLoopEvent: Event
  {
    // Create the text to use for the marker.
    let text = "end(\(identifier.uuidString))"

    // Return a marker meta event containing `text`.
    return .meta(MetaEvent(data: .marker(name: text)))
  }

  // MARK: Event Dispatch

  public func add<S>(events: S) where S: Swift.Sequence, S.Element == Event
  {
    eventContainer.append(contentsOf: events)
    sequencer.time.register(callback: weakCapture(of: self,
                                                  block: type(of: self).dispatchEvents),
                            forTimes: registrationTimes(forAdding: events),
                            identifier: UUID())
  }

  /// Returns the bar beat times to register with the transport's time for dispatching
  /// `events`.
  public func registrationTimes<Source>(forAdding events: Source) -> [BarBeatTime]
  where Source: Swift.Sequence, Source.Iterator.Element == Event
  {
    // Return the times for the MIDI node events found in `events`.
    return events.filter
    {
      if case .node = $0 { return true }
      else { return false }
    }.map { $0.time }
  }

  /// Dispatches `event` via the loop's node manager.
  public func dispatch(event: Event)
  {
    // Get the node event wrapped by `event`.
    guard case let .node(nodeEvent) = event else { return }

    // Delegate to the node manager to perform actual event handling.
    nodeManager.handle(event: nodeEvent)
  }

  // MARK: Node Dispatch

  /// Uses `track` to connect `node`.
  public func connect(node: Node) throws { try track.connect(node: node) }

  /// Uses `track` to disconnect `node`.
  public func disconnect(node: Node) throws { try track.disconnect(node: node) }

  /// Initializing with a track. The loop is assigned to the specified track. The
  /// loop is provided a new identifier and an empty event container.
  public init(track: InstrumentTrack)
  {
    // Initialize `track` with the specified instrument track.
    self.track = track

    // Initialize `identifier` with a new UUID.
    identifier = UUID()

    // Initialize `eventContainer` with an empty container.
    eventContainer = EventContainer()
  }

  // MARK: Initializing

  /// Initializing with existing values.
  ///
  /// - Parameters:
  ///   - identifier: The unique identifier.
  ///   - track: The instrument track.
  ///   - repetitions: The number of repetitions.
  ///   - repeatDelay: The repeat delay.
  ///   - start: The start time.
  ///   - events: The existing MIDI events.
  public init(identifier: UUID,
              track: InstrumentTrack,
              repetitions: Int,
              repeatDelay: UInt64,
              start: BarBeatTime,
              events: [Event])
  {
    self.identifier = identifier
    self.track = track
    self.repetitions = repetitions
    self.repeatDelay = repeatDelay
    self.start = start
    eventContainer = EventContainer(events: events)
  }
}

// MARK: Swift.Sequence

@available(iOS 14.0, *)
extension Loop: Swift.Sequence
{
  /// Returns an iterator over the loop's MIDI events.
  public func makeIterator() -> AnyIterator<Event>
  {
    var startEventInserted = false
    var endEventInserted = false

    var iteration = 0
    var offset: UInt64 = 0

    var currentGenerator = eventContainer.makeIterator()

    return AnyIterator
    {
      [
        startTicks = start.ticks,
        repeatCount = repetitions,
        totalTicks = time.ticks,
        delay = repeatDelay,
        beginEvent = beginLoopEvent,
        endEvent = endLoopEvent
      ]
      () -> Event? in

      if !startEventInserted
      {
        startEventInserted = true
        var event = beginEvent
        event.time = BarBeatTime(tickValue: startTicks)
        return event
      }

      else if var event = currentGenerator.next()
      {
        event.time = BarBeatTime(tickValue: startTicks + event.time.ticks + offset)
        return event
      }

      else if repeatCount >= { let i = iteration; iteration += 1; return i }()
                || repeatCount < 0
      {
        offset += delay + totalTicks
        currentGenerator = self.eventContainer.makeIterator()

        if var event = currentGenerator.next()
        {
          event.time = BarBeatTime(tickValue: startTicks + event.time.ticks + offset)
          return event
        }

        else if !endEventInserted
        {
          endEventInserted = true
          var event = endEvent
          event.time = BarBeatTime(tickValue: startTicks + event.time.ticks + offset)
          return event
        }

        else
        {
          return nil
        }
      }

      else if !endEventInserted
      {
        endEventInserted = true
        var event = endEvent
        event.time = BarBeatTime(tickValue: startTicks + event.time.ticks + offset)
        return event
      }

      else
      {
        return nil
      }
    }
  }
}

// MARK: CustomStringConvertible

@available(iOS 14.0, *)
extension Loop: CustomStringConvertible
{
  public var description: String
  {
    """
    time: \(time)
    repetitions: \(repetitions)
    repeatDelay: \(repeatDelay)
    start: \(start)
    end: \(end)
    identifier: \(identifier)
    color: \(color)
    isRecording: \(isRecording)
    name: \(name)
    nodes: \(nodes)
    events: \(eventContainer)
    """
  }
}
