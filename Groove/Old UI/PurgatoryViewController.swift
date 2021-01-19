//
//  PurgatoryViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import MoonDev
import UIKit

// MARK: - PurgatorySegue

/// A custom segue for transitioning to an instance of `PurgatoryViewController`.
final class PurgatorySegue: UIStoryboardSegue
{
  /// Overridden to set the backdrop image for the destination controller.
  override func perform()
  {
    // To the backdrop image to a snapshot of the current view.
    (destination as? PurgatoryViewController)?.backdropImage = source.view.snapshot
    
    // Perform the segue.
    super.perform()
  }
}

// MARK: - PurgatoryViewController

/// A view controller that prevents interacting with the application until iCloud
/// storage is available or the setting to use iCloud is updated.
final class PurgatoryViewController: UIViewController
{
  /// The view displaying the backdrop image.
  @IBOutlet var backdrop: UIImageView!
  
  /// The image to display beneath the informative text.
  var backdropImage: UIImage?
  
  /// Subscription for `UIApplication.didBecomeActiveNotification` notifications.
  private var didBecomeActiveSubscription: Cancellable?
  
  /// Subscription for blah notifications.
  private var iCloudStorageChangedSubscription: Cancellable?
  
  /// Subscription for `.NSUbiquityIdentityDidChange` notifications.
  private var identityDidChangeSubscription: Cancellable?
  
  /// Overridden to register for various notifications.
  override func awakeFromNib()
  {
    super.awakeFromNib()
    
    didBecomeActiveSubscription = NotificationCenter.default
      .publisher(for: UIApplication.didBecomeActiveNotification)
      .sink
      { _ in
        guard self.isBeingPresented,
              !settings.iCloudStorage || FileManager.default.ubiquityIdentityToken != nil
        else
        {
          return
        }
        
        // Dismiss the view controller.
        self.dismiss(animated: true, completion: nil)
      }
    
    identityDidChangeSubscription = NotificationCenter.default
      .publisher(for: .NSUbiquityIdentityDidChange)
      .sink
      { _ in
        guard self.isBeingPresented, FileManager.default.ubiquityIdentityToken != nil
        else
        {
          return
        }
        self.dismiss(animated: true, completion: nil)
      }
    
    iCloudStorageChangedSubscription = UserDefaults.standard
      .publisher(for: \.iCloudStorage)
      .sink
      {
        guard self.isBeingPresented, $0 == false else { return }
        self.dismiss(animated: true, completion: nil)
      }
  }
  
  /// Overridden to update the backdrop image.
  override func viewDidLoad() { super.viewDidLoad(); backdrop.image = backdropImage }
  
  /// Overridden to ensure the view only appears when the controller is being presented,
  /// the iCloud storage setting is `true`, and the ubiquity identity token is `nil`.
  override func viewWillAppear(_: Bool)
  {
    guard isBeingPresented
    else
    {
      fatalError("This controller is meant only to be presented")
    }
    
    guard settings.iCloudStorage
    else
    {
      fatalError("This controller should only appear when 'Use iCloud' is true")
    }
    
    guard FileManager.default.ubiquityIdentityToken == nil
    else
    {
      fatalError(
        "This controller's view should only appear when ubiquityIdentityToken is nil"
      )
    }
  }
}
