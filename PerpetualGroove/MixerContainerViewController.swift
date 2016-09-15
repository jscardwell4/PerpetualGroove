//
//  MixerContainerViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/7/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

final class MixerContainerViewController: SecondaryControllerContainer {
  
  fileprivate(set) weak var mixerViewController: MixerViewController!

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)
    switch segue.destination {
      case let controller as MixerViewController: mixerViewController = controller
      default: break
    }
  }

  override func completionForDismissalAction(_ dismissalAction: DismissalAction) -> (Bool) -> Void {
    let completion = super.completionForDismissalAction(dismissalAction)
    return {
      [weak mixer = mixerViewController] completed in
      mixer?.soundSetSelectionTargetCell = nil
      completion(completed)
    }
  }
}
