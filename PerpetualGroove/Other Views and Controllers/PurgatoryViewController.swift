//
//  PurgatoryViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

// TODO: Review file

final class PurgatorySegue: UIStoryboardSegue {

  override func perform() {
    (destination as? PurgatoryViewController)?.backdropImage = source.view.snapshot
    super.perform()
  }

}

final class PurgatoryViewController: UIViewController {

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  @IBOutlet var backdrop: UIImageView!

  var backdropImage: UIImage?

  override func viewDidLoad() {
    super.viewDidLoad()

     backdrop.image = backdropImage

    receptionist.observe(name: NSNotification.Name.NSUbiquityIdentityDidChange.rawValue) {
      [weak self] _ in
      guard FileManager.default.ubiquityIdentityToken != nil else { return }
      self?.dismiss(animated: true, completion: nil)
    }

    receptionist.observe(name: .iCloudStorageChanged, from: SettingsManager.self) {
      [weak self] _ in

      if !SettingsManager.iCloudStorage { self?.dismiss(animated: true, completion: nil) }
    }

    receptionist.observe(name: NSNotification.Name.UIApplicationDidBecomeActive.rawValue) {
      [weak self] _ in

      if !(SettingsManager.iCloudStorage && FileManager.default.ubiquityIdentityToken == nil) {
        self?.dismiss(animated: true, completion: nil)
      }
    }

  }

  override func viewWillAppear(_ animated: Bool) {

    guard isBeingPresented else {
      fatalError("This controller is meant only to be presented")
    }

    guard SettingsManager.iCloudStorage else {
      fatalError("This controller should only appear when 'Use iCloud' is true")
    }

    guard FileManager.default.ubiquityIdentityToken == nil else {
      fatalError("This controller's view should only appear when ubiquityIdentityToken is nil")
    }
    
  }

}
