//
//  HashBucket.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/3/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

struct HashBucket: BidirectionalIndexType, Comparable, Hashable {
  let offset: Int
  let capacity: Int

  func predecessor() -> HashBucket {
    return HashBucket(offset: (offset &- 1) & (capacity &- 1), capacity: capacity)
  }

  func successor() -> HashBucket {
    return HashBucket(offset: (offset &+ 1) & (capacity &- 1), capacity: capacity)
  }

  var hashValue: Int { return offset ^ capacity }
}

extension HashBucket: CustomStringConvertible {
  var description: String { return "\(offset)" }
}

func ==(lhs: HashBucket, rhs: HashBucket) -> Bool { return lhs.offset == rhs.offset }
func <(lhs: HashBucket, rhs: HashBucket) -> Bool { return lhs.offset < rhs.offset }


/// Returns the hash value of `value` squeezed into `capacity`
@inline(__always)
func suggestBucketForValue<H:Hashable>(value: H, capacity: Int) -> HashBucket {
  return HashBucket(offset: _squeezeHashValue(value.hashValue, 0 ..< capacity), capacity: capacity)
}

/// - requires: `initializedBuckets` has an empty bucket (to avoid an infinite loop)
func findBucketForValue<H:Hashable>(value: H, capacity: Int, initializedBuckets: BitMap) -> HashBucket {
  var bucket = suggestBucketForValue(value, capacity: capacity)
  repeat {
    guard initializedBuckets[bucket.offset] else { return bucket }
    bucket._successorInPlace()
  } while true
}

