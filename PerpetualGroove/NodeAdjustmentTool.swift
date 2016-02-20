//
//  NodeAdjustmentTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/17/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

class NodeAdjustmentTool: NodeSelectionTool {

  /**
   adjustNode:

   - parameter body: () -> Void
  */
  final func adjustNode(@noescape body: () -> Void) {
    // Ensure we have a node to adjust
    guard let node = node else { return }

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
    catch { logError(error); return }

    // Perform node adjustements
    body()

    // Adjust playback position if the node's start time has changed
    if node.initTime != preadjustedNodeStart {
      do { try transport.automateJogToTime(node.initTime) }
      catch { logError(error); return }
    }

    // Make sure the transport wasn't paused or return
    guard !isPaused else { return }

    // Resume playback
    transport.play()
  }

}