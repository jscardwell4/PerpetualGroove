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
    guard let sourceViewController      = source      as? MIDIPlayerViewController,
              let destinationViewController = destination as? PurgatoryViewController else
    {
      fatalError("This must not work like I thought it did.")
    }
    destinationViewController.backdropImage = sourceViewController.view.snapshot
    super.perform()
  }
}

final class PurgatoryViewController: UIViewController {

  fileprivate let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  @IBOutlet var backdrop: UIImageView!

  var backdropImage: UIImage?

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    receptionist.observe(name: NSNotification.Name.NSUbiquityIdentityDidChange.rawValue,
                callback: weakMethod(self, PurgatoryViewController.ubiquityIdentityDidChange))

    receptionist.observe(notification: .iCloudStorageChanged,
                    from: SettingsManager.self,
                callback: weakMethod(self, PurgatoryViewController.iCloudStorageChanged))

    receptionist.observe(name: NSNotification.Name.UIApplicationDidBecomeActive.rawValue,
                    from: UIApplication.shared,
                callback: weakMethod(self, PurgatoryViewController.applicationDidBecomeActive))

    backdrop.image = backdropImage
  }

  /**
  applicationDidBecomeActive:

  - parameter notification: NSNotification
  */
  fileprivate func applicationDidBecomeActive(_ notification: Notification) {
    logDebug("received notification that application is now active")
    if !(SettingsManager.iCloudStorage && FileManager.default.ubiquityIdentityToken == nil) {
      dismiss(animated: true, completion: nil)
    }
  }

  /**
  ubiquityIdentityDidChange:

  - parameter notification: NSNotification
  */
  fileprivate func ubiquityIdentityDidChange(_ notification: Notification) {
    logDebug("identityToken: \(FileManager.default.ubiquityIdentityToken)")
    guard FileManager.default.ubiquityIdentityToken != nil else { return }
    dismiss(animated: true, completion: nil)
  }

  /**
  iCloudStorageChanged:

  - parameter notification: NSNotification
  */
  fileprivate func iCloudStorageChanged(_ notification: Notification) {
    logDebug("iCloudStorage: \(SettingsManager.iCloudStorage)")
    if !SettingsManager.iCloudStorage { dismiss(animated: true, completion: nil) }
  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  override func viewWillAppear(_ animated: Bool) {

    guard isBeingPresented else { fatalError("This controller is meant only to be presented") }

    guard SettingsManager.iCloudStorage else { fatalError("This controller should only appear when 'Use iCloud' is true") }

    guard FileManager.default.ubiquityIdentityToken == nil else {
      fatalError("This controller's view should only appear when ubiquityIdentityToken is nil")
    }
  }

}
