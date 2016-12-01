//
//  NodeAdjustmentTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/17/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

private func _adjust(node: MIDINode, body: () -> Void) {
  // Get the node's start time before any adjustments
  let preadjustedNodeStart = node.initTime

  // Get the transport
  let transport = Sequencer.transport

  // Cache the pause state of the transport
  let isPaused = transport.paused

  // Make sure the transport is paused before adjusting
  if !isPaused { transport.pause() }

  // Try rolling the sequence back to the node's start time, returning on error
  do { try transport.automateJogToTime(preadjustedNodeStart) }
  catch { Log.error(error); return }

  // Perform node adjustements
  body()

  // Adjust playback position if the node's start time has changed
  if node.initTime != preadjustedNodeStart {
    do { try transport.automateJogToTime(node.initTime) }
    catch { Log.error(error); return }
  }

  // Make sure the transport wasn't paused or return
  guard !isPaused else { return }

  // Resume playback
  transport.play()
}

class NodeAdjustmentTool: NodeSelectionTool {

  final func adjustNode(_ body: () -> Void) {
    // Ensure we have a node to adjust
    guard let node = node else { return }
    _adjust(node: node, body: body)
  }

}

class PresentingNodeAdjustmentTool: PresentingNodeSelectionTool {

  final func adjustNode(_ body: () -> Void) {
    // Ensure we have a node to adjust
    guard let node = node else { return }
    _adjust(node: node, body: body)
  }

}
