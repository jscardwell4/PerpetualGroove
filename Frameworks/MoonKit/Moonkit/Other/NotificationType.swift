//
//  NotificationType.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/5/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public protocol NotificationNameType: RawRepresentable, Hashable {
  var notificationName: String { get }
}

public extension NotificationNameType where Self.RawValue == String {
  var notificationName: String { return rawValue }
  var hashValue: Int { return rawValue.hashValue }
}

public func ==<N:NotificationNameType>(lhs: N, rhs: N) -> Bool { return lhs.notificationName == rhs.notificationName }

public typealias NotificationKeyType = KeyType


extension String: RawRepresentable {
  public var rawValue: String { return self }
  public init?(rawValue: String) { self = rawValue }
}
extension String: KeyType { public var key: String { return self } }

public protocol _NotificationType {
  var _name: String { get }
  var object: AnyObject? { get }
  var _userInfo: [NSObject:AnyObject]? { get }
}

public func ==<N:_NotificationType>(lhs: N, rhs: N) -> Bool { return lhs._name == rhs._name }

public protocol NotificationType: _NotificationType, CustomStringConvertible {
  typealias NameType: NotificationNameType
  var name: NameType { get }

  typealias Key: NotificationKeyType
  var userInfo: [Key:AnyObject?]? { get }

  typealias Callback = (NSNotification) -> Void

  func post(object obj: AnyObject?, userInfo info: [Key:AnyObject?]?)
  func observe(object: AnyObject?, queue: NSOperationQueue?, callback: Callback) -> NSObjectProtocol
}

public extension NotificationType {
  var _name: String { return name.notificationName }
  var object: AnyObject? { return nil }
  var _userInfo: [NSObject:AnyObject]? {
    guard let userInfo = self.userInfo else { return nil }
    var result: [NSObject:AnyObject] = [:]
    for (k, v) in userInfo { result[k.key] = v ?? NSNull() }
    return result
  }
  var userInfo: [Key:AnyObject?]? { return nil }


  /**
  postObject:userInfo:

  - parameter obj: AnyObject? = nil
  - parameter info: [NSObject:AnyObject]? = nil
  */
  func post(object obj: AnyObject? = nil, userInfo info: [Key:AnyObject?]? = nil) {
    let notificationCenter = NSNotificationCenter.defaultCenter()
    let object = obj ?? self.object
    let userInfo: [NSObject:AnyObject]?
    if let info = info {
      var userInfoʹ: [NSObject:AnyObject] = [:]
      for (k, v) in info { userInfoʹ[k.key] = v ?? NSNull() }
      if let selfInfo = self._userInfo { userInfoʹ.insertContentsOf(selfInfo) }
      userInfo = userInfoʹ
    } else {
      userInfo = _userInfo
    }
//    logVerbose("posting <\(self.dynamicType)>'\(_name)' with object (\(object == nil ? "nil" : "\(unsafeAddressOf(object!))") and info (\(userInfo == nil ? "nil" : "\(userInfo!)"))", asynchronous: false)
    notificationCenter.postNotificationName(_name, object: object, userInfo: userInfo)
  }

  /**
  observe:queue:callback:

  - parameter object: AnyObject? = nil
  - parameter queue: NSOperationQueue? = nil
  - parameter callback: (NSNotification) -> Void

  - returns: NSObjectProtocol
  */
  func observe(object: AnyObject? = nil,
         queue: NSOperationQueue? = nil,
      callback: (NSNotification) -> Void) -> NSObjectProtocol
  {
    return NSNotificationCenter.defaultCenter()
             .addObserverForName(_name, object: object, queue: queue, usingBlock: callback)
  }

  var description: String {
    var result = "\(self.dynamicType) {\n"
    result += "\tname: \(_name)\n"
    if let object = object { result += "\tobject: \(object)\n" } else { result += "\tobject: nil\n" }
    if let info = _userInfo { result += "\tuserInfo: {\n\(info.formattedDescription().indentedBy(8))\n\t}\n" }
    else { result += "\tuserInfo: nil\n" }
    result += "}"
    return result
  }
}

public extension NotificationType where Self:NotificationNameType {
  var name: Self { return self }
}
