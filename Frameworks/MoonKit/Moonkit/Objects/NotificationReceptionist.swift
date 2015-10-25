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

  private var _logContext: LogManager.LogContext?
  public var logContext: LogManager.LogContext {
    get { return _logContext ?? NotificationReceptionist.defaultLogContext }
    set { _logContext = newValue }
  }

  private var infos: Set<ObservationInfo> = []

  private struct ObservationInfo: Hashable, CustomStringConvertible {
    let name: String
    let object: Weak<AnyObject>
    let observer: NSObjectProtocol
    var hashValue: Int { return name.hashValue ^ object.hashValue ^ observer.hash }

    var description: String {
      return "'\(name)'\(object.reference == nil ? "" : " from object \(object))")"
    }
  }

  public var count: Int { return infos.count }

  private var notificationCenter: NSNotificationCenter { return NSNotificationCenter.defaultCenter() }

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
    observe(notification.name.notificationName, from: object, queue: queue, callback: callback)
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
    let info = ObservationInfo(
      name: name,
      object: Weak(object),
      observer: notificationCenter.addObserverForName(name, object: object, queue: queue, usingBlock: callback)
    )
    infos.insert(info)
    logDebug("observing \(info)")
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
    notificationCenter.removeObserver(info.observer, name: info.name, object: info.object.reference)
    logDebug("stopped observing \(info)")
  }

  deinit { while let info = infos.popFirst() { stopObserving(info) } }
}

private func ==(lhs: NotificationReceptionist.ObservationInfo, rhs: NotificationReceptionist.ObservationInfo) -> Bool {
  return lhs.hashValue == rhs.hashValue
}
