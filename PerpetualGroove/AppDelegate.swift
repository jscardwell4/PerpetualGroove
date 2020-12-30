//
//  AppDelegate.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

// TODO: Implement or remove the empty delegate methods.

/// The delegate for the application.
@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

  /// The singleton instance of the delegate.
  static var currentInstance: AppDelegate { return UIApplication.shared.delegate as! AppDelegate }

  /// The main window of the application.
  var window: UIWindow?

  /// The root view controller for `window`.
  private(set) weak var viewController: RootViewController!

  /// Overridden to initialize the log manager unless the testing bundle has been injected.
//  @objc override class func initialize() {
//
//    // Check that this is actually the `AppDelegate` class and that the testing bundle has not been injected.
//    guard self === AppDelegate.self
//      && ProcessInfo.processInfo.environment["XCInjectBundle"] == nil
//      else
//    {
//      return
//    }
//
//    // Initialize the log manager in the background.
//    backgroundDispatch { LogManager.initialize() }
//
//  }

  /// Sets the `viewController` property and initializes `SettingsManager`, `AudioManager`, `Sequencer`,
  /// `MIDINodePlayer`, and `DocumentManager`.
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
  {

    do {

      SettingsManager.initialize()
      try AudioManager.initialize()
      try Sequencer.initialize()
      MIDINodePlayer.initialize()
      DocumentManager.initialize()

    } catch {

      loge("\(error)")

    }

    viewController = window?.rootViewController as? RootViewController

    return true

  }

  /// Sent when the application is about to move from active to inactive state. This can occur for certain 
  /// types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits
  /// the application and it begins the transition to the background state.
  ///
  /// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games
  /// should use this method to pause the game.
  ///
  /// - TODO: Implement or remove.
  func applicationWillResignActive(_ application: UIApplication) { }

  /// Use this method to release shared resources, save user data, invalidate timers, and store enough 
  /// application state information to restore your application to its current state in case it is terminated
  /// later.
  ///
  /// If your application supports background execution, this method is called instead of 
  /// `applicationWillTerminate(:)` when the user quits.
  ///
  /// - TODO: Implement or remove.
  func applicationDidEnterBackground(_ application: UIApplication) { }

  /// Called as part of the transition from the background to the inactive state; here you can undo many of 
  /// the changes made on entering the background.
  ///
  /// - TODO: Implement or remove.
  func applicationWillEnterForeground(_ application: UIApplication) { }

  /// Restart any tasks that were paused (or not yet started) while the application was inactive. If the 
  /// application was previously in the background, optionally refresh the user interface.
  ///
  /// - TODO: Implement or remove.
  func applicationDidBecomeActive(_ application: UIApplication) { }

  /// Called when the application is about to terminate. Save data if appropriate. 
  ///
  /// - seealso: `applicationDidEnterBackground(:)`
  /// - TODO: Implement or remove.
  func applicationWillTerminate(_ application: UIApplication) { }
  
}

