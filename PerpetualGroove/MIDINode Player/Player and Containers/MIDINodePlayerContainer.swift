//
//  MIDINodePlayerContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/7/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

/// `SecondaryControllerContainer` subclass whose primary controller is an instance of 
/// `MIDINodePlayerViewController`. Any secondary content presented is provided by the various
/// tools owned by `MIDINodePlayer`.
final class MIDINodePlayerContainer: SecondaryControllerContainer {

  /// The primary controller.
  private(set) weak var playerViewController: MIDINodePlayerViewController! {
    didSet { MIDINodePlayer.playerContainer = self }
  }

  /// Overridden to update `playerViewController`.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)

    playerViewController = segue.destination as? MIDINodePlayerViewController
  }

  /// Overridden to stretch the blur across the player view when available.
  override var blurFrame: CGRect {
    guard playerViewController?.isViewLoaded == true else { return super.blurFrame }
    return playerViewController!.playerView.frame
  }

}
