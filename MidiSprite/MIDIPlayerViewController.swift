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

  // MARK: - UIViewController overridden methods -

  // MARK: View loading and layout

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    midiPlayerSceneView.ignoresSiblingOrder = true

    midiPlayerSceneView.presentScene(MIDIPlayerScene(size: midiPlayerSceneView.bounds.size))
    playerScene.paused = true

    fileTrackNameLabel.text = nil

    initializeReceptionist()

    logDebug(view.viewTreeDescription,/* "\n".join(view.constraints.map({$0.description})), separator: "\n\n",*/ asynchronous: false)

  }

  /** viewDidLayoutSubviews */
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    logDebug(view.viewTreeDescription, asynchronous: false)
//    logDebug(view.constraints.map({$0.description}).joinWithSeparator("\n"), asynchronous: false)

    /**
    Helper function for adjusting the `xOffset` property of the popover views

    - parameter popoverView: PopoverView
    - parameter presentingView: UIView
    */
    func adjustPopover(popoverView: PopoverView, _ presentingView: UIView) {
      let popoverCenter = view.convertPoint(popoverView.center, fromView: popoverView.superview)
      let presentingCenter = view.convertPoint(presentingView.center, fromView: presentingView.superview)
      popoverView.xOffset = presentingCenter.x - popoverCenter.x
    }

    adjustPopover(filesPopoverView, filesButton)
    adjustPopover(noteAttributesPopoverView, noteAttributesButton)
    adjustPopover(mixerPopoverView, mixerButton)
    adjustPopover(tempoPopoverView, tempoButton)
    adjustPopover(instrumentPopoverView, instrumentButton)
  }

  // MARK: Rotation

  /**
  shouldAutorotate

  - returns: Bool
  */
  override func shouldAutorotate() -> Bool { return false }

  /**
  supportedInterfaceOrientations

  - returns: UIInterfaceOrientationMask
  */
  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    // TODO: This needs to be changed or rotation supported before shipping
    return UIDevice.currentDevice().userInterfaceIdiom == .Phone ? .AllButUpsideDown : .All
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
      case let controller as FilesViewController:          filesViewController          = controller
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
        case .Files:          return MIDIPlayerViewController.currentInstance?.filesPopoverView
        case .NoteAttributes: return MIDIPlayerViewController.currentInstance?.noteAttributesPopoverView
        case .Instrument:     return MIDIPlayerViewController.currentInstance?.instrumentPopoverView
        case .Mixer:          return MIDIPlayerViewController.currentInstance?.mixerPopoverView
        case .Tempo:          return MIDIPlayerViewController.currentInstance?.tempoPopoverView
        case .None:           return nil
      }
    }
    var button: ImageButtonView? {
      switch self {
        case .Files:          return MIDIPlayerViewController.currentInstance?.filesButton
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

  @IBOutlet weak var filesButton: ImageButtonView!
  @IBOutlet weak var saveButton: ImageButtonView!
  @IBOutlet weak var fileTrackLabel: UILabel!
  @IBOutlet weak var fileTrackNameLabel: UILabel!
  @IBOutlet weak var fileTrackNameSwipeGesture: UISwipeGestureRecognizer!
  @IBOutlet weak var fileTrackNameDismissiveSwipeGesture: UISwipeGestureRecognizer!
  @IBOutlet weak var fileTrackActionButton: LabelButton!
  @IBOutlet var fileTrackNameActionButtonWidthConstraint: NSLayoutConstraint!

  /**
  fileTrackNameShowAction:
  */
  @IBAction func fileTrackNameShowAction() {
    UIView.animateWithDuration(0.25,
                    animations: { self.fileTrackNameActionButtonWidthConstraint.active = false },
                    completion: {_ in self.fileTrackNameSwipeGesture.enabled = false
                                      self.fileTrackNameDismissiveSwipeGesture.enabled = true})
  }

  /**
  fileTrackNameAction:
  */
  @IBAction func fileTrackNameAction() {
    
    if state ∋ .FileLoaded { Sequencer.currentFile = nil }
    dismissFileTrackNameAction()
  }

  /**
  dismissFileTrackNameAction:
  */
  @IBAction func dismissFileTrackNameAction() {
    
    UIView.animateWithDuration(0.25,
                    animations: { self.fileTrackNameActionButtonWidthConstraint.active = true },
                    completion: {_ in self.fileTrackNameDismissiveSwipeGesture.enabled = false
                                      self.fileTrackNameSwipeGesture.enabled = true})
  }

  /** save */
  @IBAction private func save() {
    
    let textField = FormTextField(name: "File Name", value: nil, placeholder: "Awesome Sauce") {
      (text: String?) -> Bool in
      guard let text = text else { return false }
      let url = documentsURLToFile(text)
      return !url.checkResourceIsReachableAndReturnError(nil)
    }
    let form = Form(fields: [textField])
    let submit = { [unowned self] (f: Form) -> Void in
      guard let text = f["File Name"]?.value as? String else { self.dismissViewControllerAnimated(true, completion: nil); return }
      let url = documentsURLToFile("\(text).mid")
      logDebug("saving to file '\(url)'")
      do { try Sequencer.sequence.writeToFile(url) } catch { logError(error) }
      self.dismissViewControllerAnimated(true, completion: nil)
    }
    let cancel = { [unowned self] () -> Void in self.dismissViewControllerAnimated(true, completion: nil) }
    let formViewController = FormViewController(form: form, didSubmit: submit, didCancel: cancel)
    presentViewController(formViewController, animated: true, completion: nil)
  }

  /** files */
  @IBAction private func files() { if case .Files = popover { popover = .None } else { popover = .Files } }

  private weak var filesViewController: FilesViewController! {
    didSet {
      filesViewController?.didSelectFile = { [unowned self] in Sequencer.currentFile = $0; self.popover = .None }
      filesViewController?.didDeleteFile = { guard Sequencer.currentFile == $0 else { return }; Sequencer.currentFile = nil }
    }
  }

  @IBOutlet private weak var filesPopoverView: PopoverView!

 // MARK: - Mixer

  @IBOutlet weak var mixerButton: ImageButtonView!
  @IBAction private func mixer() { updatePopover(.Mixer) }
  private weak var mixerViewController: MixerViewController!
  @IBOutlet private weak var mixerPopoverView: PopoverView!

  // MARK: - Instrument

  @IBOutlet weak var instrumentButton: ImageButtonView!
  @IBAction private func instrument() { updatePopover(.Instrument) }
  private weak var instrumentViewController: InstrumentViewController!
  @IBOutlet private weak var instrumentPopoverView: PopoverView!

  // MARK: - NoteAttributes

  @IBOutlet weak var noteAttributesButton: ImageButtonView!
  private weak var noteAttributesViewController: NoteAttributesViewController!
  @IBAction private func noteAttributes() { updatePopover(.NoteAttributes) }
  @IBOutlet private weak var noteAttributesPopoverView: PopoverView!

  // MARK: - Tempo

  @IBOutlet weak var tempoButton: ImageButtonView!
  private weak var tempoViewController: TempoViewController!
  @IBAction private func tempo() { updatePopover(.Tempo) }
  @IBOutlet private weak var tempoPopoverView: PopoverView!

  // MARK: - Undo

//  @IBOutlet weak var revertButton: ImageButtonView!
  @IBAction private func revert() { (midiPlayerSceneView?.scene as? MIDIPlayerScene)?.revert() }


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

  @IBOutlet weak var midiPlayerSceneView: SKView!

  var playerScene: MIDIPlayerScene {
    guard let playerScene = midiPlayerSceneView.scene as? MIDIPlayerScene else { fatalError("Failed to retrieve player scene") }
    return playerScene
  }

  // MARK: - Managing state

  private var notificationReceptionist: NotificationReceptionist?

  /**
  didChangeCurrentTrack:

  - parameter notification: NSNotification
  */
  private func didChangeCurrentTrack(notification: NSNotification) {
    guard state ∌ .FileLoaded else { return }
    fileTrackLabel.text = "Track"
    fileTrackNameLabel.text = Sequencer.currentTrack?.name
  }

  /**
  didRemoveTrack:

  - parameter notification: NSNotification
  */
  private func didRemoveTrack(notification: NSNotification) {
    guard Sequencer.sequence.instrumentTracks.count == 0 else { return }
    state ∖= [.TrackAdded]
  }

  /**
  didAddTrack:

  - parameter notification: NSNotification
  */
  private func didAddTrack(notification: NSNotification) { state ∪= [.TrackAdded] }

  /**
  didLoadFile:

  - parameter notification: NSNotification
  */
  private func didLoadFile(notification: NSNotification) { state ∪= [.FileLoaded] }

  /**
  didUnloadFile:

  - parameter notification: NSNotification
  */
  private func didUnloadFile(notification: NSNotification) { state ∖= [.FileLoaded] }

  /**
  didPause:

  - parameter notification: NSNotification
  */
  private func didPause(notification: NSNotification) { state ⊻= [.Playing, .Paused] }

  /**
  didStart:

  - parameter notification: NSNotification
  */
  private func didStart(notification: NSNotification) {
    if state ∋ .Paused { state ⊻= [.Playing, .Paused] } else { state ∪= .Playing }
  }

  /**
  didStop:

  - parameter notification: NSNotification
  */
  private func didStop(notification: NSNotification) { state ∖= [.Playing, .Paused] }

  /**
  didReset:

  - parameter notification: NSNotification
  */
  private func didReset(notification: NSNotification) { playerScene.midiPlayer.reset() }

  /** initializeReceptionist */
  private func initializeReceptionist() {

    guard notificationReceptionist == nil else { return }

    typealias Callback = NotificationReceptionist.Callback

    let queue = NSOperationQueue.mainQueue()

    let didAddTrackCallback:           Callback = (MIDISequence.self,   queue, didAddTrack)
    let didRemoveTrackCallback:        Callback = (MIDISequence.self,   queue, didRemoveTrack)
    let didChangeCurrentTrackCallback: Callback = (Sequencer.self,      queue, didChangeCurrentTrack)
    let didLoadFileCallback:           Callback = (Sequencer.self,      queue, didLoadFile)
    let didUnloadFileCallback:         Callback = (Sequencer.self,      queue, didUnloadFile)
    let didPauseCallback:              Callback = (Sequencer.self,      queue, didPause)
    let didStartCallback:              Callback = (Sequencer.self,      queue, didStart)
    let didStopCallback:               Callback = (Sequencer.self,      queue, didStop)
    let didResetCallback:              Callback = (Sequencer.self,      queue, didReset)

    let callbacks: [NotificationReceptionist.Notification:NotificationReceptionist.Callback] = [

      MIDISequence.Notification.Name.DidAddTrack.value:        didAddTrackCallback,
      MIDISequence.Notification.Name.DidRemoveTrack.value:     didRemoveTrackCallback,

      Sequencer.Notification.DidLoadFile.name.value:           didLoadFileCallback,
      Sequencer.Notification.DidUnloadFile.name.value:         didUnloadFileCallback,
      Sequencer.Notification.DidChangeCurrentTrack.name.value: didChangeCurrentTrackCallback,
      Sequencer.Notification.DidPause.name.value:              didPauseCallback,
      Sequencer.Notification.DidStart.name.value:              didStartCallback,
      Sequencer.Notification.DidStop.name.value:               didStopCallback,
      Sequencer.Notification.DidReset.name.value:              didResetCallback

    ]

    notificationReceptionist = NotificationReceptionist(callbacks: callbacks)

  }

  private struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    static let Popover     = State(rawValue: 0b0000_0000_0001)
    static let Playing     = State(rawValue: 0b0000_0000_0010)
    static let TrackAdded  = State(rawValue: 0b0000_0001_0000)
    static let Recording   = State(rawValue: 0b0000_0010_0000)
    static let FileLoaded  = State(rawValue: 0b0000_0100_0000)
    static let Paused      = State(rawValue: 0b0000_1000_0000)
    static let Jogging     = State(rawValue: 0b0001_0000_0000)

    var description: String {
      var result = "MIDIPlayerViewController.State { "
      var flagStrings: [String] = []
      if self ∋ .Popover     { flagStrings.append("Popover")     }
      if self ∋ .Playing     { flagStrings.append("Playing")     }
      if self ∋ .TrackAdded  { flagStrings.append("TrackAdded")  }
      if self ∋ .Recording   { flagStrings.append("Recording")   }
      if self ∋ .FileLoaded  { flagStrings.append("FileLoaded")  }
      if self ∋ .Paused      { flagStrings.append("Paused")      }
      if self ∋ .Jogging     { flagStrings.append("Jogging")     }

      result += ", ".join(flagStrings)
      result += " }"
      return result
    }
  }

  private var state: State = [] {
    didSet {
      guard isViewLoaded() && state != oldValue else { return }
      guard state ∌ [.Playing, .Paused] else { fatalError("State invalid: cannot be both playing and paused") }

      logVerbose("didSet…old state: \(oldValue); new state: \(state)")

      let modifiedState = state ⊻ oldValue

      // Check if popover state has changed
      if modifiedState ∋ .Popover {
        popoverBlur.hidden = state ∌ .Popover
        saveButton.enabled = state ∋ .TrackAdded && state ∌ .Popover
      }

      // Check if track changed
      if modifiedState ∋ .TrackAdded {
        saveButton.enabled = state ∋ .TrackAdded && state ∌ .Popover
      }

      // Check if file status changed
      if modifiedState ∋ .FileLoaded {
        if let currentFile = Sequencer.currentFile?.lastPathComponent {
          fileTrackLabel.text = "File"
          fileTrackNameLabel.text = currentFile[..<currentFile.endIndex.advancedBy(-4)]
        } else {
          fileTrackLabel.text = "Track"
          fileTrackNameLabel.text = Sequencer.currentTrack?.name
        }
        fileTrackNameSwipeGesture.enabled = state ∋ .FileLoaded
        recordButton.enabled = state ∌ .FileLoaded
      }

      // Check if jog status changed
      if modifiedState ∋ .Jogging {
        transportStack.userInteractionEnabled = state ∌ .Jogging
      }

      // Check for recording status change
      if modifiedState ∋ .Recording {
        recordButton.selected = state ∋ .Recording
      }

      // Check if play/pause status changed
      if modifiedState ~∩ [.Playing, .Paused] {
        playerScene.paused = state ∌ .Playing
        stopButton.enabled = state ~∩ [.Playing, .Paused]
        (playerScene.paused ? ControlImage.Play : ControlImage.Pause).decorateButton(playPauseButton)
      }
    }
  }

}
