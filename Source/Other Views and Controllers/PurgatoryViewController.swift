//
//  PurgatoryViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import UIKit
import MoonKit
import Common

/// A custom segue for transitioning to an instance of `PurgatoryViewController`.
final class PurgatorySegue: UIStoryboardSegue {

  /// Overridden to set the backdrop image for the destination controller.
  override func perform() {

    // To the backdrop image to a snapshot of the current view.
    (destination as? PurgatoryViewController)?.backdropImage = source.view.snapshot

    // Perform the segue.
    super.perform()

  }

}

/// A view controller that prevents interacting with the application until iCloud storage is available
/// or the setting to use iCloud is updated.
final class PurgatoryViewController: UIViewController {

  /// Handles registration/reception of application and settings manager notifications.
  private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

  /// The view displaying the backdrop image.
  @IBOutlet var backdrop: UIImageView!

  /// The image to display beneath the informative text.
  var backdropImage: UIImage?

  /// Overridden to register for various notifications.
  override func awakeFromNib() {

    super.awakeFromNib()

    fatalError("\(#function) not yet implemented.")
//    receptionist.observe(name: .NSUbiquityIdentityDidChange,
//                         callback: weakCapture(of: self, block:PurgatoryViewController.identityDidChange))
//
//    receptionist.observe(name: .iCloudStorageChanged, from: SettingsManager.self,
//                         callback: weakCapture(of: self, block:PurgatoryViewController.iCloudStorageChanged))
//
//    receptionist.observe(name: UIApplication.didBecomeActiveNotification,
//                         callback: weakCapture(of: self, block:PurgatoryViewController.applicationDidBecomeActive))

  }

  /// Overridden to update the backdrop image.
  override func viewDidLoad() {

    super.viewDidLoad()

    backdrop.image = backdropImage

  }

  /// Handler for ubiquity identity change notifications.
  private func identityDidChange(_ notification: Notification) {

    // Check that the view controller is being presented and a ubiquity identity token has been assigned.
    guard isBeingPresented && FileManager.default.ubiquityIdentityToken != nil else { return }

    // Dismiss the view controller.
    dismiss(animated: true, completion: nil)

  }

  /// Handler for iCloud storage setting change notifications.
  private func iCloudStorageChanged(_ notification: Notification) {
    
    // Check that the view controller is being presented and the iCloud storage setting is false.
    guard isBeingPresented && SettingsManager.shared.iCloudStorage == false else { return }

    // Dismiss the view controller.
    dismiss(animated: true, completion: nil)

  }

  /// Handler for notifications that the application has become active.
  private func applicationDidBecomeActive(_ notification: Notification) {

    // Check that the view controller is being presented and the iCloud storage setting is false or a 
    // ubiquity identity token has been assigned.
    guard isBeingPresented
            && ( !SettingsManager.shared.iCloudStorage
                  || FileManager.default.ubiquityIdentityToken != nil)
      else
    {
      return
    }

    // Dismiss the view controller.
    dismiss(animated: true, completion: nil)

  }

  /// Overridden to ensure the view only appears when the controller is being presented,
  /// the iCloud storage setting is `true`, and the ubiquity identity token is `nil`.
  override func viewWillAppear(_ animated: Bool) {

    guard isBeingPresented else {
      fatalError("This controller is meant only to be presented")
    }

    guard SettingsManager.shared.iCloudStorage else {
      fatalError("This controller should only appear when 'Use iCloud' is true")
    }

    guard FileManager.default.ubiquityIdentityToken == nil else {
      fatalError("This controller's view should only appear when ubiquityIdentityToken is nil")
    }
    
  }

}
