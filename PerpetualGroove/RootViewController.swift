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

  @IBOutlet var topStack: UIStackView!
  @IBOutlet var middleStack: UIStackView!
  @IBOutlet var bottomStack: UIStackView!


  @IBOutlet var topStackHeight: NSLayoutConstraint!
  @IBOutlet var middleStackHeight: NSLayoutConstraint!
  @IBOutlet var bottomStackHeight: NSLayoutConstraint!

  @IBOutlet var mixerContainer: UIView!
  @IBOutlet var noteAttributesContainer: UIView!
  @IBOutlet var instrumentContainer: UIView!
  @IBOutlet var noteAttributesInstrumentStack: UIStackView!

  /**
  animateFromSize:toSize:

  - parameter fromSize: CGSize
  - parameter toSize: CGSize
  */
  private func transitionFromSize(fromSize: CGSize, toSize: CGSize, animated: Bool) {
//    guard fromSize.maxAxis != toSize.maxAxis else { return }
//    layoutForSize(toSize)
//    UIView.animateWithDuration(animated ? 0.25 : 0) { self.layoutForSize(toSize) }
  }

  /**
  layoutForSize:

  - parameter size: CGSize
  */
  private func layoutForSize(size: CGSize) {
    switch size.maxAxis {
      case .Vertical:
        guard topStackHeight.constant == 120 else { return }
        topStackHeight.constant = 430
        topStack.addArrangedSubview(mixerContainer)
        noteAttributesInstrumentStack.axis = .Vertical
        middleStack.insertArrangedSubview(noteAttributesInstrumentStack, atIndex: 0)
        middleStackHeight.constant = 400
      case .Horizontal:
        guard topStackHeight.constant == 430 else { return }
        topStackHeight.constant = 120
        noteAttributesInstrumentStack.axis = .Horizontal
        topStack.addArrangedSubview(noteAttributesInstrumentStack)
        middleStack.insertArrangedSubview(mixerContainer, atIndex: 0)
        middleStackHeight.constant = 430
    }
    noteAttributesInstrumentStack.updateConstraintsIfNeeded()
  }

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tempoSlider.value = Float(Sequencer.tempo)
    metronomeButton.selected = AudioManager.metronome?.on ?? false

    layoutForSize(view.bounds.size)
  }

  /**
  viewDidAppear:

  - parameter animated: Bool
  */
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    guard !SettingsManager.initialized || !SettingsManager.iCloudStorage || NSFileManager.defaultManager().ubiquityIdentityToken != nil else {
      performSegueWithIdentifier("Purgatory", sender: self)
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
    func adjustPopover(popoverView: PopoverView?, _ presentingView: UIView?) {
      guard let popoverView = popoverView, presentingView = presentingView else { return }
      let popoverCenter = view.convertPoint(popoverView.center, fromView: popoverView.superview)
      let presentingCenter = view.convertPoint(presentingView.center, fromView: presentingView.superview)
      popoverView.xOffset = presentingCenter.x - popoverCenter.x
    }

    adjustPopover(documentsPopoverView, documentsButton)
    adjustPopover(noteAttributesPopoverView, noteAttributesButton)
    adjustPopover(mixerPopoverView, mixerButton)
    adjustPopover(tempoPopoverView, tempoButton)
    adjustPopover(instrumentPopoverView, instrumentButton)
  }

  // MARK: Status bar

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  override func prefersStatusBarHidden() -> Bool { return true }

  // MARK: - Popovers

  /**
  prepareForSegue:sender:

  - parameter segue: UIStoryboardSegue
  - parameter sender: AnyObject?
  */
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    super.prepareForSegue(segue, sender: sender)
    switch segue.destinationViewController {
      case let controller as MixerViewController:      mixerViewController          = controller
      case let controller as InstrumentViewController: instrumentViewController     = controller
      case let controller as NoteViewController:       noteAttributesViewController = controller
      case let controller as DocumentsViewController:  documentsViewController      = controller
      case let controller as TempoViewController:      tempoViewController          = controller
      case let controller as MIDIPlayerViewController: playerViewController         = controller
      case let controller as TransportViewController:  transportViewController      = controller
      default:                                         break
    }
  }

  @IBOutlet weak var popoverBlur: UIVisualEffectView!

  /** dismissPopover */
  @IBAction private func dismissPopover() { popover = .None }

  // MARK: Popover enumeration
  private enum Popover {
    case None, Files, Note, Instrument, Mixer, Tempo
    var view: PopoverView? {
      switch self {
        case .Files:      return RootViewController.currentInstance.documentsPopoverView
        case .Note:       return RootViewController.currentInstance.noteAttributesPopoverView
        case .Instrument: return RootViewController.currentInstance.instrumentPopoverView
        case .Mixer:      return RootViewController.currentInstance.mixerPopoverView
        case .Tempo:      return RootViewController.currentInstance.tempoPopoverView
        case .None:       return nil
      }
    }
    var button: ImageButtonView? {
      switch self {
        case .Files:      return RootViewController.currentInstance.documentsButton
        case .Note:       return RootViewController.currentInstance.noteAttributesButton
        case .Instrument: return RootViewController.currentInstance.instrumentButton
        case .Mixer:      return RootViewController.currentInstance.mixerButton
        case .Tempo:      return RootViewController.currentInstance.tempoButton
        case .None:       return nil
      }
    }
  }

  private func updatePopover(newValue: Popover) { popover = popover == newValue ? .None : newValue }

  private var popover = Popover.None {
    didSet {
      guard oldValue != popover else { return }
      oldValue.view?.hidden = true
      oldValue.button?.selected = false
      popover.view?.hidden = false
      popoverBlur?.hidden = popover == .None
    }
  }

  // MARK: - Files

  @IBOutlet weak var documentsButton: ImageButtonView?

  /** documents */
  @IBAction private func documents() {
    if case .Files = popover { popover = .None } else { popover = .Files }
  }

  private(set) weak var documentsViewController: DocumentsViewController! {
    didSet {
      documentsViewController?.dismiss = {[unowned self] in self.popover = .None}
    }
  }

  @IBOutlet private weak var documentsPopoverView: PopoverView!

 // MARK: - Mixer

  @IBOutlet weak var mixerButton: ImageButtonView?
  @IBAction private func mixer() { updatePopover(.Mixer) }
  private(set) var mixerViewController: MixerViewController!
  @IBOutlet private weak var mixerPopoverView: PopoverView?

  // MARK: - Instrument

  @IBOutlet weak var instrumentButton: ImageButtonView?
  @IBAction private func instrument() { updatePopover(.Instrument) }
  private(set) weak var instrumentViewController: InstrumentViewController!
  @IBOutlet private weak var instrumentPopoverView: PopoverView?

  // MARK: - Note

  @IBOutlet weak var noteAttributesButton: ImageButtonView?
  private(set) weak var noteAttributesViewController: NoteViewController!
  @IBAction private func noteAttributes() { updatePopover(.Note) }
  @IBOutlet private weak var noteAttributesPopoverView: PopoverView?

  // MARK: - Tempo

  @IBOutlet weak var tempoButton: ImageButtonView?
  private(set) weak var tempoViewController: TempoViewController?
  @IBAction private func tempo() { updatePopover(.Tempo) }
  @IBOutlet private weak var tempoPopoverView: PopoverView?

  // MARK: - Tempo

  @IBOutlet weak var tempoSlider: Slider!
  @IBOutlet weak var metronomeButton: ImageButtonView!

  /** tempoSliderValueDidChange */
  @IBAction private func tempoSliderValueDidChange() { Sequencer.tempo = Double(tempoSlider.value) }

  /** toggleMetronome */
  @IBAction private func toggleMetronome() { AudioManager.metronome.on = !AudioManager.metronome.on }

  // MARK: - Transport

  @IBOutlet weak var barBeatTimeLabel: BarBeatTimeLabel!


  // MARK: - Player

  private(set) weak var playerViewController: MIDIPlayerViewController!


  // MARK: - Transport
  private(set) weak var transportViewController: TransportViewController!

}

// MARK: - UIContentContainter
extension RootViewController {

  /**
  willTransitionToTraitCollection:withTransitionCoordinator:

  - parameter newCollection: UITraitCollection
  - parameter coordinator: UIViewControllerTransitionCoordinator
  */
  override func willTransitionToTraitCollection(newCollection: UITraitCollection,
                      withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
  {
    logDebug("newCollection: \(newCollection)\ncoordinator: \(coordinator)")
    super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
  }

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
//      case let controller as NoteViewController where controller === noteAttributesViewController:
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
  override func viewWillTransitionToSize(size: CGSize,
               withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
  {

    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

    transitionFromSize(view.bounds.size, toSize: size, animated: true)
  }

}
