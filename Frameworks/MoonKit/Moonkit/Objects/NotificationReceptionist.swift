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
  public enum Callback {
    case Selector (UIKit.Selector)
    case Block (NSOperationQueue?, (NSNotification!) -> Void)
  }

  private var observers: [NSObjectProtocol] = []
  
  public init(callbacks: [Notification:Callback], object: AnyObject?) {
    super.init()
    let notificationCenter = NSNotificationCenter.defaultCenter()
    for (name, callback) in callbacks {
      switch callback {
        case .Selector(let selector):
          notificationCenter.addObserver(self, selector: selector, name: name, object: object)
        case .Block(let queue, let block):
          observers.append(notificationCenter.addObserverForName(name, object: object, queue: queue, usingBlock: block))
      }
    }
  }

  deinit {
    let notificationCenter = NSNotificationCenter.defaultCenter()
    apply(observers) {notificationCenter.removeObserver($0)}
    observers.removeAll(keepCapacity: false)
    notificationCenter.removeObserver(self)
  }
}
