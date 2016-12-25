//
//  RootViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 11/27/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

// TODO: Review file

final class RootViewController: UIViewController {

  static var currentInstance: RootViewController { return AppDelegate.currentInstance.viewController }

  // MARK: - View loading and layout

  @IBOutlet var contentStack: UIStackView!
  @IBOutlet var middleStack: UIStackView!
  @IBOutlet var bottomStack: UIStackView!

  @IBOutlet var middleStackHeight: NSLayoutConstraint!
  @IBOutlet var bottomStackHeight: NSLayoutConstraint!

  @IBOutlet var mixerContainer: UIView!
  @IBOutlet var midiNodePlayerContainer: UIView!
  @IBOutlet var transportContainer: UIView!
  @IBOutlet var tempoContainer: UIView!

  override func viewDidLoad() {
    super.viewDidLoad()

    contentStack.bringSubview(toFront: middleStack)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    assert(SettingsManager.initialized)

    guard SettingsManager.iCloudStorage && FileManager.default.ubiquityIdentityToken == nil else { return }

    performSegue(withIdentifier: "Purgatory", sender: self)
  }


  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    guard let popoverView = documentsPopoverView, let presentingView = documentsButton else { return }
    let popoverCenter = view.convert(popoverView.center, from: popoverView.superview)
    let presentingCenter = view.convert(presentingView.center, from: presentingView.superview)
    popoverView.xOffset = presentingCenter.x - popoverCenter.x

  }

  // MARK: Status bar

  override var prefersStatusBarHidden : Bool { return true }

  // MARK: - Popovers

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)

    switch segue.destination {

      case let controller as MixerViewController:          mixerViewController      = controller
      case let controller as DocumentsViewController:      documentsViewController  = controller
      case let controller as TempoViewController:          tempoViewController      = controller
      case let controller as MIDINodePlayerViewController: playerViewController     = controller
      case let controller as TransportViewController:      transportViewController  = controller
      default:                                             break

    }

  }

  @IBAction private func dismissPopover() { popover = .none }

  private func updatePopover(_ newValue: Popover) { popover = popover == newValue ? .none : newValue }

  private var popover = Popover.none {
    didSet {
      guard oldValue != popover else { return }
      oldValue.view?.isHidden = true
      oldValue.button?.isSelected = false
      popover.view?.isHidden = false
    }
  }

  // MARK: - Files

  @IBOutlet weak var documentsButton: ImageButtonView?

  @IBAction private func documents() {
    if case .files = popover { popover = .none } else { popover = .files }
  }

  private(set) weak var documentsViewController: DocumentsViewController! {
    didSet {
      documentsViewController?.dismiss = {[unowned self] in self.popover = .none}
    }
  }

  @IBOutlet fileprivate weak var documentsPopoverView: PopoverView!

  private(set) var mixerViewController: MixerViewController!
  private(set) weak var tempoViewController: TempoViewController!
  private(set) weak var playerViewController: MIDINodePlayerViewController!
  private(set) weak var transportViewController: TransportViewController!

}

extension RootViewController {

  fileprivate enum Popover {
    case none, files
    var view: PopoverView? {
      switch self {
      case .files:      return RootViewController.currentInstance.documentsPopoverView
      case .none:       return nil
      }
    }
    var button: ImageButtonView? {
      switch self {
      case .files:      return RootViewController.currentInstance.documentsButton
      case .none:       return nil
      }
    }
  }

}
