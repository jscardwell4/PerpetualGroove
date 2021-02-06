//
//  Trajectory.swift
//  Common
//
//  Created by Jason Cardwell on 2/5/21.
//
import Foundation
import MoonDev
import CoreGraphics

/// Type for expressing velocity and angle from a point.
public struct Trajectory: Hashable, ByteArrayConvertible,
                          CustomStringConvertible, Codable
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
  public var angle: CGFloat
  {
    get { velocity.angle }
    set { velocity.angle = newValue }
  }

  /// Elapsed time in seconds between the specified points
  public func time(from p1: CGPoint, to p2: CGPoint) -> TimeInterval
  {
    let result = abs(TimeInterval(p1.distanceTo(p2) / slope)) *
      TimeInterval(Trajectory.modifier)

    guard result.isFinite else { fatalError("Invalid time: \(result)") }

    return result
  }

  /// The 'zero' trajectory.
  public static var zero: Trajectory
  {
    return Trajectory(velocity: .zero, position: .zero)
  }

  /// Trajectory value for representing a 'null' or 'invalid' trajectory
  public static var null: Trajectory
  {
    return Trajectory(velocity: CGVector.zero, position: CGPoint.null)
  }

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
    return Array("{\(NSCoder.string(for: position)), \(NSCoder.string(for: velocity))}"
                  .utf8)
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

    guard let match = (~/"\\{(\(value)), (\(value))\\}")
            .firstMatch(in: string, anchored: true),
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

  private enum CodingKeys: String, CodingKey { case position, velocity }

  public func encode(to encoder: Encoder) throws
  {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(position, forKey: .position)
    try container.encode(velocity, forKey: .velocity)
  }

  public init(from decoder: Decoder) throws
  {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    position = try container.decode(CGPoint.self, forKey: .position)
    velocity = try container.decode(CGVector.self, forKey: .velocity)
  }

  public var description: String { "{ velocity: \(velocity); position: \(position) }" }

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
        case let ((x1, y1), (x2, y2))
              where x1 < x2 && y1 == y2: self = .horizontal(.right)
        case let ((_, y1), (_, y2)) where y1 == y2: self = .horizontal(.left)
        case let ((x1, y1), (x2, y2))
              where x1 < x2 && y1 < y2: self = .diagonal(.up, .right)
        case let ((x1, y1), (x2, y2))
              where x1 < x2 && y1 > y2: self = .diagonal(.down, .right)
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
