//
//  MixerContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/7/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import Common
import MoonKit
import UIKit

// MARK: - MixerContainer

/// A view controller containing the interface to the mixer.
public final class MixerContainer: SecondaryControllerContainer
{
  /// The view controller responsible for the primary content.
  public private(set) weak var mixerViewController: MixerViewController?
  
  /// Overridden to assign the segue's destination to `mixerViewController`.
  override public func prepare(for segue: UIStoryboardSegue, sender: Any?)
  {
    super.prepare(for: segue, sender: sender)
    mixerViewController = segue.destination as? MixerViewController
  }
  
  /// Overridden to nullify `mixerViewController.soundFontTarget`. Also invokes `super`.
  override public func completion(forAction dismissalAction: DismissalAction)
  -> (Bool) -> Void
  {
    {
      self.mixerViewController?.soundFontTarget = nil
      super.completion(forAction: dismissalAction)($0)
    }
  }
}
