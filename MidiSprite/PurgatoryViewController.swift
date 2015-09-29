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
    guard let sourceViewController = sourceViewController as? MIDIPlayerViewController,
      destinationViewController = destinationViewController as? PurgatoryViewController else
    {
      fatalError("This must not work like I thought it did.")
    }
    destinationViewController.backdropImage = sourceViewController.view.snapshot
    super.perform()
  }
}

final class PurgatoryViewController: UIViewController {

  private var notificationReceptionist: NotificationReceptionist!
  @IBOutlet var backdrop: UIImageView!

  var backdropImage: UIImage?

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    guard case .None = notificationReceptionist else { return }

    notificationReceptionist = NotificationReceptionist(callbacks:[
      NSUbiquityIdentityDidChangeNotification: (nil, NSOperationQueue.mainQueue(), identityDidChange)
      ])

    backdrop.image = backdropImage
  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  override func viewWillAppear(animated: Bool) {
    guard isBeingPresented() else { fatalError("This controller is meant only to be presented") }
    guard NSFileManager.defaultManager().ubiquityIdentityToken == nil else {
      fatalError("This controller's view should only appear when ubiquityIdentityToken is nil")
    }
  }

  /**
  identityDidChange:

  - parameter notification: NSNotification
  */
  private func identityDidChange(notification: NSNotification) {
    logDebug()
    guard NSFileManager.defaultManager().ubiquityIdentityToken != nil else { return }
    dismissViewControllerAnimated(true, completion: nil)
  }

}
