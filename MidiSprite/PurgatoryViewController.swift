//
//  PurgatoryViewController.swift
//  MidiSprite
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

    receptionist.observe(NSUbiquityIdentityDidChangeNotification) {
      [weak self] _ in
      guard NSFileManager.defaultManager().ubiquityIdentityToken != nil else { return }
      self?.dismissViewControllerAnimated(true, completion: nil)
    }
    receptionist.observe(SettingsManager.Notification.Name.iCloudStorageChanged, from: SettingsManager.self) {
      [weak self] _ in
      if !SettingsManager.iCloudStorage { self?.dismissViewControllerAnimated(true, completion: nil) }
    }

    backdrop.image = backdropImage
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
