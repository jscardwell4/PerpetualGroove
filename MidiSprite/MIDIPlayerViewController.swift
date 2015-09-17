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
    playerScene!.paused = true

    fileTrackNameLabel.text = nil

    initializeReceptionist()

  }

  /** viewDidLayoutSubviews */
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

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
    switch (segue.identifier, segue.destinationViewController) {
      case ("Mixer", let controller as MixerViewController):                   mixerViewController          = controller
      case ("Instrument", let controller as InstrumentViewController):         instrumentViewController     = controller
      case ("NoteAttributes", let controller as NoteAttributesViewController): noteAttributesViewController = controller
      case ("Files", let controller as FilesViewController):                   filesViewController          = controller
      case ("Tempo", let controller as TempoViewController):                   tempoViewController          = controller
      default:                                                                 break
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
      if popover == .None { state.remove(.PopoverActive) }
      else if oldValue == .None { state.insert(.PopoverActive) }
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
    logDebug()
    UIView.animateWithDuration(0.25,
                    animations: { self.fileTrackNameActionButtonWidthConstraint.active = false },
                    completion: {_ in self.fileTrackNameSwipeGesture.enabled = false
                                      self.fileTrackNameDismissiveSwipeGesture.enabled = true})
  }

  /**
  fileTrackNameAction:
  */
  @IBAction func fileTrackNameAction() {
    logDebug()
    if state ∋ .FileLoaded { Sequencer.currentFile = nil }
    dismissFileTrackNameAction()
  }

  /**
  dismissFileTrackNameAction:
  */
  @IBAction func dismissFileTrackNameAction() {
    logDebug()
    UIView.animateWithDuration(0.25,
                    animations: { self.fileTrackNameActionButtonWidthConstraint.active = true },
                    completion: {_ in self.fileTrackNameDismissiveSwipeGesture.enabled = false
                                      self.fileTrackNameSwipeGesture.enabled = true})
  }

  /** save */
  @IBAction private func save() {
    logDebug("")
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
      MSLogDebug("saving to file '\(url)'")
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
  @IBAction private func mixer() { logDebug(""); updatePopover(.Mixer) }
  private weak var mixerViewController: MixerViewController!
  @IBOutlet private weak var mixerPopoverView: PopoverView!

  // MARK: - Instrument

  @IBOutlet weak var instrumentButton: ImageButtonView!
  @IBAction private func instrument() { logDebug(""); updatePopover(.Instrument) }
  private weak var instrumentViewController: InstrumentViewController!
  @IBOutlet private weak var instrumentPopoverView: PopoverView!

  // MARK: - NoteAttributes

  @IBOutlet weak var noteAttributesButton: ImageButtonView!
  private weak var noteAttributesViewController: NoteAttributesViewController!
  @IBAction private func noteAttributes() { logDebug(""); updatePopover(.NoteAttributes) }
  @IBOutlet private weak var noteAttributesPopoverView: PopoverView!

  // MARK: - Tempo

  @IBOutlet weak var tempoButton: ImageButtonView!
  private weak var tempoViewController: TempoViewController!
  @IBAction private func tempo() { logDebug(""); updatePopover(.Tempo) }
  @IBOutlet private weak var tempoPopoverView: PopoverView!

  // MARK: - Undo

  @IBOutlet weak var revertButton: ImageButtonView!
  @IBAction private func revert() { logDebug(""); (midiPlayerSceneView?.scene as? MIDIPlayerScene)?.revert() }


  // MARK: - Transport

  @IBOutlet weak var recordButton: ImageButtonView!
  @IBOutlet weak var playPauseButton: ImageButtonView!
  @IBOutlet weak var stopButton: ImageButtonView!
  @IBOutlet weak var barBeatTimeLabel: UILabel!
  @IBOutlet weak var jogWheel: ScrollWheel!

  @IBAction func record() { logDebug(); Sequencer.recording = !Sequencer.recording }
  @IBAction func playPause() { logDebug(); if playing { pause() } else { play() } }
  @IBAction func stop() { logDebug(); guard playing, let scene = playerScene else { return }; scene.midiPlayer.reset(); playing = false }
  @IBAction private func beginJog(){ state.insert(.JogActive) }
  @IBAction private func jog() { }
  @IBAction private func endJog() { state.remove(.JogActive) }

  func play() { logDebug(); guard !playing else { return }; playing = true }
  func pause() { logDebug(); guard !paused && playing else { return }; paused = true }

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

  private(set) var paused: Bool {
    get { return state ∋ .PlayerPaused }
    set {
      logDebug("didSet… currentValue: \(paused); newValue: \(newValue)")
      guard newValue != paused, let playerScene = playerScene else { return }
      if newValue { Sequencer.pause(); playerScene.paused = true } else { Sequencer.play(); playerScene.paused = false }
      state ⊻= .PlayerPaused
      if !paused { state.insert(.PlayerPlaying) }
    }
  }

  private(set) var playing: Bool {
    get { return state ∋ .PlayerPlaying }
    set {
      logDebug("didSet… currentValue: \(playing); newValue: \(newValue)")
      guard newValue != playing, let playerScene = playerScene else { return }
      if newValue { Sequencer.play(); playerScene.paused = false } else { playerScene.paused = true }
      state ⊻= .PlayerPlaying
      if playing { state.remove(.PlayerPaused) }
    }
  }

  // MARK: - Scene-relatd properties

  @IBOutlet weak var midiPlayerSceneView: SKView!

  var playerScene: MIDIPlayerScene? { return midiPlayerSceneView.scene as? MIDIPlayerScene }

  // MARK: - Managing state

  private var notificationReceptionist: NotificationReceptionist?

  /**
  nodeCountDidChange:

  - parameter notification: NSNotification
  */
  private func nodeCountDidChange(notification: NSNotification) {
    logDebug("")
    let isEmptyField = (playerScene?.midiPlayer.midiNodes.count ?? 0) == 0
    guard (state ∋ .MIDINodeAdded && isEmptyField)
       || (state ∌ .MIDINodeAdded && !isEmptyField) else { return }
    state ⊻= .MIDINodeAdded
    if state ∋ .MIDINodeAdded && !playing { playPause() }
  }


  /**
  currentTrackDidChange:

  - parameter notification: NSNotification
  */
  private func currentTrackDidChange(notification: NSNotification) {
    logDebug("")
    if state ∌ .FileLoaded { fileTrackLabel.text = "Track"; fileTrackNameLabel.text = Sequencer.currentTrack?.name }
  }

  /**
  trackCountDidChange:

  - parameter notification: NSNotification
  */
  private func trackCountDidChange(notification: NSNotification) {
    logDebug("")
    let isEmptySequence = Sequencer.sequence.instrumentTracks.count == 0
    guard (state ∋ .TrackAdded && isEmptySequence)
      || (state ∌ .TrackAdded && !isEmptySequence) else { return }
    state ⊻= .TrackAdded
  }

  /**
  fileDidLoad:

  - parameter notification: NSNotification
  */
  private func fileDidLoad(notification: NSNotification) { logDebug(""); state.insert(.FileLoaded) }

  /**
  fileDidUnload:

  - parameter notification: NSNotification
  */
  private func fileDidUnload(notification: NSNotification) { logDebug(""); state.remove(.FileLoaded) }

  /** initializeReceptionist */
  private func initializeReceptionist() {

    guard notificationReceptionist == nil else { return }

    typealias Callback = NotificationReceptionist.Callback

    let queue = NSOperationQueue.mainQueue()

    let nodeCallback: Callback = (MIDIPlayerNode.self, queue, nodeCountDidChange)
    let trackCallback: Callback = (MIDISequence.self, queue, trackCountDidChange)
    let currentTrackCallback: Callback = (Sequencer.self, queue, currentTrackDidChange)
    let fileLoadedCallback: Callback = (Sequencer.self, queue, fileDidLoad)
    let fileUnloadedCallback: Callback = (Sequencer.self, queue, fileDidUnload)

    let callbacks: [NotificationReceptionist.Notification:NotificationReceptionist.Callback] = [
      MIDIPlayerNode.Notification.NodeAdded.name.value: nodeCallback,
      MIDIPlayerNode.Notification.NodeRemoved.name.value: nodeCallback,
      MIDISequence.Notification.Name.TrackAdded.value: trackCallback,
      MIDISequence.Notification.Name.TrackRemoved.value: trackCallback,
      Sequencer.Notification.FileLoaded.name.value: fileLoadedCallback,
      Sequencer.Notification.FileUnloaded.name.value: fileUnloadedCallback,
      Sequencer.Notification.CurrentTrackDidChange.name.value: currentTrackCallback
    ]

    notificationReceptionist = NotificationReceptionist(callbacks: callbacks)

  }

  private struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int
    static let Default           = State(rawValue: 0b0000_0000_0000)
    static let PopoverActive     = State(rawValue: 0b0000_0000_0001)
    static let PlayerPlaying     = State(rawValue: 0b0000_0000_0010)
    static let PlayerFieldActive = State(rawValue: 0b0000_0000_0100)
    static let MIDINodeAdded     = State(rawValue: 0b0000_0000_1000)
    static let TrackAdded        = State(rawValue: 0b0000_0001_0000)
    static let PlayerRecording   = State(rawValue: 0b0000_0010_0000)
    static let FileLoaded        = State(rawValue: 0b0000_0100_0000)
    static let PlayerPaused      = State(rawValue: 0b0000_1000_0000)
    static let JogActive         = State(rawValue: 0b0001_0000_0000)

    var description: String {
      var result = "MIDIPlayerViewController.State { "
      var flagStrings: [String] = []
      if self ∋ .PopoverActive     { flagStrings.append("PopoverActive")     }
      if self ∋ .PlayerPlaying     { flagStrings.append("PlayerPlaying")     }
      if self ∋ .PlayerFieldActive { flagStrings.append("PlayerFieldActive") }
      if self ∋ .MIDINodeAdded     { flagStrings.append("MIDINodeAdded")     }
      if self ∋ .TrackAdded        { flagStrings.append("TrackAdded")        }
      if self ∋ .PlayerRecording   { flagStrings.append("PlayerRecording")   }
      if self ∋ .FileLoaded        { flagStrings.append("FileLoaded")        }
      if self ∋ .JogActive         { flagStrings.append("JogActive")         }

      result += ", ".join(flagStrings)
      result += " }"
      return result
    }
  }

  private var state: State = [] {
    didSet {
      logDebug("didSet…\n\told state: \(oldValue)\n\tnew state: \(state)")
      let modifiedState = state ⊻ oldValue

      if modifiedState ∋ .MIDINodeAdded {
        revertButton.enabled = state ∋ .MIDINodeAdded && state ∌ .PopoverActive // We have a node and aren't showing popover
      }

      if modifiedState ∋ .TrackAdded {
        saveButton.enabled = state ∋ .TrackAdded && state ∌ .PopoverActive // We have a track and aren't showing popover
      }

      if modifiedState ∋ .PlayerPlaying {
        stopButton.enabled = state ∋ .PlayerPlaying
        (state ∋ .PlayerPlaying ? ControlImage.Pause : ControlImage.Play).decorateButton(playPauseButton)
      }

      if modifiedState ∋ .PopoverActive {
        popoverBlur.hidden = state ∌ .PopoverActive
      }

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

      if modifiedState ∋ .JogActive {
        logDebug("do something about the change in `JogActive` state")
      }
    }
  }

}
