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

protocol SecondaryControllerContentType: class {
  var showsCancelButton: Bool { get }
  var showsConfirmButton: Bool { get }
  var showsNavigationArrows: Bool { get }
  var navigationArrows: SecondaryControllerContainerViewController.NavigationArrows { get }
  var actions: SecondaryControllerContainerViewController.SecondaryContentActions { get }
}

extension SecondaryControllerContentType {
  var showsCancelButton: Bool { return true }
  var showsConfirmButton: Bool { return true }
  var showsNavigationArrows: Bool { return false }
  var navigationArrows: SecondaryControllerContainerViewController.NavigationArrows { return .None }
  var actions: SecondaryControllerContainerViewController.SecondaryContentActions {
    return SecondaryControllerContainerViewController.SecondaryContentActions()
  }
}

class SecondaryControllerContainerViewController: UIViewController {

  var primaryController: UIViewController? { return childViewControllers.first }
  var secondaryController: UIViewController? { return secondaryContentController as? UIViewController }

  @IBOutlet private weak var containerView: UIView!

//  @IBOutlet private var blurView: UIVisualEffectView!

  private lazy var blurView: UIVisualEffectView! = {
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    blurView.userInteractionEnabled = true
    return blurView
  }()

  @IBOutlet private weak var confirmButton: ImageButtonView?
  @IBOutlet private weak var cancelButton: ImageButtonView?

  @IBOutlet weak var leftArrow: ImageButtonView?
  @IBOutlet weak var rightArrow: ImageButtonView?

  /** confirm */
  @IBAction private func confirm() { dismissSecondaryController(.Confirm) }

  /** cancel */
  @IBAction private func cancel() { dismissSecondaryController(.Cancel) }

  /** next */
  @IBAction private func next() { nextAction?(); secondaryContentActions?.nextAction?() }

  /** previous */
  @IBAction private func previous() { previousAction?(); secondaryContentActions?.previousAction?() }

  private var secondaryContentActions: SecondaryContentActions?

  var anyAction: (() -> Void)? { return secondaryContentActions?.anyAction }
  var cancelAction: (() -> Void)? { return secondaryContentActions?.cancelAction }
  var confirmAction: (() -> Void)? { return secondaryContentActions?.confirmAction }
  var nextAction: (() -> Void)? { return secondaryContentActions?.nextAction }
  var previousAction: (() -> Void)? { return secondaryContentActions?.previousAction }

  /** refreshNavigationArrows */
  func refreshNavigationArrows() {

  }

  var navigationArrows: SecondaryControllerContainerViewController.NavigationArrows = .None {
    didSet {
      guard oldValue != navigationArrows
        && (navigationArrows == .None || (leftArrow != nil && rightArrow != nil) ) else { return }
      leftArrow?.enabled = navigationArrows ∋ .Previous
      rightArrow?.enabled = navigationArrows ∋ .Next
    }
}

  enum DismissalAction { case None, Cancel, Confirm }

  var blurFrame: CGRect { guard isViewLoaded() else { return .zero }; return view.bounds }

  private(set) weak var secondaryContentController: SecondaryControllerContentType? {
    didSet {
      if let controller = secondaryContentController {
        secondaryContentActions = controller.actions
        cancelButton?.hidden = !controller.showsCancelButton
        confirmButton?.hidden = !controller.showsConfirmButton
        if controller.showsNavigationArrows {
          leftArrow?.hidden = false
          rightArrow?.hidden = false
          leftArrow?.enabled = controller.navigationArrows ∋ .Previous
          rightArrow?.enabled = controller.navigationArrows ∋ .Next
        } else {
          leftArrow?.hidden = true
          rightArrow?.hidden = true
        }
      } else {
        secondaryContentActions = nil
      }
    }
  }

  /**
   presentSecondaryController:completion:

   - parameter controller: T
   - parameter completion: ((Bool) -> Void
  */
  func presentSecondaryController<T:UIViewController
    where T:SecondaryControllerContentType>(controller: T, completion: ((Bool) -> Void)? = nil)
  {
    guard childViewControllers.count == 1 && isViewLoaded() && blurView.superview == nil else { return }

    secondaryContentController = controller

    addChildViewController(controller)

    let controllerView = controller.view
    controllerView.frame = view.bounds.insetBy(dx: 20, dy: 20)
    controllerView.translatesAutoresizingMaskIntoConstraints = false
    controllerView.backgroundColor = nil

    blurView.contentView.insertSubview(controllerView, atIndex: 0)
    blurView.contentView.constrain(𝗩|--20--controllerView--20--|𝗩, 𝗛|--20--controllerView--20--|𝗛)
    blurView.frame = blurFrame

    let animations = {
      [view = view, blurView = blurView] in
      view.addSubview(blurView)
      view.constrain(
        𝗩|--blurView.frame.y--blurView--(view.bounds.maxY - blurView.frame.maxY)--|𝗩,
        𝗛|--blurView.frame.x--blurView--(view.bounds.maxX - blurView.frame.maxX)--|𝗛
      )
    }

    UIView.transitionWithView(view, duration: 0.25, options: [.AllowAnimatedContent], animations: animations) {
      [unowned self] completed in
      controller.didMoveToParentViewController(self)
      completion?(completed)
    }

  }

  /** dismissSecondaryController */
  func dismissSecondaryController(dismissalAction: DismissalAction = .None) {
    guard let controller = secondaryController
      where controller.isViewLoaded() && blurView.superview != nil else { return }

    controller.willMoveToParentViewController(nil)
    controller.removeFromParentViewController()

    let options: UIViewAnimationOptions = [.AllowAnimatedContent]

    let animations = {
      [unowned self] in
      controller.view.removeFromSuperview()
      self.blurView.removeFromSuperview()
    }

    let completion: (Bool) -> Void = {
      [unowned self] completed in
      guard completed else { return }

      self.secondaryContentActions?.anyAction?()
      self.anyAction?()

      switch dismissalAction {
      case .Cancel:
        self.secondaryContentActions?.cancelAction?()
        self.cancelAction?()
      case .Confirm:
        self.secondaryContentActions?.confirmAction?()
        self.confirmAction?()
      case .None:
        break
      }
    }

    UIView.transitionWithView(view,
                     duration: 0.25,
                      options: options,
                   animations: animations,
                   completion: completion)
  }

}

extension SecondaryControllerContainerViewController {
  struct SecondaryContentActions {
    var anyAction: (() -> Void)?
    var cancelAction: (() -> Void)?
    var confirmAction: (() -> Void)?
    var nextAction: (() -> Void)?
    var previousAction: (() -> Void)?
  }
}

extension SecondaryControllerContainerViewController {
  struct NavigationArrows: OptionSetType {
    let rawValue: Int
    static let None     = NavigationArrows(rawValue: 0b00)
    static let Previous = NavigationArrows(rawValue: 0b01)
    static let Next     = NavigationArrows(rawValue: 0b10)
  }
}
