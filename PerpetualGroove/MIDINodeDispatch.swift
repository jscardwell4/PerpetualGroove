//
//  MIDINodeDispatch.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/13/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

typealias MIDINodeRef = Weak<MIDINode>

// MARK: - MIDINodeDispatch
protocol MIDINodeDispatch: class, MIDIEventDispatch, Loggable, Named {
  var nextNodeName: String { get }
  var color: TrackColor { get }
  var nodeManager: MIDINodeManager! { get }
  func connectNode(_ node: MIDINode) throws
  func disconnectNode(_ node: MIDINode) throws

  var recording: Bool { get }
}

// MARK: - MIDINodeDispatchError
enum MIDINodeDispatchError: String, Swift.Error, CustomStringConvertible {
  case NodeNotFound = "The specified node was not found among the track's nodes"
  case NodeAlreadyConnected = "The specified node has already been connected"
}
