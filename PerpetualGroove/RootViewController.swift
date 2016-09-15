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

final class RootViewController: UIViewController {

  static var currentInstance: RootViewController { return AppDelegate.currentInstance.viewController }

  // MARK: - View loading and layout

  @IBOutlet var contentStack: UIStackView!
  @IBOutlet var topStack: UIStackView!
  @IBOutlet var middleStack: UIStackView!
  @IBOutlet var bottomStack: UIStackView!


  @IBOutlet var topStackHeight: NSLayoutConstraint!
  @IBOutlet var middleStackHeight: NSLayoutConstraint!
  @IBOutlet var bottomStackHeight: NSLayoutConstraint!

  @IBOutlet var mixerContainer: UIView!
  @IBOutlet var generatorContainer: UIView!
  @IBOutlet var instrumentContainer: UIView!
  @IBOutlet var generatorInstrumentStack: UIStackView!

  /**
  animateFromSize:toSize:

  - parameter fromSize: CGSize
  - parameter toSize: CGSize
  */
//  private func transitionFromSize(fromSize: CGSize, toSize: CGSize, animated: Bool) {
//    guard fromSize.maxAxis != toSize.maxAxis else { return }
//    layoutForSize(toSize)
//    UIView.animateWithDuration(animated ? 0.25 : 0) { self.layoutForSize(toSize) }
//  }

  /**
  layoutForSize:

  - parameter size: CGSize
  */
//  private func layoutForSize(size: CGSize) {
//    switch size.maxAxis {
//      case .Vertical:
//        guard topStackHeight.constant == 120 else { return }
//        topStackHeight.constant = 430
//        topStack.addArrangedSubview(mixerContainer)
//        generatorInstrumentStack.axis = .Vertical
//        middleStack.insertArrangedSubview(generatorInstrumentStack, atIndex: 0)
//        middleStackHeight.constant = 400
//      case .Horizontal:
//        guard topStackHeight.constant == 430 else { return }
//        topStackHeight.constant = 120
//        generatorInstrumentStack.axis = .Horizontal
//        topStack.addArrangedSubview(generatorInstrumentStack)
//        middleStack.insertArrangedSubview(mixerContainer, atIndex: 0)
//        middleStackHeight.constant = 430
//    }
//    generatorInstrumentStack.updateConstraintsIfNeeded()
//  }

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    contentStack.bringSubview(toFront: middleStack)
    tempoSlider.value = Float(Sequencer.tempo)
    metronomeButton.isSelected = AudioManager.metronome?.on ?? false

//    layoutForSize(view.bounds.size)
  }

  /**
  viewDidAppear:

  - parameter animated: Bool
  */
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    guard !SettingsManager.initialized || !SettingsManager.iCloudStorage || FileManager.default.ubiquityIdentityToken != nil else {
      performSegue(withIdentifier: "Purgatory", sender: self)
      return
    }
  }


  /** viewDidLayoutSubviews */
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    /**
    Helper function for adjusting the `xOffset` property of the popover views

    - parameter popoverView: PopoverView
    - parameter presentingView: UIView
    */
    func adjustPopover(_ popoverView: PopoverView?, _ presentingView: UIView?) {
      guard let popoverView = popoverView, let presentingView = presentingView else { return }
      let popoverCenter = view.convert(popoverView.center, from: popoverView.superview)
      let presentingCenter = view.convert(presentingView.center, from: presentingView.superview)
      popoverView.xOffset = presentingCenter.x - popoverCenter.x
    }

    adjustPopover(documentsPopoverView, documentsButton)
