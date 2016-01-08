//
//  MIDIPlayerContainerViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/7/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

final class MIDIPlayerContainerViewController: SecondaryControllerContainerViewController {

  private weak var controllerTool: ConfigurableToolType?

  private(set) weak var playerViewController: MIDIPlayerViewController! {
    didSet { MIDIPlayer.playerContainer = self }
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    super.prepareForSegue(segue, sender: sender)
    switch segue.destinationViewController {
    case let controller as MIDIPlayerViewController: playerViewController = controller
    default: break
    }
  }

  override var blurFrame: CGRect {
    guard playerViewController?.isViewLoaded() == true else { return super.blurFrame }
    return playerViewController!.playerView.frame
  }

  /**
   presentControllerForTool:

   - parameter tool: ConfigurableToolType
   */
  func presentControllerForTool(tool: ConfigurableToolType) {
    let controller = tool.viewController
    presentSecondaryController(controller) {
      [unowned self] in
        guard $0 else { return }
        tool.didShowViewController(controller)
        self.controllerTool = tool
    }
  }

  override var anyAction: (() -> Void)? {
    get {
      let action = super.anyAction
      return {
        [unowned self] in
        guard let tool = self.controllerTool where tool.isShowingViewController else { action?(); return }
        tool.didHideViewController(tool.viewController)
        self.controllerTool = nil
        action?()
      }
    }
    set {
      super.anyAction = newValue
    }
  }

}