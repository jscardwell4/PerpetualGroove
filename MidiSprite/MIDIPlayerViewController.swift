//
//  MIDIPlayerViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

final class MIDIPlayerViewController: UIViewController {

  static var currentInstance: MIDIPlayerViewController? {
    guard let delegate = UIApplication.sharedApplication().delegate,
                window = delegate.window,
            controller = window?.rootViewController as? MIDIPlayerViewController else { return nil }
    return controller
  }

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
    guard fromSize.maxAxis != toSize.maxAxis else { return }
    layoutForSize(toSize)
    UIView.animateWithDuration(animated ? 0.25 : 0) { self.layoutForSize(toSize) }
  }

  /**
  layoutForSize:

  - parameter size: CGSize
  */
  private func layoutForSize(size: CGSize) {
    switch size.maxAxis {
      case .Vertical:
        guard topStackHeight.constant == 120 else { return }
        topStackHeight.constant = 400
        topStack.addArrangedSubview(mixerContainer)
        noteAttributesInstrumentStack.axis = .Vertical
        middleStack.insertArrangedSubview(noteAttributesInstrumentStack, atIndex: 0)
      case .Horizontal:
        guard topStackHeight.constant == 400 else { return }
        topStackHeight.constant = 120
        noteAttributesInstrumentStack.axis = .Horizontal
        topStack.addArrangedSubview(noteAttributesInstrumentStack)
        middleStack.insertArrangedSubview(mixerContainer, atIndex: 0)
    }
    noteAttributesInstrumentStack.updateConstraintsIfNeeded()
  }

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    tempoSlider.value = Float(Sequencer.tempo)
    metronomeButton.selected = AudioManager.metronome.on

    layoutForSize(view.bounds.size)

    initializeReceptionist()
  }

  /**
  viewDidAppear:

  - parameter animated: Bool
  */
  override func viewDidAppear(animated: Bool) {
    guard !NSUserDefaults.standardUserDefaults().boolForKey("iCloudStorage")
        || NSFileManager.defaultManager().ubiquityIdentityToken != nil else
    {
      performSegueWithIdentifier("Purgatory", sender: self)
      return
    }

    guard MIDIDocumentManager.currentDocument == nil && !MIDIDocumentManager.openingDocument else { return }

    do { try MIDIDocumentManager.createNewDocument() } catch { logError(error, message: "Failed to create new document") }
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
      case let controller as MixerViewController:          mixerViewController          = controller
      case let controller as InstrumentViewController:     instrumentViewController     = controller
      case let controller as NoteAttributesViewController: noteAttributesViewController = controller
      case let controller as DocumentsViewController:      documentsViewController      = controller
      case let controller as TempoViewController:          tempoViewController          = controller
      default:                                             break
    }
  }

  @IBOutlet weak var popoverBlur: UIVisualEffectView!

  /** dismissPopover */
  @IBAction private func dismissPopover() { popover = .None }

  // MARK: Popover enumeration
  private enum Popover {
    case None, Files, NoteAttributes, Instrument, Mixer, Tempo
    var view: PopoverView? {
      switch self {
        case .Files:          return MIDIPlayerViewController.currentInstance?.documentsPopoverView
        case .NoteAttributes: return MIDIPlayerViewController.currentInstance?.noteAttributesPopoverView
        case .Instrument:     return MIDIPlayerViewController.currentInstance?.instrumentPopoverView
        case .Mixer:          return MIDIPlayerViewController.currentInstance?.mixerPopoverView
        case .Tempo:          return MIDIPlayerViewController.currentInstance?.tempoPopoverView
        case .None:           return nil
      }
    }
    var button: ImageButtonView? {
      switch self {
        case .Files:          return MIDIPlayerViewController.currentInstance?.documentsButton
        case .NoteAttributes: return MIDIPlayerViewController.currentInstance?.noteAttributesButton
        case .Instrument:     return MIDIPlayerViewController.currentInstance?.instrumentButton
        case .Mixer:          return MIDIPlayerViewController.currentInstance?.mixerButton
        case .Tempo:          return MIDIPlayerViewController.currentInstance?.tempoButton
        case .None:           return nil
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
      if popover == .None { state ∖= [.Popover] } else { state ∪= [.Popover] }
    }
  }

  // MARK: - Files

  @IBOutlet weak var documentsButton: ImageButtonView?
  @IBOutlet weak var documentName: UITextField!

  /** documents */
  @IBAction private func documents() {
    if case .Files = popover { popover = .None } else { popover = .Files }
  }

  private weak var documentsViewController: DocumentsViewController! {
    didSet {
      documentsViewController?.dismiss = {[unowned self] in self.popover = .None}
    }
  }

  @IBOutlet private weak var documentsPopoverView: PopoverView!

 // MARK: - Mixer

  @IBOutlet weak var mixerButton: ImageButtonView?
  @IBAction private func mixer() { updatePopover(.Mixer) }
  private weak var mixerViewController: MixerViewController!
  @IBOutlet private weak var mixerPopoverView: PopoverView?

  // MARK: - Instrument

  @IBOutlet weak var instrumentButton: ImageButtonView?
  @IBAction private func instrument() { updatePopover(.Instrument) }
  private weak var instrumentViewController: InstrumentViewController!
  @IBOutlet private weak var instrumentPopoverView: PopoverView?

  // MARK: - NoteAttributes

  @IBOutlet weak var noteAttributesButton: ImageButtonView?
  private weak var noteAttributesViewController: NoteAttributesViewController!
  @IBAction private func noteAttributes() { updatePopover(.NoteAttributes) }
  @IBOutlet private weak var noteAttributesPopoverView: PopoverView?

  // MARK: - Tempo

  @IBOutlet weak var tempoButton: ImageButtonView?
  private weak var tempoViewController: TempoViewController?
  @IBAction private func tempo() { updatePopover(.Tempo) }
  @IBOutlet private weak var tempoPopoverView: PopoverView?

  // MARK: - Undo

//  @IBOutlet weak var revertButton: ImageButtonView!
  @IBAction private func revert() { midiPlayerView.revert() }

  // MARK: - Tempo

  @IBOutlet weak var tempoSlider: Slider!
  @IBOutlet weak var metronomeButton: ImageButtonView!

  /** tempoSliderValueDidChange */
  @IBAction private func tempoSliderValueDidChange() { Sequencer.tempo = Double(tempoSlider.value) }

  /** toggleMetronome */
  @IBAction private func toggleMetronome() { AudioManager.metronome.on = !AudioManager.metronome.on }

  // MARK: - Transport

  @IBOutlet weak var transportStack: UIStackView!
  @IBOutlet weak var recordButton: ImageButtonView!
  @IBOutlet weak var playPauseButton: ImageButtonView!
  @IBOutlet weak var stopButton: ImageButtonView!
  @IBOutlet weak var barBeatTimeLabel: BarBeatTimeLabel!
  @IBOutlet weak var jogWheel: ScrollWheel!

  /** record */
  @IBAction func record() { Sequencer.toggleRecord() }

  /** playPause */
  @IBAction func playPause() { if state ∋ .Playing { pause() } else { play() } }

  /** play */
  func play() { Sequencer.play() }

  /** pause */
  func pause() { Sequencer.pause() }

  /** stop */
  @IBAction func stop() { Sequencer.reset() }

  /** beginJog */
  @IBAction private func beginJog(){ Sequencer.beginJog() }

  /** jog */
  @IBAction private func jog() { Sequencer.jog(jogWheel.revolutions) }

  /** endJog */
  @IBAction private func endJog() { Sequencer.endJog() }

  private enum ControlImage {
    case Pause, Play
    func decorateButton(item: ImageButtonView) {
      item.image = image
      item.highlightedImage = selectedImage
    }
    var image: UIImage {
      switch self {
        case .Pause: return UIImage(named: "pause")!
        case .Play: return UIImage(named: "play")!
      }
    }
    var selectedImage: UIImage {
      switch self {
        case .Pause: return UIImage(named: "pause-selected")!
        case .Play: return UIImage(named: "play-selected")!
      }
    }
  }

  // MARK: - Scene-relatd properties

  @IBOutlet weak var midiPlayerView: MIDIPlayerView!

  // MARK: - Managing state

  private var notificationReceptionist: NotificationReceptionist?

  /** initializeReceptionist */
  private func initializeReceptionist() {

    guard notificationReceptionist == nil else { return }

    notificationReceptionist = NotificationReceptionist()

    let queue = NSOperationQueue.mainQueue()

    notificationReceptionist?.observe(Sequencer.Notification.DidPause, from: Sequencer.self, queue: queue) {
      [weak self] _ in self?.state ⊻= [.Playing, .Paused]
    }

    notificationReceptionist?.observe(Sequencer.Notification.DidStart, from: Sequencer.self, queue: queue) {
      [weak self] _ in self?.state ⊻= self!.state ∋ .Paused ? [.Playing, .Paused] : [.Playing]
    }

    notificationReceptionist?.observe(Sequencer.Notification.DidStart, from: Sequencer.self, queue: queue) {
      [weak self] _ in self?.state ∖= [.Playing, .Paused]
    }

    notificationReceptionist?.observe(MIDIDocumentManager.Notification.DidChangeCurrentDocument,
                                 from: MIDIDocumentManager.self,
                                queue: queue)
    {
        [weak self] _ in self?.documentName.text = MIDIDocumentManager.currentDocument?.localizedName
    }

    notificationReceptionist?.observe(UIKeyboardWillShowNotification, from: nil, queue: queue) {
      [weak self] in
      guard let size = ($0.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size,
                responder = self?.view.firstResponder,
                window = self?.view.window,
                superview = responder.superview else
      {
        return
      }
      let h = window.bounds.height
      let location = CGPoint(x: responder.frame.minX, y: responder.frame.maxY)
      let locationʹ = window.convertPoint(location, fromView: superview)
      let hʹ = h - locationʹ.y

      self?.view.transform.ty = min(hʹ - size.height, 0)
    }

    notificationReceptionist?.observe(UIKeyboardDidHideNotification, from: nil, queue: queue) {
      [weak self] _ in self?.view.transform.ty = 0
    }
    
  }

  private struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    static let Popover     = State(rawValue: 0b0000_0001)
    static let Playing     = State(rawValue: 0b0000_0010)
    static let Recording   = State(rawValue: 0b0000_0100)
    static let Paused      = State(rawValue: 0b0000_1000)
    static let Jogging     = State(rawValue: 0b0001_0000)

    var description: String {
      var result = "MIDIPlayerViewController.State { "
      var flagStrings: [String] = []
      if self ∋ .Popover     { flagStrings.append("Popover")     }
      if self ∋ .Playing     { flagStrings.append("Playing")     }
      if self ∋ .Recording   { flagStrings.append("Recording")   }
      if self ∋ .Paused      { flagStrings.append("Paused")      }
      if self ∋ .Jogging     { flagStrings.append("Jogging")     }

      result += ", ".join(flagStrings)
      result += " }"
      return result
    }
  }

  var paused: Bool { return state ∋ .Paused }
  var playing: Bool { return state ∋ .Playing }
  var recording: Bool { return state ∋ .Recording }
  var jogging: Bool { return state ∋ .Jogging }

  private var state: State = [] {
    didSet {
      guard isViewLoaded() && state != oldValue else { return }
      guard state ∌ [.Playing, .Paused] else { fatalError("State invalid: cannot be both playing and paused") }

      logVerbose("didSet…old state: \(oldValue); new state: \(state)")

      let modifiedState = state ⊻ oldValue

      // Check if popover state has changed
      if modifiedState ∋ .Popover { popoverBlur?.hidden = state ∌ .Popover }

      // Check if jog status changed
      if modifiedState ∋ .Jogging { transportStack.userInteractionEnabled = !jogging }

      // Check for recording status change
      if modifiedState ∋ .Recording { recordButton.selected = recording }

      // Check if play/pause status changed
      if modifiedState ~∩ [.Playing, .Paused] {
        stopButton.enabled = playing || paused
        (playing ? ControlImage.Pause : ControlImage.Play).decorateButton(playPauseButton)
      }
    }
  }

}

// MARK: - UIContentContainter
extension MIDIPlayerViewController {

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
//      case let controller as NoteAttributesViewController where controller === noteAttributesViewController:
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

extension MIDIPlayerViewController: UITextFieldDelegate {

  /**
  textFieldShouldBeginEditing:

  - parameter textField: UITextField

  - returns: Bool
  */
  func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
    return MIDIDocumentManager.currentDocument != nil
  }

  /**
  textFieldShouldReturn:

  - parameter textField: UITextField

  - returns: Bool
  */
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return false
  }

  /**
  textFieldShouldEndEditing:

  - parameter textField: UITextField

  - returns: Bool
  */
  func textFieldShouldEndEditing(textField: UITextField) -> Bool {
    guard let text = textField.text,
              fileName = MIDIDocumentManager.noncollidingFileName(text) else { return false }
    if text != fileName { textField.text = fileName }
    return true
  }

  /**
  textFieldDidEndEditing:

  - parameter textField: UITextField
  */
  func textFieldDidEndEditing(textField: UITextField) {
    guard let text = textField.text else { return }
    MIDIDocumentManager.currentDocument?.renameTo(text)
  }
}