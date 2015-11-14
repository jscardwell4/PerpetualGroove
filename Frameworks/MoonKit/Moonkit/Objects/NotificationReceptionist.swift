//
//  NotificationReceptionist.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/15/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public final class NotificationReceptionist: NSObject, Loggable {

  /**
  receiveNotification:

  - parameter notification: NSNotification
  */
  @objc private func receiveNotification(notification: NSNotification) {
    guard let idx = infos.indexOf({$0.name == notification.name && $0.object.reference === notification.object}) else {
      logWarning("not observing \(notification.name)'\(notification.object == nil ? "" : "from object at address \(unsafeAddressOf(notification.object!))")")
      return
    }
    let info = infos[idx]
    (info.queue ?? callbackQueue ?? NSOperationQueue.mainQueue()).addOperationWithBlock { info.callback(notification) }
  }


  private var _logContext: LogManager.LogContext?
  public var logContext: LogManager.LogContext {
    get { return _logContext ?? NotificationReceptionist.defaultLogContext }
    set { _logContext = newValue }
  }

  private var infos: Set<ObservationInfo> = []

  public var callbackQueue: NSOperationQueue?

  /**
  init:

  - parameter queue: NSOperationQueue? = nil
  */
  public init(callbackQueue queue: NSOperationQueue? = nil) {
    super.init()
    callbackQueue = queue
  }

  public var count: Int { return infos.count }

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
    observe(notification.name.notificationName, from: object, queue: queue ?? callbackQueue, callback: callback)
  }

  /**
  observe:from:queue:callback:

  - parameter name: String
  - parameter object: AnyObject? = nil
  - parameter queue: NSOperationQueue? = nil
  - parameter callback: (NSNotification) -> Void
  */
  public func observe(name: String,
                 from object: AnyObject? = nil,
                queue: NSOperationQueue? = nil,
             callback: (NSNotification) -> Void)
  {
    infos.insert(ObservationInfo(name: name, object: Weak(object), callback: callback, queue: queue))
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveNotification:", name: name, object: object)
  }

  /**
  observe:from:queue:callback:

  - parameter notification: N
  - parameter object: AnyObject? = nil
  - parameter queue: NSOperationQueue? = nil
  - parameter callback: (NSNotification) -> Void
  */
  public func observe<N:NotificationType where N:NotificationNameType>(notification: N,
                                                                  from object: AnyObject? = nil,
                                                                 queue: NSOperationQueue? = nil,
                                                              callback: (NSNotification) -> Void)
  {
    observe(notification.notificationName, from: object, queue: queue, callback: callback)
  }

  /**
  observe:from:queue:callback:

  - parameter name: N
  - parameter object: AnyObject? = nil
  - parameter queue: NSOperationQueue? = nil
  - parameter callback: (NSNotification) -> Void
  */
  public func observe<N:NotificationNameType>(name: N,
                                         from object: AnyObject? = nil,
                                        queue: NSOperationQueue? = nil,
                                     callback: (NSNotification) -> Void)
  {
    observe(name.notificationName, from: object, queue: queue, callback: callback)
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

  - parameter notification: N
  - parameter object: AnyObject? = nil
  */
  public func stopObserving<N:NotificationType where N:NotificationNameType>(notification: N, from object: AnyObject? = nil) {
    stopObserving(notification._name, from: object)
  }

  /**
  stopObserving:from:

  - parameter name: N
  - parameter object: AnyObject? = nil
  */
  public func stopObserving<N:NotificationNameType>(name: N, from object: AnyObject? = nil) {
    stopObserving(name.notificationName, from: object)
  }


  /**
  stopObserving:from:

  - parameter name: String
  - parameter object: AnyObject? = nil
  */
  public func stopObserving(name: String, from object: AnyObject? = nil) {
    guard let idx = infos.indexOf({$0.name == name && $0.object.reference === object}) else {
      logWarning("not observing \(name)'\(object == nil ? "" : "from object at address \(unsafeAddressOf(object!))")")
      return
    }
    stopObserving(infos.removeAtIndex(idx))
  }

  /**
  stopObserving:

  - parameter info: ObservationInfo
  */
  private func stopObserving(info: ObservationInfo) {
    NSNotificationCenter.defaultCenter().removeObserver(self, name: info.name, object: info.object.reference)
    logVerbose("stopped observing \(info)")
  }

  deinit { while let info = infos.popFirst() { stopObserving(info) } }
}

extension NotificationReceptionist {
  private struct ObservationInfo: Hashable, CustomStringConvertible {
    let name: String
    let object: Weak<AnyObject>
    let callback: (NSNotification) -> Void
    var hashValue: Int { return name.hashValue ^ object.hashValue }
    weak var queue: NSOperationQueue?

    var description: String {
      return "'\(name)'\(object.reference == nil ? "" : " from object \(object))")"
    }
  }
}

private func ==(lhs: NotificationReceptionist.ObservationInfo, rhs: NotificationReceptionist.ObservationInfo) -> Bool {
  return lhs.hashValue == rhs.hashValue
}
