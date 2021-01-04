//
//  MixerContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/7/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import Foundation
import UIKit
import MoonKit
import Common

/// A view controller that contains an instance of `MixerViewController` as its primary content
/// and within which secondary content, such as an instance of `InstrumentViewController`, may 
/// be presented.
public final class MixerContainer: SecondaryControllerContainer {

  /// The view controller responsible for the primary content.
  public private(set) weak var mixerViewController: MixerViewController!

  /// Overridden to assign the segue's destination to `mixerViewController`.
  public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    super.prepare(for: segue, sender: sender)

    guard let controller = segue.destination as? MixerViewController else { return }

    mixerViewController = controller

  }

  /// Overridden to nullify `mixerViewController.soundFontTarget`. Also invokes `super`.
  public override func completion(forAction dismissalAction: DismissalAction) -> (Bool) -> Void {

    // Store the result of super's implementation.
    let completion = super.completion(forAction: dismissalAction)

    // Return a closure that sets the mixer view controller's sound font target to `nil` and then
    // invokes the stored closure.
    return {
      [weak mixer = mixerViewController] completed in
        mixer?.soundFontTarget = nil
        completion(completed)
    }

  }

}
