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
  
  private(set) weak var mixerViewController: MixerViewController!

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    super.prepareForSegue(segue, sender: sender)
    switch segue.destinationViewController {
      case let controller as MixerViewController: mixerViewController = controller
      default: break
    }
  }

  override func completionForDismissalAction(dismissalAction: DismissalAction) -> (Bool) -> Void {
    let completion = super.completionForDismissalAction(dismissalAction)
    return {
      [weak mixer = mixerViewController] completed in
      mixer?.soundSetSelectionTargetCell = nil
      completion(completed)
    }
  }
}