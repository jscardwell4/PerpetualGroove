//
//  ChameleonAppDelegate.swift
//  ChameleonApp
//
//  Created by Jason Cardwell on 5/11/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import Chameleon

@UIApplicationMain
class ChameleonAppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.

    window = UIWindow(frame: UIScreen.mainScreen().bounds)
    window?.backgroundColor = UIColor.whiteColor()
    window?.makeKeyAndVisible()
    window?.rootViewController = SchemeEditor()

    return true
  }

}

