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

final class MIDIPlayerContainerViewController: SecondaryControllerContainer {

//  private weak var controllerTool: ToolType?

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
   presentContentForTool:

   - parameter tool: ConfigurableToolType
   */
//  func presentContentForTool<T:ToolType where T:SecondaryControllerContentDelegate>(tool: T) {
//    presentContentForDelegate(tool) {
//      [unowned self] in
//        guard $0 else { return }
//        self.controllerTool = tool
//    }
//  }

//  override func completionForDismissalAction(dismissalAction: DismissalAction) -> (Bool) -> Void {
//    let completion = super.completionForDismissalAction(dismissalAction)
//    return {
//      [weak self] completed in
//      completion(completed)
//      guard let tool = self?.controllerTool where tool.isShowingContent == true else {
//        return
//      }
//      tool.didHideContent?(dismissalAction)
//      self?.controllerTool = nil
//    }
//  }

}