//
//  Node.swift
//  Documents
//
//  Created by Jason Cardwell on 01/06/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MIDI
import MoonDev
import Sequencing

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
extension File
{
  /// A type for encapsulating all the necessary data for adding and removing a `Node`.
  public struct Node: Codable
  {
    /// Use the identifier type utilized by midi node events.
    public typealias Identifier = NodeEvent.Identifier

    /// The type for encapsulating initial angle and velocity data.
    public typealias Trajectory = MIDINode.Trajectory

    /// Typealias for the midi event kind utilized by `Node`.
    public typealias Event = NodeEvent

    /// The unique identifier for the node within its track.
    public let identifier: Identifier

    /// The node's initial trajectory.
    public var trajectory: Node.Trajectory

    /// The node's generator
    public var generator: AnyGenerator

    /// The bar beat time at which point the node is added to the player.
    public var addTime: BarBeatTime

    /// The bar beat time at which point the node is removed from the player.
    /// A `nil` value for this property indicates that the node is never removed
    /// from the player.
    public var removeTime: BarBeatTime?
    {
      didSet
      {
        // Check that `removeTime` is invalid.
        guard removeTime != nil, removeTime! < addTime else { return }

        // Clear the invalid time.
        removeTime = nil
      }
    }

    /// The event for adding the node to the player.
    public var addEvent: Event
    {
      // Return an add event with node's identifier, trajectory, generator, and add time.
      Event(data: .add(identifier: identifier,
                       trajectory: trajectory,
                       generator: generator),
            time: addTime)
    }

    /// The event for removing the node from the player or `nil` if `removeTime == nil`.
    public var removeEvent: Event?
    {
      // Get the remove time.
      guard let removeTime = removeTime else { return nil }

      // Return a remove event with the node's identifier and remove time.
      return Event(data: .remove(identifier: identifier), time: removeTime)
    }

    /// Initializing with a node event.
    /// - Parameter event: To be successful the event must be an add event.
    public init?(event: Event)
    {
      // Extract the identifier, trajectory and generator from the event's data.
      guard case let .add(identifier, trajectory, generator) = event.data
      else
      {
        return nil
      }

      // Initialize the node's properties.
      addTime = event.time
      self.identifier = identifier
      self.trajectory = trajectory
      self.generator = generator
    }

    private enum CodingKeys: String, CodingKey
    {
      case identifier, generator, trajectory, addTime, removeTime
    }

    public func encode(to encoder: Encoder) throws
    {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(identifier, forKey: .identifier)
      try container.encode(generator, forKey: .generator)
      try container.encode(trajectory, forKey: .trajectory)
      try container.encode(addTime, forKey: .addTime)
      try container.encode(removeTime, forKey: .removeTime)
    }

    public init(from decoder: Decoder) throws
    {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      identifier = try container.decode(Identifier.self, forKey: .identifier)
      generator = try container.decode(AnyGenerator.self, forKey: .generator)
      trajectory = try container.decode(Trajectory.self, forKey: .trajectory)
      addTime = try container.decode(BarBeatTime.self, forKey: .addTime)
      removeTime = try container.decode(BarBeatTime?.self, forKey: .removeTime)
    }
  }
}
