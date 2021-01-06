//
//  AppDelegate.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import UIKit
import MoonKit
import Common
import Sequencer
import NodePlayer
import Documents

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

  func application(_ application: UIApplication,
                   willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool
  {
    //    backgroundDispatch { LogManager.initialize() }
    return true
  }

  /// Sets the `viewController` property and initializes `SettingsManager`, `AudioManager`, `Sequencer`,
  /// `MIDINodePlayer`, and `DocumentManager`.
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
  {
    
    _ = Sequencer.shared
    MIDINodePlayer.initialize()
    DocumentManager.initialize()

    viewController = window?.rootViewController as? RootViewController

    return true

  }

}

