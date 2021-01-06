//
//  NodeEvent.swift
//  Groove
//
//  Created by Jason Cardwell on 1/2/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import CoreGraphics
import Foundation
import MoonKit

// MARK: - NodeEvent

/// A MIDI meta event that uses the 'Cue Point' message to embed data for adding and
/// removing `Node` instances to and from the MIDI node player.
public struct NodeEvent: _Event, Hashable
{
  public var time = BarBeatTime.zero

  public var delta: UInt64?

  /// The event's data for adding or removing a MIDI node.
  public let data: Data

  public var bytes: [UInt8]
  {
    // Get the bytes for the event's data.
    let dataBytes = data.bytes

    // Create a variable length quantity for the data's length.
    let length = VariableLengthQuantity(dataBytes.count)

    // Create an array of bytes initialized with the 'FF' specifying a meta event and
    // '7' indicating a 'Cue Point' message.
    var bytes: [UInt8] = [0xFF, 0x07]

    // Append the bytes for the variable length quantity.
    bytes.append(contentsOf: length.bytes)

    // Append the bytes of data.
    bytes.append(contentsOf: dataBytes)

    // Return the array of bytes.
    return bytes
  }

  /// The unique node identifier specified in the event's `data`.
  public var identifier: Identifier
  {
    // Consider the data.
    switch data
    {
      case let .add(id, _, _),
           let .remove(id):
        // Return the data's identifier

        return id
    }
  }

  /// Wrapper for the `nodeIdentifier` property of `identifier`.
  public var nodeIdentifier: UUID { return identifier.nodeIdentifier }

  /// Wrapper for the `loopIdentifier` property of `identifier`.
  public var loopIdentifier: UUID? { return identifier.loopIdentifier }

  /// Initializing with data and a bar-beat time.
  ///
  /// - Parameters:
  ///   - data: The data for the new MIDI node event.
  ///   - time: The bar-beat time to use when initializing the MIDI node event's `time`
  ///           property. The default is `zero`.
  public init(data: Data, time: BarBeatTime = .zero)
  {
    // Initialize `data` with the specified data.
    self.data = data

    // Initialize `time` with the specified bar-beat time.
    self.time = time
  }

  public init(delta: UInt64, data: Foundation.Data.SubSequence) throws
  {
    self.delta = delta
    guard data[data.startIndex +--> 2].elementsEqual([0xFF, 0x07])
    else
    {
      throw File.Error.invalidHeader("Event must begin with `FF 07`")
    }

    var currentIndex = data.startIndex + 2

    var i = currentIndex
    while data[i] & 0x80 != 0 { i += 1 }

    let dataLength = Int(VariableLengthQuantity(bytes: data[currentIndex ... i]))

    currentIndex = i + 1

    i += dataLength + 1

    guard data.endIndex == i
    else
    {
      throw File.Error.invalidLength("Specified length does not match actual")
    }

    self.data = try Data(data: data[currentIndex ..< i])
  }

  public func hash(into hasher: inout Hasher)
  {
    time.hash(into: &hasher)
    delta?.hash(into: &hasher)
    data.hash(into: &hasher)
  }

  public static func == (lhs: NodeEvent, rhs: NodeEvent) -> Bool
  {
    return lhs.time == rhs.time && lhs.delta == rhs.delta && lhs.data == rhs.data
  }

  public var description: String { return "\(time) \(data)" }
}

public extension NodeEvent
{
  /// Type to encode and decode the bytes used to identify a MIDI node.
  struct Identifier: Hashable, LosslessJSONValueConvertible
  {
    public let loopIdentifier: UUID?
    public let nodeIdentifier: UUID

    public init(loopIdentifier: UUID? = nil, nodeIdentifier: UUID)
    {
      self.loopIdentifier = loopIdentifier
      self.nodeIdentifier = nodeIdentifier
    }

