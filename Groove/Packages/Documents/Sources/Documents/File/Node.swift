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
import Sequencer

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
public extension File
{
  /// A type for encapsulating all the necessary data for adding and removing a `Node`.
  struct Node: LosslessJSONValueConvertible
  {
    /// Use the identifier type utilized by midi node events.
    public typealias Identifier = NodeEvent.Identifier
    
    /// The type for encapsulating initial angle and velocity data.
    public typealias Trajectory = Sequencer.Node.Trajectory
    
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
    
    /// A JSON object with values for keys 'identifier', 'generator',
    /// 'trajectory', 'addTime', and 'removeTime'.
    public var jsonValue: JSONValue
    {
      .object([
        "identifier": identifier.jsonValue,
        "generator": generator.jsonValue,
        "trajectory": trajectory.jsonValue,
        "addTime": .string(addTime.rawValue),
        "removeTime": removeTime != nil ? .string(removeTime!.rawValue) : .null
      ])
    }
    
    /// Initializing with a JSON value.
    ///
    /// - Parameters:
    ///   - jsonValue: To be successful `jsonValue` must be a JSON object with entries
    ///                for 'identifier', 'trajectory', 'generator', and 'addTime'. The
    ///                object may optionally include an entry for 'removeTime'.
    public init?(_ jsonValue: JSONValue?)
    {
      // Extract the identifier, trajectory, generator, and add time values.
      guard let dict = ObjectJSONValue(jsonValue),
            let identifier = Identifier(dict["identifier"]),
            let trajectory = Node.Trajectory(dict["trajectory"]),
            let generator = AnyGenerator(dict["generator"]),
            let addTime = BarBeatTime(rawValue: dict["addTime"]?.value as? String ?? "")
      else
      {
        return nil
      }
      
      // Intialize the corresponding property for each value extracted from the object.
      self.identifier = identifier
      self.generator = generator
      self.trajectory = trajectory
      self.addTime = addTime
      
      // Extract the remove time value.
      switch dict["removeTime"]
      {
        case let .string(s)?:
          // The JSON object contains an entry for node's remove time,
          // use it to initialize `removeTime`.
          
          removeTime = BarBeatTime(rawValue: s)
          
        case .null?:
          // The JSON object contains an entry for the node's remove time
          // specifying a null value.
          
          fallthrough
          
        default:
          // The JSON object does not contain an entry for the node's remove time.
          
          removeTime = nil
      }
    }
  }
}
