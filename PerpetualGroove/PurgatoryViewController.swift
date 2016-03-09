//
//  PurgatoryViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class PurgatorySegue: UIStoryboardSegue {
  /** perform */
  override func perform() {
    guard let sourceViewController      = sourceViewController      as? MIDIPlayerViewController,
              destinationViewController = destinationViewController as? PurgatoryViewController else
    {
      fatalError("This must not work like I thought it did.")
    }
    destinationViewController.backdropImage = sourceViewController.view.snapshot
    super.perform()
  }
}

final class PurgatoryViewController: UIViewController {

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  @IBOutlet var backdrop: UIImageView!

  var backdropImage: UIImage?

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    receptionist.observe(name: NSUbiquityIdentityDidChangeNotification,
                callback: weakMethod(self, PurgatoryViewController.ubiquityIdentityDidChange))

    receptionist.observe(notification: .iCloudStorageChanged,
                    from: SettingsManager.self,
                callback: weakMethod(self, PurgatoryViewController.iCloudStorageChanged))

    receptionist.observe(name: UIApplicationDidBecomeActiveNotification,
                    from: UIApplication.sharedApplication(),
                callback: weakMethod(self, PurgatoryViewController.applicationDidBecomeActive))

    backdrop.image = backdropImage
  }

  /**
  applicationDidBecomeActive:

  - parameter notification: NSNotification
  */
  private func applicationDidBecomeActive(notification: NSNotification) {
    logDebug("received notification that application is now active")
    if !(SettingsManager.iCloudStorage && NSFileManager.defaultManager().ubiquityIdentityToken == nil) {
      dismissViewControllerAnimated(true, completion: nil)
    }
  }

  /**
  ubiquityIdentityDidChange:

  - parameter notification: NSNotification
  */
  private func ubiquityIdentityDidChange(notification: NSNotification) {
    logDebug("identityToken: \(NSFileManager.defaultManager().ubiquityIdentityToken)")
    guard NSFileManager.defaultManager().ubiquityIdentityToken != nil else { return }
    dismissViewControllerAnimated(true, completion: nil)
  }

  /**
  iCloudStorageChanged:

  - parameter notification: NSNotification
  */
  private func iCloudStorageChanged(notification: NSNotification) {
    logDebug("iCloudStorage: \(SettingsManager.iCloudStorage)")
    if !SettingsManager.iCloudStorage { dismissViewControllerAnimated(true, completion: nil) }
  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  override func viewWillAppear(animated: Bool) {

    guard isBeingPresented() else { fatalError("This controller is meant only to be presented") }

    guard SettingsManager.iCloudStorage else { fatalError("This controller should only appear when 'Use iCloud' is true") }

    guard NSFileManager.defaultManager().ubiquityIdentityToken == nil else {
      fatalError("This controller's view should only appear when ubiquityIdentityToken is nil")
    }
  }

}
