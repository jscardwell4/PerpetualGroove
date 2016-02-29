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
  
  private(set) weak var secondaryController: SecondaryContentViewController? {
    didSet {
      guard let controller = secondaryController else { return }

      // Hide or reveal the buttons according to the controller's settings
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

      // Add the controller's view to the blur view content
      let controllerView = controller.view
      controllerView.frame = view.bounds.insetBy(dx: 20, dy: 20)
      controllerView.translatesAutoresizingMaskIntoConstraints = false
      controllerView.backgroundColor = nil

      blurView.contentView.insertSubview(controllerView, atIndex: 0)
      blurView.contentView.constrain(𝗩|--20--controllerView--20--|𝗩, 𝗛|--20--controllerView--20--|𝗛)
      blurView.frame = blurFrame
    }

  }

  @IBOutlet private weak var containerView: UIView!

  var blurFrame: CGRect { guard isViewLoaded() else { return .zero }; return view.bounds }

  private lazy var blurView: UIVisualEffectView = {
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    blurView.userInteractionEnabled = true

    let cancelButton = ImageButtonView(autolayout: true)
    cancelButton.image = UIImage(named: "cancel")
    cancelButton.normalTintColor = .pearlBush
    cancelButton.highlightedTintColor = .mahogany
    cancelButton.identifier = "ConfirmButton"
    cancelButton.accessibilityIdentifier = cancelButton.identifier
    cancelButton.addTarget(self, action: #selector(SecondaryControllerContainerViewController.cancel), forControlEvents: .TouchUpInside)
    blurView.contentView.addSubview(cancelButton)
    blurView.contentView.constrain(𝗩|--cancelButton, 𝗛|--cancelButton)
    self.cancelButton = cancelButton

    let confirmButton = ImageButtonView(autolayout: true)
    confirmButton.image = UIImage(named: "confirm")
    confirmButton.normalTintColor = .pearlBush
    confirmButton.highlightedTintColor = .mahogany
    confirmButton.identifier = "ConfirmButton"
    confirmButton.accessibilityIdentifier = confirmButton.identifier
    confirmButton.addTarget(self, action: #selector(SecondaryControllerContainerViewController.confirm), forControlEvents: .TouchUpInside)
    blurView.contentView.addSubview(confirmButton)
    blurView.contentView.constrain(𝗩|--confirmButton, confirmButton--|𝗛)
    self.confirmButton = confirmButton

    let leftArrow = ImageButtonView(autolayout: true)
    leftArrow.image = UIImage(named: "left_arrow")
    leftArrow.normalTintColor = .pearlBush
    leftArrow.highlightedTintColor = .mahogany
    leftArrow.identifier = "PreviousButton"
    leftArrow.accessibilityIdentifier = leftArrow.identifier
    leftArrow.addTarget(self, action: #selector(SecondaryControllerContainerViewController.previous), forControlEvents: .TouchUpInside)
    blurView.contentView.addSubview(leftArrow)
    blurView.contentView.constrain(leftArrow--|𝗩, 𝗛|--leftArrow)
    self.leftArrow = leftArrow

    let rightArrow = ImageButtonView(autolayout: true)
    rightArrow.image = UIImage(named: "right_arrow")
    rightArrow.normalTintColor = .pearlBush
    rightArrow.highlightedTintColor = .mahogany
    rightArrow.identifier = "NextButton"
    rightArrow.accessibilityIdentifier = rightArrow.identifier
    rightArrow.addTarget(self, action: #selector(SecondaryControllerContainerViewController.next), forControlEvents: .TouchUpInside)
    blurView.contentView.addSubview(rightArrow)
    blurView.contentView.constrain(rightArrow--|𝗩, rightArrow--|𝗛)
    self.rightArrow = rightArrow

    return blurView
  }()

  private weak var confirmButton: ImageButtonView?
  private weak var cancelButton: ImageButtonView?

  weak var leftArrow: ImageButtonView?
  weak var rightArrow: ImageButtonView?

  /** confirm */
  @objc private func confirm() { dismissSecondaryController(.Confirm) }

  /** cancel */
  @objc private func cancel() { dismissSecondaryController(.Cancel) }

  /** next */
  @objc private func next() { nextAction?() }

  /** previous */
  @objc private func previous() { previousAction?() }

  var anyAction: (() -> Void)?      { return secondaryController?.actions.anyAction      }
  var cancelAction: (() -> Void)?   { return secondaryController?.actions.cancelAction   }
  var confirmAction: (() -> Void)?  { return secondaryController?.actions.confirmAction  }
  var nextAction: (() -> Void)?     { return secondaryController?.actions.nextAction     }
  var previousAction: (() -> Void)? { return secondaryController?.actions.previousAction }

  /** refreshNavigationArrows */
  func refreshNavigationArrows() {

  }

  enum DismissalAction { case None, Cancel, Confirm }

  /**
   presentSecondaryController:completion:

   - parameter controller: SecondaryContentViewController
   - parameter completion: ((Bool) -> Void
  */
  func presentSecondaryController(controller: SecondaryContentViewController,
                       completion: ((Bool) -> Void)? = nil)
  {
    guard secondaryController == nil else { return }

    addChildViewController(controller)
    secondaryController = controller


    let options: UIViewAnimationOptions = [.AllowAnimatedContent]

    let animations = {
      [view = view, blurView = blurView] in
      view.addSubview(blurView)
      view.constrain(
        𝗩|--blurView.frame.y--blurView--(view.bounds.maxY - blurView.frame.maxY)--|𝗩,
        𝗛|--blurView.frame.x--blurView--(view.bounds.maxX - blurView.frame.maxX)--|𝗛
      )
    }

    UIView.transitionWithView(view, duration: 0.25, options: options, animations: animations) {
      [unowned self] completed in
      controller.didMoveToParentViewController(self)
      completion?(completed)
    }

  }

  /** dismissSecondaryController */
  func dismissSecondaryController(dismissalAction: DismissalAction = .None) {
    guard let controller = secondaryController else { return }

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

      self.anyAction?()

      switch dismissalAction {
      case .Cancel:
        self.cancelAction?()
      case .Confirm:
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
