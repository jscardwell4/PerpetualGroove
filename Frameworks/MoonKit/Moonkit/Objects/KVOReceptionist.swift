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

  public typealias Observation = (KVOReceptionist) -> Void

  public let keyPath: String
  public let queue: NSOperationQueue
  public let options: NSKeyValueObservingOptions
  public let handler: Observation

  private(set) public weak var observer: AnyObject?
  private(set) public weak var object: AnyObject?

  private(set) public var change: [NSObject:AnyObject]?

  /**
  init:keyPath:object:options:queue:handler:

  - parameter obs: AnyObject
  - parameter kp: String
  - parameter obj: AnyObject
  - parameter opt: NSKeyValueObservingOptions
  - parameter q: NSOperationQueue
  - parameter h: (KVOReceptionist) -> Void
  */
  public init(observer obs: AnyObject,
              keyPath kp: String,
              object obj: AnyObject,
              options opt: NSKeyValueObservingOptions = .New,
              queue q: NSOperationQueue = NSOperationQueue.mainQueue(),
              handler h: Observation)
  {
    observer = obs; keyPath = kp; object = obj; options = opt; queue = q; handler = h
    super.init()
    obj.addObserver(self, forKeyPath: NSStringFromSelector(NSSelectorFromString(kp)), options: opt, context: observingContext)
  }


  deinit { object?.removeObserver(self, forKeyPath: keyPath, context: observingContext) }

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
    if self.keyPath == keyPath && self.object === object && context == observingContext {
      queue.addOperationWithBlock { [unowned self] in self.change = change; self.handler(self) }
    }
  }

}