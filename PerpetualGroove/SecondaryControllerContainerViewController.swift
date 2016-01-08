//
//  SecondaryControllerContainerViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/7/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

class SecondaryControllerContainerViewController: UIViewController {

  var primaryController: UIViewController? { return childViewControllers.first }
  var secondaryController: UIViewController? { return childViewControllers.count == 2 ? childViewControllers[1] : nil }

  @IBOutlet private weak var containerView: UIView!

  @IBOutlet private var blurView: UIVisualEffectView!

  @IBOutlet private weak var confirmButton: ImageButtonView!
  @IBOutlet private weak var cancelButton: ImageButtonView!

  /** confirm */
  @IBAction private func confirm() { dismissSecondaryController(.Confirm) }

  /** cancel */
  @IBAction private func cancel() { dismissSecondaryController(.Cancel) }

  var anyAction: (() -> Void)?
  var cancelAction: (() -> Void)?
  var confirmAction: (() -> Void)?

  enum DismissalAction { case None, Cancel, Confirm }

  var blurFrame: CGRect { guard isViewLoaded() else { return .zero }; return view.bounds }

  /**
   presentSecondaryController:

   - parameter controller: UIViewController
  */
  func presentSecondaryController(controller: UIViewController, completion: ((Bool) -> Void)? = nil) {
    guard childViewControllers.count == 1 && isViewLoaded() && blurView.superview == nil else { return }

    addChildViewController(controller)
    let controllerView = controller.view
    controllerView.frame = view.bounds.insetBy(dx: 20, dy: 20)
    controllerView.translatesAutoresizingMaskIntoConstraints = false
    controllerView.backgroundColor = nil
    blurView.contentView.insertSubview(controllerView, atIndex: 0)
    blurView.contentView.constrain(𝗩|--20--controllerView--20--|𝗩, 𝗛|--20--controllerView--20--|𝗛)
    blurView.frame = blurFrame
    UIView.transitionWithView(view,
                     duration: 0.25,
                      options: [.AllowAnimatedContent],
                   animations: {
                    [view = view, blurView = blurView] in
                     view.addSubview(blurView)
                     view.constrain(𝗩|--blurView.frame.y--blurView--(view.bounds.maxY - blurView.frame.maxY)--|𝗩,
                                    𝗛|--blurView.frame.x--blurView--(view.bounds.maxX - blurView.frame.maxX)--|𝗛)
                   },
      completion: { [unowned self] in controller.didMoveToParentViewController(self); completion?($0) })
  }

  /** dismissSecondaryController */
  func dismissSecondaryController(dismissalAction: DismissalAction = .None) {
    guard let controller = secondaryController
      where controller.isViewLoaded() && blurView.superview != nil else { return }
    controller.willMoveToParentViewController(nil)
    controller.removeFromParentViewController()
    let options: UIViewAnimationOptions = [.AllowAnimatedContent]
    let animations = {[unowned self] in controller.view.removeFromSuperview(); self.blurView.removeFromSuperview() }
    let action: (() -> Void)?
    switch dismissalAction {
      case .Cancel:  action = cancelAction
      case .Confirm: action = confirmAction
      case .None:    action = nil
    }
    let completion: (Bool) -> Void = { [unowned self] in if $0 { self.anyAction?(); action?() } }
    UIView.transitionWithView(view, duration: 0.25, options: options, animations: animations, completion: completion)
  }

}