    public var bytes: [UInt8]
    {
      let nodeIdentifierBytes = {
        [$0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7,
         $0.8, $0.9, $0.10, $0.11, $0.12, $0.13, $0.14, $0.15]
      }(nodeIdentifier.uuid)

      if let loopIdentifier = loopIdentifier
      {
        let loopIdentifierBytes = {
          [$0.0, $0.1, $0.2, $0.3, $0.4, $0.5, $0.6, $0.7,
           $0.8, $0.9, $0.10, $0.11, $0.12, $0.13, $0.14, $0.15]
        }(loopIdentifier.uuid)

        return UInt32(16).bytes + loopIdentifierBytes + ":".bytes + nodeIdentifierBytes
      }
      else
      {
        return UInt32(0).bytes + ":".bytes + nodeIdentifierBytes
      }
    }

    public var length: UInt32 { return UInt32(bytes.count) }

    public init(data: Foundation.Data.SubSequence) throws
    {
      guard data.count >= 4
      else
      {
        throw File.Error.invalidLength("Not enough bytes for node event identifier")
      }

      var currentIndex = data.startIndex

      let loopIDByteCount = Int(UInt32(bytes: data[currentIndex +--> 4]))

      currentIndex += 4

      guard data.endIndex - currentIndex >= loopIDByteCount
      else
      {
        throw File.Error.invalidLength("Not enough bytes for node event identifier")
      }

      if loopIDByteCount == 16
      {
        loopIdentifier = UUID(
          uuid: data.withUnsafeBytes
          { (pointer: UnsafeRawBufferPointer) -> uuid_t in
            (pointer.baseAddress! + currentIndex).assumingMemoryBound(to: uuid_t.self).pointee
          }
        )
      }
      else
      {
        loopIdentifier = nil
      }

      currentIndex += loopIDByteCount

      guard String(data[currentIndex]) == ":"
      else
      {
        throw File.Error.fileStructurallyUnsound("Missing separator in node event identifier")
      }

      currentIndex += 1

      guard data.endIndex - currentIndex >= 16
      else
      {
        throw File.Error.invalidLength("Not enough bytes for node event identifier")
      }

      nodeIdentifier = UUID(
        uuid: data.withUnsafeBytes
        { (pointer: UnsafeRawBufferPointer) -> uuid_t in
          (pointer.baseAddress! + currentIndex).assumingMemoryBound(to: uuid_t.self).pointee
        }
      )
    }

    public var jsonValue: JSONValue
    {
      return ["nodeIdentifier": nodeIdentifier.uuidString.jsonValue,
              "loopIdentifier": loopIdentifier?.uuidString.jsonValue]
    }

    public init?(_ jsonValue: JSONValue?)
    {
      guard
        let dict = ObjectJSONValue(jsonValue),
        let nodeIdentifierString = String(dict["nodeIdentifier"]),
        let nodeIdentifier = UUID(uuidString: nodeIdentifierString)
      else
      {
        return nil
      }

      self.nodeIdentifier = nodeIdentifier

      if let loopIdentifierString = String(dict["loopIdentifier"]),
         let loopIdentifier = UUID(uuidString: loopIdentifierString)
      {
        self.loopIdentifier = loopIdentifier
      }
      else
      {
        loopIdentifier = nil
      }
    }

    public func hash(into hasher: inout Hasher)
    {
      nodeIdentifier.hash(into: &hasher)
      loopIdentifier?.hash(into: &hasher)
    }

    public static func == (lhs: Identifier, rhs: Identifier) -> Bool
    {
      return lhs.nodeIdentifier == rhs.nodeIdentifier && lhs.loopIdentifier == rhs.loopIdentifier
    }
  }
}

public extension NodeEvent
{
  enum Data: Hashable, CustomStringConvertible
  {
    case add(identifier: Identifier, trajectory: Trajectory, generator: AnyGenerator)
    case remove(identifier: Identifier)