//    adjustPopover(generatorPopoverView, generatorButton)
//    adjustPopover(mixerPopoverView, mixerButton)
//    adjustPopover(tempoPopoverView, tempoButton)
//    adjustPopover(instrumentPopoverView, instrumentButton)
  }

  // MARK: Status bar

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  override var prefersStatusBarHidden : Bool { return true }

  // MARK: - Popovers

  /**
  prepareForSegue:sender:

  - parameter segue: UIStoryboardSegue
  - parameter sender: AnyObject?
  */
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)
    switch segue.destination {
      case let controller as MixerViewController:      mixerViewController      = controller
      case let controller as InstrumentViewController: instrumentViewController = controller
      case let controller as GeneratorViewController:  generatorViewController  = controller
      case let controller as DocumentsViewController:  documentsViewController  = controller
      case let controller as TempoViewController:      tempoViewController      = controller
      case let controller as MIDIPlayerViewController: playerViewController     = controller
      case let controller as TransportViewController:  transportViewController  = controller
      default:                                         break
    }
  }

  @IBOutlet weak var popoverBlur: UIVisualEffectView!

  /** dismissPopover */
  @IBAction fileprivate func dismissPopover() { popover = .none }

  // MARK: Popover enumeration
  fileprivate enum Popover {
    case none, files, note, instrument, mixer, tempo
    var view: PopoverView? {
      switch self {
        case .files:      return RootViewController.currentInstance.documentsPopoverView
        case .note:       return RootViewController.currentInstance.generatorPopoverView
        case .instrument: return RootViewController.currentInstance.instrumentPopoverView
        case .mixer:      return RootViewController.currentInstance.mixerPopoverView
        case .tempo:      return RootViewController.currentInstance.tempoPopoverView
        case .none:       return nil
      }
    }
    var button: ImageButtonView? {
      switch self {
        case .files:      return RootViewController.currentInstance.documentsButton
        case .note:       return RootViewController.currentInstance.generatorButton
        case .instrument: return RootViewController.currentInstance.instrumentButton
        case .mixer:      return RootViewController.currentInstance.mixerButton
        case .tempo:      return RootViewController.currentInstance.tempoButton
        case .none:       return nil
      }
    }
  }

  fileprivate func updatePopover(_ newValue: Popover) { popover = popover == newValue ? .none : newValue }

  fileprivate var popover = Popover.none {
    didSet {
      guard oldValue != popover else { return }
      oldValue.view?.isHidden = true
      oldValue.button?.isSelected = false
      popover.view?.isHidden = false
      popoverBlur?.isHidden = popover == .none
    }
  }

  // MARK: - Files

  @IBOutlet weak var documentsButton: ImageButtonView?

  /** documents */
  @IBAction fileprivate func documents() {
    if case .files = popover { popover = .none } else { popover = .files }
  }

  fileprivate(set) weak var documentsViewController: DocumentsViewController! {
    didSet {
      documentsViewController?.dismiss = {[unowned self] in self.popover = .none}
    }
  }

  @IBOutlet fileprivate weak var documentsPopoverView: PopoverView!

 // MARK: - Mixer

  @IBOutlet weak var mixerButton: ImageButtonView?
  @IBAction fileprivate func mixer() { updatePopover(.mixer) }
  fileprivate(set) var mixerViewController: MixerViewController!
  @IBOutlet fileprivate weak var mixerPopoverView: PopoverView?

  // MARK: - Instrument

  @IBOutlet weak var instrumentButton: ImageButtonView?
  @IBAction fileprivate func instrument() { updatePopover(.instrument) }
  fileprivate(set) weak var instrumentViewController: InstrumentViewController!
  @IBOutlet fileprivate weak var instrumentPopoverView: PopoverView?

  // MARK: - Note

  @IBOutlet weak var generatorButton: ImageButtonView?
  fileprivate(set) weak var generatorViewController: GeneratorViewController!
  @IBAction fileprivate func generator() { updatePopover(.note) }
  @IBOutlet fileprivate weak var generatorPopoverView: PopoverView?

  // MARK: - Tempo

  @IBOutlet weak var tempoButton: ImageButtonView?
  fileprivate(set) weak var tempoViewController: TempoViewController?
  @IBAction fileprivate func tempo() { updatePopover(.tempo) }
  @IBOutlet fileprivate weak var tempoPopoverView: PopoverView?

  // MARK: - Tempo

  @IBOutlet weak var tempoSlider: Slider!
  @IBOutlet weak var metronomeButton: ImageButtonView!

  /** tempoSliderValueDidChange */
  @IBAction fileprivate func tempoSliderValueDidChange() { Sequencer.tempo = Double(tempoSlider.value) }

  /** toggleMetronome */
  @IBAction fileprivate func toggleMetronome() { AudioManager.metronome.on = !AudioManager.metronome.on }

  // MARK: - Transport

  weak var barBeatTimeLabel: BarBeatTimeLabel!


  // MARK: - Player

  fileprivate(set) weak var playerViewController: MIDIPlayerViewController!

  // MARK: - Transport
  fileprivate(set) weak var transportViewController: TransportViewController!

}

// MARK: - UIContentContainter
extension RootViewController {

  /**
  willTransitionToTraitCollection:withTransitionCoordinator:

  - parameter newCollection: UITraitCollection
  - parameter coordinator: UIViewControllerTransitionCoordinator
  */
//  override func willTransitionToTraitCollection(newCollection: UITraitCollection,
//                      withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
//  {
//    logDebug("newCollection: \(newCollection)\ncoordinator: \(coordinator)")
//    super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
//  }

  /**
  sizeForChildContentContainer:withParentContainerSize:

  - parameter container: UIContentContainer
  - parameter parentSize: CGSize

  - returns: CGSize
  */
//  override func sizeForChildContentContainer(container: UIContentContainer,
//                     withParentContainerSize parentSize: CGSize) -> CGSize
//  {
//    var containerDescription = "container: \(container)"
//    switch container {
//      case let controller as InstrumentViewController where controller === instrumentViewController:
//        containerDescription += "instrument"
//      case let controller as MixerViewController where controller === mixerViewController:
//        containerDescription += "instrument"
//      case let controller as GeneratorViewController where controller === generatorViewController:
//        containerDescription += "instrument"
//      case let controller as TempoViewController where controller === tempoViewController:
//        containerDescription += "instrument"
//      default:
//        containerDescription += "unidentified"
//    }
//    let size = super.sizeForChildContentContainer(container, withParentContainerSize: parentSize)
//    logDebug("\(containerDescription)\nparentSize: \(parentSize)\nsize: \(size)")
//    return size
//  }

  /**
  viewWillTransitionToSize:withTransitionCoordinator:

  - parameter size: CGSize
  - parameter coordinator: UIViewControllerTransitionCoordinator
  */
//  override func viewWillTransitionToSize(size: CGSize,
//               withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
//  {
//
//    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
//
//    transitionFromSize(view.bounds.size, toSize: size, animated: true)
//  }

}
