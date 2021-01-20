//
//  RootViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Common
import Documents
import Foundation
import MoonDev
import Sequencer
import UIKit
import SwiftUI

/// The root view controller for the application's window.
final class RootViewController: UIViewController
{
  /// The popover view within which the documents view controller is embedded.
  @IBOutlet private var documentsPopoverView: PopoverView!
  
  /// The view controller responsible for presenting an interface to the mixer
  /// with controls for the tracks in the currently loaded sequence as well as
  /// for adding and removing tracks to/from the currently loaded sequence.
  private(set) var mixerViewController: MixerViewController!
  
  /// The view controller responsible for presenting a control for adjusting
  /// the sequencer's tempo and for toggling the metronome on and off.
  private(set) weak var tempoViewController: TempoViewController!
  
  /// The view controller responsible for presenting the midi player within
  /// which new midi nodes can be added and existing midi nodes can be
  /// modified or removed.
  private(set) weak var playerViewController: PlayerViewController!
  
  /// The view controller responsible for presenting an interface for the
  /// current transport allowing playback to be started, paused, stopped,
  /// scrubbed, recorded, and reset.
  private(set) weak var transportViewController: TransportController!
  
  /// The stack containing the top and bottom stacks of content.
  @IBOutlet var contentStack: UIStackView!
  
  /// The stack containing the mixer and midi node player.
  @IBOutlet var topStack: UIStackView!
  
  /// The stack containing the transport, tempo slider, and documents button.
  @IBOutlet var bottomStack: UIStackView!
  
  /// The constraint controlling the height of the top stack.
  @IBOutlet var topStackHeight: NSLayoutConstraint!
  
  /// The constraint controlling the height of the bottom stack.
  @IBOutlet var bottomStackHeight: NSLayoutConstraint!
  
  /// The view within which the mixer is embedded.
  @IBOutlet var mixerContainer: UIView!
  
  /// The view within which the midi node player is embedded.
  @IBOutlet var midiContainer: UIView!
  
  /// The view within which the transport is embedded.
  @IBOutlet var transportContainer: UIView!
  
  /// Overridden to ensure the top stack is at the front.
  override func viewDidLoad()
  {
    super.viewDidLoad()
    
    // Bring the top stack to the front.
    contentStack.bringSubviewToFront(topStack)
  }
  
  /// Overridden to present the purgatory view controller if settings indicate
  /// iCloud should be used but the ubiquity identity token is `nil`.
  override func viewDidAppear(_ animated: Bool)
  {
    super.viewDidAppear(animated)
    
    // Check that iCloud storage should be used and the ubiquity identity token is `nil`.
    guard settings.iCloudStorage, FileManager.default.ubiquityIdentityToken == nil
    else
    {
      return
    }
    
    // Push the purgatory view controller to disable all functionality until an
    // identity token is established or the iCloud storage setting is updated.
    performSegue(withIdentifier: "Purgatory", sender: self)
  }
  
  /// Overridden to manually align the documents popover with the documents button.
  override func viewDidLayoutSubviews()
  {
    super.viewDidLayoutSubviews()
    
    // Get the popover and the button.
    guard let popoverView = documentsPopoverView,
          let presentingView = documentsButton
    else
    {
      return
    }
    
    // Convert the centers of each view to a common coordinate space.
    let popoverCenter = view.convert(popoverView.center, from: popoverView.superview)
    let presentingCenter = view.convert(
      presentingView.center,
      from: presentingView.superview
    )
    
    // Set the popover view's x offset to the difference in x values of the two centers.
    popoverView.xOffset = presentingCenter.x - popoverCenter.x
    
//        assert(presentingView.center.x - popoverView.center.x == popoverView.xOffset,
//               "Coordinate space is not being calculated as I thought it was.")
  }
  
  /// Overridden to return `true`.
  override var prefersStatusBarHidden: Bool { return false }
  
  /// Overridden to assign the destination controller to one of the root
  /// view controller's properties.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?)
  {
    super.prepare(for: segue, sender: sender)
    
    // Assign the destination controller to a property determined by the
    // destination controller's type.
    switch segue.destination
    {
      case let controller as MixerViewController:
        mixerViewController = controller
        
      case let controller as DocumentsViewController:
        documentsViewController = controller
        
      case let controller as TempoViewController:
        tempoViewController = controller
        
      case let controller as PlayerViewController:
        playerViewController = controller
        
      case let controller as TransportController:
        transportViewController = controller
        
      default:
        break
    }
  }
  
  /// Hides the documents popover and deselects the documents button.
  @IBAction private func dismissPopover()
  {
    documentsPopoverView.isHidden = true
    documentsButton.isSelected = false
  }
  
  /// The button acting as an anchor for the documents popover and serving
  /// as a toggle for its display.
  @IBOutlet var documentsButton: ImageButtonView!
  
  /// Toggles the display of the documents popover and the selection of
  /// the documents button.
  @IBAction private func documents()
  {
    documentsPopoverView.isHidden.toggle()
    documentsButton.isSelected = documentsPopoverView.isHidden == false
  }
  
  /// The view controller responsible for presenting the list of available documents
  /// as well as the ability to create a new document. Displayed by the documents popover.
  private(set) weak var documentsViewController: DocumentsViewController!
  {
    didSet
    {
      documentsViewController?.dismiss = dismissPopover
    }
  }
}
