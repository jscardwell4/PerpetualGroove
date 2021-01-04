//
//  Error.swift
//  SoundFont
//
//  Created by Jason Cardwell on 12/31/20.
//  Copyright © 2020 Moondeer Studios. All rights reserved.
//
import Foundation

/// Enumeration of the possible errors thrown by `SoundFont` types.
public enum Error: String, Swift.Error, CustomStringConvertible {
  case StructurallyUnsound = "Invalid chunk detected"
}
