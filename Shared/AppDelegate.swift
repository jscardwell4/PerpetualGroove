//
//  AppDelegate.swift
//  Groove
//
//  Created by Jason Cardwell on 1/28/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import func MoonDev.logi
import SwiftUI

#if canImport(UIKit)
typealias Delegate = UIApplicationDelegate
#elseif canImport(AppKit)
typealias Delegate = NSApplicationDelegate
#endif

// MARK: - AppDelegate

final class AppDelegate: NSObject, Delegate
{
  #if canImport(UIKit)
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? =
      nil
  ) -> Bool
  {
    UIView.appearance().tintColor = #colorLiteral(red: 0.7609999776, green: 0.2549999952, blue: 0, alpha: 1)
    return true
  }

  #endif
}
