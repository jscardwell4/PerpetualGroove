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

  override var anyAction: (() -> Void)? {
    let action = super.anyAction
    return {
      [mixer = mixerViewController] in
      mixer?.soundSetSelectionTargetCell = nil
      action?()
    }
  }

}