    public init(data: Foundation.Data.SubSequence) throws
    {
      var currentIndex = data.startIndex

      let identifierByteCount = Int(UInt32(bytes: data[currentIndex +--> 4]))

      currentIndex += 4

      guard data.count >= identifierByteCount
      else
      {
        throw File.Error.invalidLength("Data length must at least cover length of identifier")
      }

      let identifier = try Identifier(data: data[currentIndex +--> identifierByteCount])

      currentIndex += identifierByteCount

      guard currentIndex != data.endIndex
      else
      {
        self = .remove(identifier: identifier)
        return
      }

      var i = currentIndex + Int(data[currentIndex]) + 1

      currentIndex += 1

      guard data.endIndex - i > 0
      else
      {
        throw File.Error.invalidLength("Not enough bytes for event")
      }

      let trajectory = Trajectory(bytes: data[currentIndex ..< i])
      guard trajectory != .null
      else
      {
        throw File.Error.fileStructurallyUnsound("Invalid trajectory data")
      }

      currentIndex = i + 1
      i += Int(data[i]) + 1

      guard data.endIndex - i == 0
      else
      {
        throw File.Error.invalidLength("Incorrect number of bytes")
      }

      self = .add(identifier: identifier,
                  trajectory: trajectory,
                  generator: .note(NoteGenerator(bytes: data[currentIndex ..< i])))
    }

    public var bytes: [UInt8]
    {
      switch self
      {
        case let .add(identifier, trajectory, generator):
          var bytes = identifier.length.bytes + identifier.bytes
          let trajectoryBytes = trajectory.bytes
          bytes.append(UInt8(trajectoryBytes.count))
          bytes += trajectoryBytes
          if case let .note(noteGenerator) = generator
          {
            let generatorBytes = noteGenerator.bytes
            bytes.append(UInt8(generatorBytes.count))
            bytes += generatorBytes
          }
          return bytes

        case let .remove(identifier): return identifier.bytes
      }
    }

    public var description: String
    {
      switch self
      {
        case let .add(identifier, trajectory, generator):
          return "add node '\(identifier)' (\(trajectory), \(generator))"
        case let .remove(identifier):
          return "remove node '\(identifier)'"
      }
    }

    public func hash(into hasher: inout Hasher)
    {
      switch self
      {
        case let .add(identifier, trajectory, generator):
          identifier.hash(into: &hasher)
          trajectory.hash(into: &hasher)
          generator.hash(into: &hasher)

        case let .remove(identifier):
          identifier.hash(into: &hasher)
      }
    }

    public static func == (lhs: Data, rhs: Data) -> Bool
    {
      switch (lhs, rhs)
      {
        case let (.add(identifier1, trajectory1, generator1),
                  .add(identifier2, trajectory2, generator2))
               where identifier1 == identifier2
               && trajectory1 == trajectory2
               && generator1 == generator2:
          return true
        case let (.remove(identifier1), .remove(identifier2))
              where identifier1 == identifier2:
          return true
        default:
          return false
      }
    }
  }
}

public extension NodeEvent
{
  /// Type for expressing velocity and angle from a point.
  struct Trajectory: Hashable, ByteArrayConvertible, LosslessJSONValueConvertible, CustomStringConvertible
  {
    /// The constant used to adjust the velocity units when calculating times
    public static let modifier: Fraction = 1÷1_000

    /// The slope of the trajectory (`dy` / `dx`)
    public var slope: CGFloat { return velocity.dy / velocity.dx }

    /// The velocity in units along the lines of those used by `SpriteKit`.
    public var velocity: CGVector

    /// The initial point
    public var position: CGPoint

    /// Initialize with known property values.
    public init(velocity: CGVector, position: CGPoint)
    {
      self.velocity = velocity
      self.position = position
    }

    /// The direction specified by the trajectory
    public var direction: Direction
    {
      get { return Direction(vector: velocity) }

      set
      {
        guard direction != newValue else { return }

        // Update the vertical component of `velocity`.
        switch (direction.vertical, newValue.vertical)
        {
          case (.up, .down),
               (.down, .up):
            // Changed direction of vertical movement, flip the sign of `velocity.dy`.

            velocity.dy.negate()

          case (_, .none):
            // No longer moving vertically, set `velocity.dy` to 0.

            velocity.dy = 0

          default:
            // No change to vertical movement.

            break
        }

        // Update the vertical component of `velocity`.
        switch (direction.horizontal, newValue.horizontal)
        {
          case (.left, .right),
               (.right, .left):
            // Changed direction of horizontal movement, flip the sign of `velocity.dx`.

            velocity.dx.negate()

          case (_, .none):
            // No longer moving horizontally, set `velocity.dx` to 0.

            velocity.dx = 0

          default:
            // No change to horizontal movement.

            break
        }
      }
    }

