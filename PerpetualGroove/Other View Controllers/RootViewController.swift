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

/*  fileprivate func transition(fromSize: CGSize, toSize: CGSize, animated: Bool) {
    guard fromSize.maxAxis != toSize.maxAxis else { return }
    layout(forSize: toSize)
    UIView.animate(withDuration: animated ? 0.25 : 0) { self.layout(forSize: toSize) }
  }

  private func layout(forSize size: CGSize) {
    switch size.maxAxis {
      case .vertical:
        guard topStackHeight.constant == 120 else { return }
        topStackHeight.constant = 430
        topStack.addArrangedSubview(mixerContainer)
        generatorInstrumentStack.axis = .vertical
        middleStack.insertArrangedSubview(generatorInstrumentStack, at: 0)
        middleStackHeight.constant = 400
      case .horizontal:
        guard topStackHeight.constant == 430 else { return }
        topStackHeight.constant = 120
        generatorInstrumentStack.axis = .horizontal
        topStack.addArrangedSubview(generatorInstrumentStack)
        middleStack.insertArrangedSubview(mixerContainer, at: 0)
        middleStackHeight.constant = 430
    }
    generatorInstrumentStack.updateConstraintsIfNeeded()
  }
*/

  override func viewDidLoad() {
    super.viewDidLoad()

    contentStack.bringSubview(toFront: middleStack)
    tempoSlider.value = Float(Sequencer.tempo)
    metronomeButton.isSelected = AudioManager.metronome?.on ?? false

//    layout(forSize: view.bounds.size)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    assert(SettingsManager.initialized)

    guard SettingsManager.iCloudStorage && FileManager.default.ubiquityIdentityToken == nil else { return }

    performSegue(withIdentifier: "Purgatory", sender: self)
  }


  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // Helper function for adjusting the `xOffset` property of the popover views
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

  override var prefersStatusBarHidden : Bool { return true }

  // MARK: - Popovers

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)

    switch segue.destination {

      case let controller as MixerViewController:          mixerViewController      = controller
      case let controller as InstrumentViewController:     instrumentViewController = controller
      case let controller as GeneratorViewController:      generatorViewController  = controller
      case let controller as DocumentsViewController:      documentsViewController  = controller
      case let controller as TempoViewController:          tempoViewController      = controller
      case let controller as MIDINodePlayerViewController: playerViewController     = controller
      case let controller as TransportViewController:      transportViewController  = controller
      default:                                             break

    }

  }

  @IBOutlet weak var popoverBlur: UIVisualEffectView!

  @IBAction private func dismissPopover() { popover = .none }

  private func updatePopover(_ newValue: Popover) { popover = popover == newValue ? .none : newValue }

  private var popover = Popover.none {
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

  @IBAction private func documents() {
    if case .files = popover { popover = .none } else { popover = .files }
  }

  private(set) weak var documentsViewController: DocumentsViewController! {
    didSet {
      documentsViewController?.dismiss = {[unowned self] in self.popover = .none}
    }
  }

  @IBOutlet fileprivate weak var documentsPopoverView: PopoverView!

 // MARK: - Mixer

  @IBOutlet weak var mixerButton: ImageButtonView?

  @IBAction private func mixer() { updatePopover(.mixer) }

  private(set) var mixerViewController: MixerViewController!

  @IBOutlet fileprivate weak var mixerPopoverView: PopoverView?

  // MARK: - Instrument

  @IBOutlet weak var instrumentButton: ImageButtonView?

  @IBAction private func instrument() { updatePopover(.instrument) }

  private(set) weak var instrumentViewController: InstrumentViewController!

  @IBOutlet fileprivate weak var instrumentPopoverView: PopoverView?

  // MARK: - Note

  @IBOutlet weak var generatorButton: ImageButtonView?

  private(set) weak var generatorViewController: GeneratorViewController!

  @IBAction private func generator() { updatePopover(.note) }

  @IBOutlet fileprivate weak var generatorPopoverView: PopoverView?

  // MARK: - Tempo

  @IBOutlet weak var tempoButton: ImageButtonView?

  private(set) weak var tempoViewController: TempoViewController?

  @IBAction private func tempo() { updatePopover(.tempo) }

  @IBOutlet fileprivate weak var tempoPopoverView: PopoverView?

  @IBOutlet weak var tempoSlider: Slider!

  @IBAction private func tempoSliderValueDidChange() {
    Sequencer.tempo = Double(tempoSlider.value)
  }

  // MARK: - Player

  private(set) weak var playerViewController: MIDINodePlayerViewController!

  // MARK: - Transport

  private(set) weak var transportViewController: TransportViewController!

  weak var barBeatTimeLabel: BarBeatTimeLabel!

  @IBOutlet weak var metronomeButton: ImageButtonView!

  @IBAction private func toggleMetronome() {
    AudioManager.metronome.on = !AudioManager.metronome.on
  }

}

extension RootViewController {

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

}

/*extension RootViewController {

  override func willTransition(to newCollection: UITraitCollection,
                               with coordinator: UIViewControllerTransitionCoordinator)
  {
    logDebug("newCollection: \(newCollection)\ncoordinator: \(coordinator)")
    super.willTransition(to: newCollection, with: coordinator)
  }

  override func size(forChildContentContainer container: UIContentContainer,
                     withParentContainerSize parentSize: CGSize) -> CGSize
  {
    var containerDescription = "container: \(container)"
    switch container {
      case let controller as InstrumentViewController where controller === instrumentViewController:
        containerDescription += "instrument"
      case let controller as MixerViewController where controller === mixerViewController:
        containerDescription += "instrument"
      case let controller as GeneratorViewController where controller === generatorViewController:
        containerDescription += "instrument"
      case let controller as TempoViewController where controller === tempoViewController:
        containerDescription += "instrument"
      default:
        containerDescription += "unidentified"
    }
    let size = super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
    logDebug("\(containerDescription)\nparentSize: \(parentSize)\nsize: \(size)")
    return size
  }

  override func viewWillTransition(to size: CGSize,
               with coordinator: UIViewControllerTransitionCoordinator)
  {

    super.viewWillTransition(to: size, with: coordinator)

    transition(fromSize: view.bounds.size, toSize: size, animated: true)
  }

}
*/
