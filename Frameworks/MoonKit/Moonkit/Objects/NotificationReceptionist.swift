//
//  NotificationReceptionist.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/15/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public final class NotificationReceptionist: NSObject {

  public typealias Notification = String

  public typealias Callback = (AnyObject?, NSOperationQueue?, (NSNotification) -> Void)

  private var observers: [Int:NSObjectProtocol] = [:]

  private var notificationCenter: NSNotificationCenter { return NSNotificationCenter.defaultCenter() }

  /**
  hashForName:object:

  - parameter name: String
  - parameter object: AnyObject?

  - returns: Int
  */
  private func hashForName(name: String, object: AnyObject?) -> Int {
    guard let object = object else { return name.hashValue }
    if let objectHash = object.hashValue {
      return name.hashValue ^ objectHash
    } else if let objectHash = object.hash {
      return name.hashValue ^ objectHash
    } else {
      return name.hashValue
    }
  }

  /**
  observe:from:queue:callback:

  - parameter notification: N
  - parameter object: AnyObject? = nil
  - parameter queue: NSOperationQueue? = nil
  - parameter callback: (NSNotification) -> Void
  */
  public func observe<N:NotificationType>(notification: N,
                                     from object: AnyObject? = nil,
                                    queue: NSOperationQueue? = nil,
                                 callback: (NSNotification) -> Void)
  {
//    logDebug("notification: \(notification)\nobject: \(object)\nqueue: \(queue)", asynchronous: false)
    let key = hashForName(notification._name, object: object)
    observers[key] = notification.observe(object, queue: queue, callback: callback)
  }

  /**
  observe:from:queue:callback:

  - parameter name: Notification
  - parameter object: AnyObject? = nil
  - parameter queue: NSOperationQueue? = nil
  - parameter callback: (NSNotification) -> Void
  */
  public func observe(name: Notification,
                 from object: AnyObject? = nil,
                queue: NSOperationQueue? = nil,
             callback: (NSNotification) -> Void)
  {
    let key = hashForName(name, object: object)
    observers[key] = notificationCenter.addObserverForName(name, object: object, queue: queue, usingBlock: callback)
  }

  /**
  stopObserving:from:

  - parameter notification: N
  - parameter object: AnyObject? = nil
  */
  public func stopObserving<N:NotificationType>(notification: N, from object: AnyObject? = nil) {
    stopObserving(notification._name, from: object)
  }

  /**
  stopObserving:from:

  - parameter name: Notification
  - parameter object: AnyObject? = nil
  */
  public func stopObserving(name: Notification, from object: AnyObject? = nil) {
    guard let observer = observers[hashForName(name, object: object)] else {
      logWarning("no observer registered for '\(name)' from \(object)")
      return
    }
    notificationCenter.removeObserver(observer, name: name, object: object)
    observers[hash] = nil
  }

  /** init */
  public override init() { super.init() }

  /**
  initWithCallbacks:

  - parameter callbacks: [Notification
  */
  public convenience init(callbacks: [Notification:Callback]) {
    self.init()
    callbacks.forEach { observe($0, from: $1.0, queue: $1.1, callback: $1.2) }
  }

  deinit {
    observers.values.forEach { notificationCenter.removeObserver($0) }
    observers.removeAll(keepCapacity: false)
    notificationCenter.removeObserver(self)
  }
}
