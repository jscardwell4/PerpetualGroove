//
//  GrooveTrack.Loop.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/2/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit
import struct AudioToolbox.CABarBeatTime

extension GrooveTrack {

  struct Loop {

    var repetitions: Int
    var repeatDelay: UInt64
    var start: CABarBeatTime
    var nodes: [UInt64:Node]

  }

}