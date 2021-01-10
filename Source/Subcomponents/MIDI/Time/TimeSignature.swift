//
//  TimeSignature.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// MARK: - TimeSignature

/// A structure for representing a MIDI time signature.
public enum TimeSignature
{
  /// Four beats per bar and a quarter note lasts one beat.
  case fourFour
  
  /// Three beats per bar and a quarter note lasts one beat.
  case threeFour
  
  /// Two beats per bar and a quarter note lasts one beat.
  case twoFour
  
  /// `upper` beats per bar with the beat duration determined by `lower`.
  case other(upper: UInt8, lower: UInt8)
  
  /// The lower number of the time signature when using standard western musical notation.
  /// A `beatUnit` value of `4` would mean that a quarter note lasts one beat, a value of
  /// `8` would mean that an eigth note lasts one beat, and so on…
  public var beatUnit: UInt8
  {
    // Return the lower value if the time signature has custom values.
    if case let .other(_, lower) = self
    {
      return lower
    }
    
    // Otherwise return the lower value implied by all the other enumeration cases.
    else
    {
      return 4
    }
  }
  
  /// The number of beats per bar. This is the upper number of the time signature
  /// when using the standard western musical notation.
  public var beatsPerBar: Int
  {
    switch self
    {
      case .fourFour: return 4
      case .threeFour: return 3
      case .twoFour: return 2
      case let .other(b, _): return Int(b)
    }
  }
  
  /// Initializing with the upper and lower values of the time signature.
  public init(upper: UInt8, lower: UInt8)
  {
    switch (upper, lower)
    {
      case (4, 4):
        // Four quarter notes per bar.
        
        self = .fourFour
        
      case (3, 4):
        // Three quarter notes per bar.
        
        self = .threeFour
        
      case (2, 4):
        // Two quarter notes per bar.
        
        self = .twoFour
        
      default:
        // Custom upper and lower values.
        
        self = .other(upper: upper, lower: lower)
    }
  }
}

// MARK: Hashable

extension TimeSignature: Hashable
{
  public func hash(into hasher: inout Hasher)
  {
    beatsPerBar.hash(into: &hasher)
    beatUnit.hash(into: &hasher)
  }
  
  /// Returns `true` iff `lhs` and `rhs` are of the same case excluding `other`, or if
  /// `lhs` and `rhs` are both of case `other` with equal `upper` and `lower` values.
  public static func == (lhs: TimeSignature, rhs: TimeSignature) -> Bool
  {
    switch (lhs, rhs)
    {
      case (.fourFour, .fourFour),
           (.threeFour, .threeFour),
           (.twoFour, .twoFour):
        return true
        
      case let (.other(x1, y1),
                .other(x2, y2))
            where x1 == x2 && y1 == y2:
        return true
        
      default:
        return false
    }
  }
}

// MARK: ByteArrayConvertible

extension TimeSignature: ByteArrayConvertible
{
  /// The time signature converted to its raw byte MIDI event representation.
  public var bytes: [UInt8] { return [beatUnit, UInt8(log2(Double(beatsPerBar)))] }
  
  /// Initialzing with a raw byte MIDI event representation.
  public init(bytes: [UInt8])
  {
    // Check that the correct number of bytes have been passed.
    guard bytes.count == 2
    else
    {
      // Fallback to the widely used four beats per bar with a quarter note lasting a beat.
      self.init(upper: 4, lower: 4)
      
      return
    }
    
    // Initialize with the first byte and the converted second byte as the upper and lower
    // values.
    self.init(upper: bytes[0], lower: bytes[1] * bytes[1])
  }
}
