//
//  HashedStorageHeader.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/3/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation
let maxLoadFactorInverse = 1.0/0.75

struct HashedStorageHeader: CustomStringConvertible {
  var count: Int = 0
  let capacity: Int
  let bytesAllocated: Int
  let initializedBuckets: BitMap
  let bucketMap: HashBucketMap

  init(capacity: Int,
       bytesAllocated: Int,
       initializedBuckets: BitMap,
       bucketMap: HashBucketMap)
  {
    self.capacity = capacity
    self.bytesAllocated = bytesAllocated
    self.initializedBuckets = initializedBuckets
    self.bucketMap = bucketMap
  }

  var description: String {
    return "\n".join("count: \(count)",
                     "capacity: \(capacity)",
                     "bytesAllocated: \(bytesAllocated)",
                     "initializedBuckets: \(initializedBuckets)",
                     "bucketMap: \(bucketMap)")
  }
}

