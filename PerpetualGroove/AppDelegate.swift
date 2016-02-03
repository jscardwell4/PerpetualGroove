//
//  AppDelegate.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import Eveleth
import Triump
import FestivoLC
import MoonKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

  static var currentInstance: AppDelegate { return UIApplication.sharedApplication().delegate as! AppDelegate }

  var window: UIWindow?
  private(set) weak var viewController: RootViewController!

  /** initialize */
  override class func initialize() {
//    globalBackgroundQueue.async {
      if NSProcessInfo.processInfo().environment["XCInjectBundle"] == nil { LogManager.initialize() }
      Eveleth.registerFonts()
      Triump.registerFonts()
      FestivoLC.registerFonts()
//    }
  }

  /**
  application:didFinishLaunchingWithOptions:

  - parameter application: UIApplication
  - parameter launchOptions: [NSObject

  - returns: Bool
  */
  func                application(application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool
  {
    delayedDispatchToMain(1.0) {
      globalBackgroundQueue.async {
        SettingsManager.initialize()
        Sequencer.initialize()
        MIDIDocumentManager.initialize()
        AudioManager.initialize()
        MIDIPlayer.initialize()
      }
    }
    viewController = window?.rootViewController as? RootViewController
    return true
  }

  /**
  applicationWillResignActive:

  - parameter application: UIApplication
  */
  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary 
    // interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the 
    // transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this 
    // method to pause the game.
  }

  /**
  applicationDidEnterBackground:

  - parameter application: UIApplication
  */
  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state 
    // information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the
    // user quits.
  }

  /**
  applicationWillEnterForeground:

  - parameter application: UIApplication
  */
  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on
    // entering the background.
  }

  /**
  applicationDidBecomeActive:

  - parameter application: UIApplication
  */
  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was 
    // previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  
}