    /// Returns the trajectory angle value `angle`.
    public func withAngle(_ angle: CGFloat) -> Trajectory
    {
      var result = self
      result.angle = angle
      return result
    }

    /// The angle of the trajectory.
    public var angle: CGFloat {
      get { velocity.angle }
      set { velocity.angle = newValue }
    }

    /// Elapsed time in seconds between the specified points
    public func time(from p1: CGPoint, to p2: CGPoint) -> TimeInterval
    {
      let result = abs(TimeInterval(p1.distanceTo(p2) / slope)) * TimeInterval(Trajectory.modifier)

      guard result.isFinite else { fatalError("Invalid time: \(result)") }

      return result
    }

    /// The 'zero' trajectory.
    public static var zero: Trajectory { return Trajectory(velocity: .zero, position: .zero) }

    /// Trajectory value for representing a 'null' or 'invalid' trajectory
    public static var null: Trajectory { return Trajectory(velocity: CGVector.zero, position: CGPoint.null) }

    public func hash(into hasher: inout Hasher)
    {
      velocity.dx.hash(into: &hasher)
      velocity.dy.hash(into: &hasher)
      position.x.hash(into: &hasher)
      position.y.hash(into: &hasher)
    }

    /// Returns `true` iff the two trajectories have equal `velocity` and `position` values.
    public static func == (lhs: Trajectory, rhs: Trajectory) -> Bool
    {
      return lhs.velocity == rhs.velocity && lhs.position == rhs.position
    }

    /// The array of ascii character bytes as described in `init(_ bytes:)`.
    public var bytes: [UInt8]
    {
      return Array("{\(NSCoder.string(for: position)), \(NSCoder.string(for: velocity))}".utf8)
    }

    /// Initializing with an array of bytes. The bytes should decode into ascii character '{', followed by
    /// ascii characters for the string representation of `position`, followed by ascii characters ', ',
    /// followed by the string representation of `velocity`, and ending with ascii character '}'. The string
    /// representations are as returned by `NSStringFromCGPoint` and `NSStringFromCGVector` respectively.
    public init(bytes: [UInt8])
    {
      let string = String(bytes: bytes)

      let float = "-?[0-9]+(?:\\.[0-9]+)?"
      let value = "\\{\(float), \(float)\\}"

      guard let match = (~/"\\{(\(value)), (\(value))\\}").firstMatch(in: string, anchored: true),
            let positionCapture = match.captures[1],
            let velocityCapture = match.captures[2]
      else
      {
        self = .null
        return
      }

      guard let position = CGPoint(String(positionCapture.substring)),
            let velocity = CGVector(String(velocityCapture.substring))
      else
      {
        self = .null
        return
      }

      self.position = position
      self.velocity = velocity
    }

    /// The json object for the trajectory.
    public var jsonValue: JSONValue { return ["position": position, "velocity": velocity] }

    /// Initializing with a json object containing keys 'position' and 'velocity' with appropriate values.
    public init?(_ jsonValue: JSONValue?)
    {
      guard let dict = ObjectJSONValue(jsonValue),
            let position = CGPoint(dict["position"]),
            let velocity = CGVector(dict["velocity"])
      else
      {
        return nil
      }

      self.position = position
      self.velocity = velocity
    }

    public var description: String { return "{ velocity: \(velocity); position: \(position) }" }

    /// Type for specifiying the direction of a `Trajectory`.
    public enum Direction: Equatable, CustomStringConvertible
    {
      /// Enumeration describing the possible vertical movement of a trajectory.
      public enum VerticalMovement: String, Equatable { case none, up, down }

      /// Enumeration describing the possible horizontal movement of a trajectory.
      public enum HorizontalMovement: String, Equatable { case none, left, right }

      case none
      case vertical(VerticalMovement)
      case horizontal(HorizontalMovement)
      case diagonal(VerticalMovement, HorizontalMovement)

