//
//  SecondaryContentViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 2/18/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

class SecondaryContentViewController: UIViewController, SecondaryControllerContentType {

  typealias Actions = SecondaryControllerContainerViewController.SecondaryContentActions
  typealias NavigationArrows = SecondaryControllerContainerViewController.NavigationArrows


  var actions = Actions()
  var navigationArrows: NavigationArrows = .None
  
  var anyAction: (() -> Void)? {
    get { return actions.anyAction }
    set { actions.anyAction = newValue }
  }
  var nextAction: (() -> Void)? {
    get { return actions.nextAction }
    set { actions.nextAction = newValue }
  }
  var previousAction: (() -> Void)? {
    get { return actions.previousAction }
    set { actions.previousAction = newValue }
  }
  var cancelAction: (() -> Void)? {
    get { return actions.cancelAction }
    set { actions.cancelAction = newValue }
  }
  var confirmAction: (() -> Void)? {
    get { return actions.confirmAction }
    set { actions.confirmAction = newValue }
  }

}