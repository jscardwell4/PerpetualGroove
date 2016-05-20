//
//  HashedStorageBuffer.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/20/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

enum HashedStorageBuffer<Key:Hashable, Value, Member:Hashable> {
  case OrderedSet(OrderedSetBuffer<Member>)
  case OrderedDictionary(OrderedDictionaryBuffer<Key, Value>)

  var storageHeader: HashedStorageHeader {
    switch self {
      case .OrderedSet(let buffer): return buffer.storage.value
      case .OrderedDictionary(let buffer): return buffer.storage.value
    }
  }

  var bucketMap: HashBucketMap {
    switch self {
      case .OrderedSet(let buffer): return buffer.bucketMap
      case .OrderedDictionary(let buffer): return buffer.bucketMap
    }
  }

  var initializedBuckets: BitMap {
    switch self {
    case .OrderedSet(let buffer): return buffer.initializedBuckets
    case .OrderedDictionary(let buffer): return buffer.initializedBuckets
    }
  }

  var identity: UnsafePointer<Void> { return UnsafePointer<Void>(initializedBuckets.buffer.baseAddress) }

  func idealBucketFor<H:Hashable>(h: H) -> HashBucket {
    return suggestBucketForValue(h, capacity: storageHeader.capacity)
  }



}