      /// Initialize with a vector representing the slope of a line segment.
      public init(vector: CGVector)
      {
        switch *vector
        {
          case (0, 0): self = .none
          case (0, <--0): self = .vertical(.down)
          case (0, _): self = .vertical(.up)
          case (<--0, 0): self = .horizontal(.left)
          case (_, 0): self = .horizontal(.right)
          case (<--0, <--0): self = .diagonal(.down, .left)
          case (<--0, _): self = .diagonal(.up, .left)
          case (_, <--0): self = .diagonal(.down, .right)
          case (_, _): self = .diagonal(.up, .right)
        }
      }

      /// Initialize with the end points of a line segment.
      public init(start: CGPoint, end: CGPoint)
      {
        switch (*start, *end)
        {
          case let ((x1, y1), (x2, y2)) where x1 == x2 && y1 == y2: self = .none
          case let ((x1, y1), (x2, y2)) where x1 == x2 && y1 < y2: self = .vertical(.up)
          case let ((x1, _), (x2, _)) where x1 == x2: self = .vertical(.down)
          case let ((x1, y1), (x2, y2)) where x1 < x2 && y1 == y2: self = .horizontal(.right)
          case let ((_, y1), (_, y2)) where y1 == y2: self = .horizontal(.left)
          case let ((x1, y1), (x2, y2)) where x1 < x2 && y1 < y2: self = .diagonal(.up, .right)
          case let ((x1, y1), (x2, y2)) where x1 < x2 && y1 > y2: self = .diagonal(.down, .right)
          case let ((_, y1), (_, y2)) where y1 < y2: self = .diagonal(.up, .left)
          case let ((_, y1), (_, y2)) where y1 > y2: self = .diagonal(.down, .left)
          default: self = .none
        }
      }

      /// The vertical movement in the trajectory.
      public var vertical: VerticalMovement
      {
        get
        {
          switch self
          {
            case let .vertical(movement): return movement
            case let .diagonal(movement, _): return movement
            default: return .none
          }
        }
        set
        {
          guard vertical != newValue else { return }
          switch self
          {
            case let .horizontal(horizontal): self = .diagonal(newValue, horizontal)
            case .vertical: self = .vertical(newValue)
            case let .diagonal(_, horizontal): self = .diagonal(newValue, horizontal)
            case .none: self = .vertical(newValue)
          }
        }
      }

      /// The horizontal movement in the trajectory.
      public var horizontal: HorizontalMovement
      {
        get
        {
          switch self
          {
            case let .horizontal(movement): return movement
            case let .diagonal(_, movement): return movement
            default: return .none
          }
        }
        set
        {
          guard horizontal != newValue else { return }
          switch self
          {
            case let .vertical(vertical): self = .diagonal(vertical, newValue)
            case .horizontal: self = .horizontal(newValue)
            case let .diagonal(vertical, _): self = .diagonal(vertical, newValue)
            case .none: self = .horizontal(newValue)
          }
        }
      }

      /// The direction generated by reversing the vertical and horizontal movement.
      public var reversed: Direction
      {
        switch self
        {
          case .vertical(.up): return .vertical(.down)
          case .vertical(.down): return .vertical(.up)
          case .horizontal(.left): return .horizontal(.right)
          case .horizontal(.right): return .horizontal(.left)
          case .diagonal(.up, .left): return .diagonal(.down, .right)
          case .diagonal(.down, .left): return .diagonal(.up, .right)
          case .diagonal(.up, .right): return .diagonal(.down, .left)
          case .diagonal(.down, .right): return .diagonal(.up, .left)
          default: return .none
        }
      }

      public var description: String
      {
        switch self
        {
          case let .vertical(v): return v.rawValue
          case let .horizontal(h): return h.rawValue
          case let .diagonal(v, h): return "\(v.rawValue)-\(h.rawValue)"
          case .none: return "none"
        }
      }

      /// Returns true iff the vertical and horizontal movement of `lhs` are equal to those of `rhs`.
      public static func == (lhs: Direction, rhs: Direction) -> Bool
      {
        return lhs.vertical == rhs.vertical && lhs.horizontal == rhs.horizontal
      }
    }
  }
}
