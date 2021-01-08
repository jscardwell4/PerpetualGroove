//
//  AppDelegate.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Common
import Documents
import MoonKit
import Sequencer
import UIKit

/// The delegate for the application.
@UIApplicationMain final class AppDelegate: UIResponder, UIApplicationDelegate
{
  /// The main window of the application.
  var window: UIWindow?

  /// The root view controller for `window`.
  private(set) weak var viewController: RootViewController!

  /// Sets the `viewController` property and kickstarts various initializations.
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool
  {
    _ = Controller.shared
    _ = Manager.shared

    viewController = window?.rootViewController as? RootViewController

    return true
  }
}
