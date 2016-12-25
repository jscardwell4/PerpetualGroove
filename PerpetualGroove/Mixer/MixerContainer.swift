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

// TODO: Review file

final class MixerContainer: SecondaryControllerContainer {

  /// The primary content's view controller.
  fileprivate(set) weak var mixerViewController: MixerViewController!

  /// Overridden to assign the segue's destination to `mixerViewController`.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)
    switch segue.destination {
      case let controller as MixerViewController: mixerViewController = controller
      default: break
    }
  }

  /// Overridden to nullify `mixerViewController.soundFontTarget`. Also invokes `super`.
  override func completion(forAction dismissalAction: DismissalAction) -> (Bool) -> Void {
    let completion = super.completion(forAction: dismissalAction)
    return {
      [weak mixer = mixerViewController] completed in
        mixer?.soundFontTarget = nil
        completion(completed)
    }
  }
}
