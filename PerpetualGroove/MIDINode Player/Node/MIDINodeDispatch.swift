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

protocol MIDINodeDispatch: class, MIDIEventDispatch, Named {

  var nextNodeName: String { get }

  var color: TrackColor { get }

  var nodeManager: MIDINodeManager! { get }

  func connect   (node: MIDINode) throws
  func disconnect(node: MIDINode) throws

  var recording: Bool { get }

}

enum MIDINodeDispatchError: String, Swift.Error, CustomStringConvertible {
  case NodeNotFound = "The specified node was not found among the track's nodes"
  case NodeAlreadyConnected = "The specified node has already been connected"
}
