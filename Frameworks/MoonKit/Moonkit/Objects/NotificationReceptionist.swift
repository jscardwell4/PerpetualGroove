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
   Returns the `ObservationInfo` in `infos` matching the specified `notification`;
   returns nil when there is no match
   */
  private subscript(notification: NSNotification) -> ObservationInfo? {
    guard let idx = infos.indexOf({$0.match(notification)}) else { return nil }
    return infos[idx]
  }

  /**
   Processes the received `notification` by invoking the registered callback on an
   appropriate queue
   */
  @objc private func receiveNotification(notification: NSNotification) {
    guard let info = self[notification] else {
      logWarning("not observing \(notification.name)"
        + (notification.object == nil
            ? ""
            : "from object at address \(unsafeAddressOf(notification.object!))"))
      return
    }
    logVerbose("notification: \(notification)")
    (info.queue ?? callbackQueue ?? NSOperationQueue.mainQueue()).addOperationWithBlock {
      info.callback(notification)
    }
  }


  /// Stores an optional override for the log context used when logging
  private var _logContext: LogManager.LogContext?

  /// Accessor for the log context used when logging
  public var logContext: LogManager.LogContext {
    get { return _logContext ?? NotificationReceptionist.defaultLogContext }
    set { _logContext = newValue }
  }

  /// The store of registered observers
  private var infos: Set<ObservationInfo> = []

  /// The queue upon which callbacks are scheduled upon receipt of a notification
  public var callbackQueue: NSOperationQueue?

  /// Create an new instance with the specified `callbackQueue`
  public init(callbackQueue queue: NSOperationQueue? = nil) {
    super.init()
    callbackQueue = queue
  }

  /// The total number of registered observers
  public var count: Int { return infos.count }

  /// Invokes `observe(name:from:queue:callback:)` with `name` set to `notification.name.notificationName`
  public func observe<N:NotificationType>(notification notification: N,
                      from object: AnyObject? = nil,
                           queue: NSOperationQueue? = nil,
                           callback: (NSNotification) -> Void)
  {
    observe(name: notification.name.notificationName, from: object, queue: queue, callback: callback)
  }

  /// Invokes `observeOnce(name:from:queue:callback:)` with `name` set to `notification.name.notificationName`
  public func observeOnce<N:NotificationType>(notification notification: N,
                      from object: AnyObject? = nil,
                           queue: NSOperationQueue? = nil,
                           callback: (NSNotification) -> Void)
  {
    observeOnce(name: notification.name.notificationName, from: object, queue: queue, callback: callback)
  }

  /**
   Invokes `observe(name:from:queue:callback)` with `name` set to `notification.name.notificationName`
   The restricting to `NotificationDispatchType` allows for dot-syntax, when valid, for specifying the 
   notification to observe.
   
   For example, given the following class:

       class NotificationDispatchingClass: NotificationDispatchType {
           
         enum Notification: 
           String, NotificationType, NotificationNameType 
         {
           case SomeNotification, SomeOtherNotification
           typealias Key = String
           var object: AnyObject? { 
             return NotificationDispatchingClass.self 
           }
         }
   
       }

   and `NotificationReceptionist` `receptionist`

   the method invocation might look something like:
   
       receptionist.observe(notification: .SomeNotification, 
                            from: NotificationDispatchingClass.self) {
         notification in
           print("notification received: \(notification)")
       }

  */
  public func observe<N:NotificationDispatchType>
    (notification notification: N.Notification,
                  from object: N?,
                       queue: NSOperationQueue? = nil,
                       callback: (NSNotification) -> Void)
  {
    observe(name: notification.name.notificationName, from: object, queue: queue, callback: callback)
  }

  /**
   Invokes `observeOnce(name:from:queue:callback)` with `name` set to `notification.name.notificationName`
   - seealso: observe<N:NotificationDistatchType>(notification:from:queue:callback:)
   */
  public func observeOnce<N:NotificationDispatchType>
    (notification notification: N.Notification,
                  from object: N?,
                       queue: NSOperationQueue? = nil,
                       callback: (NSNotification) -> Void)
  {
    observeOnce(name: notification.name.notificationName, from: object, queue: queue, callback: callback)
  }

  /// Disambiguates calls where the object is `N` (not an instance of `N`) being cast to `AnyObject`
  public func observe<N:NotificationDispatchType>
    (notification notification: N.Notification,
                  from object: N.Type?,
                       queue: NSOperationQueue? = nil,
                       callback: (NSNotification) -> Void)
  {
    observe(name: notification.name.notificationName, from: object, queue: queue, callback: callback)
  }

  /// Disambiguates calls where the object is `N` (not an instance of `N`) being cast to `AnyObject`
  public func observeOnce<N:NotificationDispatchType>
    (notification notification: N.Notification,
                  from object: N.Type?,
                       queue: NSOperationQueue? = nil,
                       callback: (NSNotification) -> Void)
  {
    observeOnce(name: notification.name.notificationName, from: object, queue: queue, callback: callback)
  }

  /// Invokes `observe(name:fromObjects:queue:callback:)` with `name` set to `notification.name.notificationName`
  public func observe<N:NotificationType>(notification notification: N,
                      fromObjects objects: [AnyObject],
                                  queue: NSOperationQueue? = nil,
                                  callback: (NSNotification) -> Void)
  {
    observe(name: notification.name.notificationName, fromObjects: objects, queue: queue, callback: callback)
  }

  /// Invokes `observeOnce(name:fromObjects:queue:callback:)` with `name` set to `notification.name.notificationName`
  public func observeOnce<N:NotificationType>(notification notification: N,
                      fromObjects objects: [AnyObject],
                                  queue: NSOperationQueue? = nil,
                                  callback: (NSNotification) -> Void)
  {
    observeOnce(name: notification.name.notificationName, fromObjects: objects, queue: queue, callback: callback)
  }

  /// Invokes `observe(name:from:queue:callback:)` for each object in `objects`
  public func observe(name name: String,
                           fromObjects objects: [AnyObject],
                                       queue: NSOperationQueue? = nil,
                                       callback: (NSNotification) -> Void)
  {
    objects.forEach { observe(name: name, from: $0, queue: queue, callback: callback) }
  }

  /// Invokes `observeOnce(name:from:queue:callback:)` for each object in `objects`
  public func observeOnce(name name: String,
                           fromObjects objects: [AnyObject],
                                       queue: NSOperationQueue? = nil,
                                       callback: (NSNotification) -> Void)
  {
    objects.forEach { observeOnce(name: name, from: $0, queue: queue, callback: callback) }
  }

  /**
   Registers with the default `NSNotificationCenter` to receive notifications named `name` from object `object`;
   `ObervationInfo` is created for this registration and inserted into `infos` to be retrieved as notifications
   are received.

   - parameter name: String The name of the notification for which to register the observer
   - parameter object: AnyObject? = nil The object whose notifications shall be received; 
                                         passing `nil` will cause the receptionist to receive all
                                         notifications with `name`.
   - parameter queue: NSOperationQueue? = nil The operation queue upon which `callback` should be scheduled; 
                                               uses `NSNotificationQueue.mainQueue()` when `nil`.
   - parameter callback: (NSNotification) -> Void The code to run when a notification has been received.
  */
  public func observe(name name: String,
                           from object: AnyObject? = nil,
                                queue: NSOperationQueue? = nil,
                                callback: (NSNotification) -> Void)
  {
    infos.insert(ObservationInfo(name: name, object: Weak(object), callback: callback, queue: queue))
    let selector = #selector(NotificationReceptionist.receiveNotification(_:))
    NSNotificationCenter.defaultCenter().addObserver(self, selector: selector, name: name, object: object)
  }

  /// Invokes `observe(name:from:queue:callback:` with `callback` modified to remove registration when called.
  public func observeOnce(name name: String,
                               from object: AnyObject? = nil,
                                    queue: NSOperationQueue? = nil,
                                    callback: (NSNotification) -> Void)
  {
    observe(name: name, from: object, queue: queue) {
      [unowned self] notification in
      callback(notification)
      guard let info = self[notification] else {
        fatalError("Received notification for which no matching `ObservationInfo` could be found: \(notification)")
      }
      self.stopObserving(info: info)
    }
  }

  /**
  Invokes `stopObserving(name:from:)` with `name` set to `notification.name.notificationName`
  */
  public func stopObserving<N:NotificationType>(notification notification: N, from object: AnyObject? = nil) {
    stopObserving(name: notification.name.notificationName, from: object)
  }

  /**
   Invokes `stopObserving(name:from:)` with `name` set to `notification.name.notificationName`
   - seealso: observe<N:NotificationDispatchType where N:AnyObject>(notification:from:)
   */
  public func stopObserving<N:NotificationDispatchType>
    (notification notification: N.Notification, from object: N? = nil)
  {
    stopObserving(name: notification.name.notificationName, from: object)
  }

  /// Disambiguates calls where the object is `N` (not an instance of `N`) being cast to `AnyObject`
  public func stopObserving<N:NotificationDispatchType
    where N:AnyObject>(notification notification: N.Notification, from object: N.Type? = nil)
  {
    stopObserving(name: notification.name.notificationName, from: object)
  }

  /**
   Unregisters the receptionist with the default notification center for notifications from `object` 
   with name `name`
   
   passing `nil` for `name` will unregister for all notifications from `object`

   passing `nil` for `object` will unregister for all notifications with `name`
   
   passing `nil` for both `name` and `object` will unregister for all notifications for which the 
   receptionist is currently registered.
   */
  public func stopObserving(name name: String?, from object: AnyObject? = nil) {

    switch (name, object) {
      case let (name?, object?):
        stopObserving(infos.filter({ $0.name == name && $0.object?.reference === object }))
      case let (nil, object?):
        stopObserving(infos.filter({ $0.object?.reference === object}))
      case let (name?, nil):
        stopObserving(infos.filter({ $0.name == name && $0.object == nil }))
      case (nil, nil):
        stopObserving(infos)
    }

  }

  /// Unregisters the receptionist with the default notification center for all notifications from `object`
  public func stopObserving(object object: AnyObject) {
    infos.filter({$0.object?.reference === object}).forEach({stopObserving(info: $0)})
  }

  /// Unregisters the receptionist with the default notification using the `name` and `object` values from `info`
  private func stopObserving(info info: ObservationInfo) {
    NSNotificationCenter.defaultCenter().removeObserver(self,
                                                        name: info.name,
                                                        object: info.object?.reference)
    logVerbose("stopped observing \(info)")
  }

  /// Invokes `stopObserving(info:)` for each `info` in `infos`
  private func stopObserving<S:SequenceType where S.Generator.Element == ObservationInfo>(infos: S) {
    for info in infos {
      stopObserving(info: info)
      self.infos.remove(info)
    }
  }

  deinit { stopObserving(infos) }
}

extension NotificationReceptionist {

  private struct ObservationInfo: Hashable, CustomStringConvertible {

    let name: String

    let object: Weak<AnyObject>?

    let callback: (NSNotification) -> Void

    var hashValue: Int { return name.hashValue ^ (object?.hashValue ?? 0) }

    weak var queue: NSOperationQueue?

    func match(notification: NSNotification) -> Bool {
      return name == notification.name && (object?.reference === notification.object || object == nil)
    }

    var description: String {
      return "'\(name)'\(object?.reference == nil ? "" : " from object \(object))")"
    }

  }

}

private func ==(lhs: NotificationReceptionist.ObservationInfo,
                rhs: NotificationReceptionist.ObservationInfo) -> Bool
{
  return lhs.hashValue == rhs.hashValue
}
