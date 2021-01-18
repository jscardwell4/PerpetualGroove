//
//  AppDelegate.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Common
import Documents
import MoonDev
import Sequencer
import UIKit

/// The delegate for the application.
@available(macCatalyst 14.0, *)
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
    MoonDev.Logger.shared.logLevel = .info
    logi("\(#fileID) \(#function) Touching settings, sequencer, and documentManager…")
    _ = settings
    _ = sequencer
    _ = documentManager
    
    viewController = window?.rootViewController as? RootViewController
    
    return true
  }
}
