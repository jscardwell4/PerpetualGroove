//
//  KVOReceptionist.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/30/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

private(set) var observingContext = UnsafeMutablePointer<Void>.alloc(1)

public final class KVOReceptionist: NSObject {

  public typealias Callback = (String, AnyObject, [String:AnyObject]) -> Void

  private struct Observation {
    let object: WeakObject<AnyObject>
    let keyPath: String
    let queue: NSOperationQueue
    let callback: Callback
  }

  private var observations: [ObjectIdentifier:[String:Observation]] = [:]

  /**
  observe:forChangesTo:withOptions:queue:callback:

  - parameter object: AnyObject
  - parameter keyPath: String
  - parameter options: NSKeyValueObservingOptions = .New
  - parameter queue: NSOperationQueue = NSOperationQueue.mainQueue()
  - parameter callback: Callback
  */
  public func observe(object: AnyObject,
     var forChangesTo keyPath: String,
          withOptions options: NSKeyValueObservingOptions = .New,
                queue: NSOperationQueue = NSOperationQueue.mainQueue(),
             callback: Callback)
  {
    let identifier = ObjectIdentifier(object)
    keyPath = NSStringFromSelector(NSSelectorFromString(keyPath))
    var observationBag = observations[identifier] ?? [:]
    observationBag[keyPath] = Observation(object: WeakObject(object), keyPath: keyPath, queue: queue, callback: callback)
    observations[identifier] = observationBag
    object.addObserver(self,
            forKeyPath: keyPath,
               options: options,
               context: observingContext)
  }

  /**
  stopObserving:forChangesTo:

  - parameter object: AnyObject
  - parameter keyPath: String
  */
  public func stopObserving(object: AnyObject, var forChangesTo keyPath: String) {
    let identifier = ObjectIdentifier(object)
    keyPath = NSStringFromSelector(NSSelectorFromString(keyPath))
    guard var observationBag = observations[identifier], let observation = observationBag[keyPath] else { return }
    observationBag[keyPath] = nil
    observation.object.value?.removeObserver(self, forKeyPath: keyPath, context: observingContext)
    observations[identifier] = observationBag
  }


  deinit {
    for observation in observations.values.map({$0.values}).flatten() {
      observation.object.value?.removeObserver(self, forKeyPath: observation.keyPath, context: observingContext)
    }
    observations.removeAll()
  }

  /**
  observeValueForKeyPath:ofObject:change:context:

  - parameter keyPath: String?
  - parameter object: AnyObject?
  - parameter change: [String:AnyObject]?
  - parameter context: UnsafeMutablePointer<Void>
  */
  public override func observeValueForKeyPath(keyPath: String?,
                                     ofObject object: AnyObject?,
                                       change: [String:AnyObject]?,
                                      context: UnsafeMutablePointer<Void>)
  {
    guard context == observingContext,
      let keyPath = keyPath,
          object = object,
          change = change,
          observation = observations[ObjectIdentifier(object)]?[keyPath] else { return }

    observation.queue.addOperationWithBlock { observation.callback(keyPath, object, change) }
  }

}