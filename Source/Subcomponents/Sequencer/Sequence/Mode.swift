//
//  Mode.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/9/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation

/// An enumeration for specifying the sequencer's mode of operation.
public enum Mode: String
{
  /// The sequencer is manipulating it's current sequence as a whole.
  case linear
  
  /// The sequencer is manipulating a subsequence belonging to it's current sequence.
  case loop
}
