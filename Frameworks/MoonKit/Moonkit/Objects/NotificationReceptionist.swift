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

  private var observers: [NSObjectProtocol] = []
  
  public init(callbacks: [Notification:Callback]) {
    super.init()
    let notificationCenter = NSNotificationCenter.defaultCenter()
    for (name, callback) in callbacks {
      observers.append(notificationCenter.addObserverForName(name, object: callback.0, queue: callback.1, usingBlock: callback.2))
    }
  }

  deinit {
    let notificationCenter = NSNotificationCenter.defaultCenter()
    observers.forEach {notificationCenter.removeObserver($0)}
    observers.removeAll(keepCapacity: false)
    notificationCenter.removeObserver(self)
  }
}
