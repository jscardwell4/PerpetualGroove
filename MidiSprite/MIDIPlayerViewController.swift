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

    filesPopoverView.hidden = true
    view.addSubview(filesPopoverView)

    mixerPopoverView.hidden = true
    view.addSubview(mixerPopoverView)

    instrumentPopoverView.hidden = true
    view.addSubview(instrumentPopoverView)

    noteAttributesPopoverView.hidden = true
    view.addSubview(noteAttributesPopoverView)

    view.setNeedsUpdateConstraints()

    initializeReceptionist()

  }

  /** viewDidLayoutSubviews */
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    func adjustPopover(popoverView: PopoverView, _ presentingView: UIView) {
      let popoverCenter = view.convertPoint(popoverView.center, fromView: popoverView.superview)
      let presentingCenter = view.convertPoint(presentingView.center, fromView: presentingView.superview)
      popoverView.xOffset = presentingCenter.x - popoverCenter.x
    }

    adjustPopover(filesPopoverView, filesButton)
    adjustPopover(noteAttributesPopoverView, noteAttributesButton)
    adjustPopover(mixerPopoverView, mixerButton)
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
    if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
      return .AllButUpsideDown
    } else {
      return .All
    }
  }

  // MARK: Status bar

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  override func prefersStatusBarHidden() -> Bool { return true }

  // MARK: - Tempo

  @IBOutlet weak var tempoSlider: Slider!

  /** tempoSliderValueDidChange */
  @IBAction private func tempoSliderValueDidChange() { Sequencer.tempo = Double(tempoSlider.value) }

  @IBOutlet weak var metronomeButton: ImageButtonView!

  /** metronome */
  @IBAction func metronome() { AudioManager.metronome.on = !AudioManager.metronome.on }

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
      default:                                                                 break
    }
  }

  @IBOutlet weak var popoverBlur: UIVisualEffectView!

  /** dismissPopover */
  @IBAction private func dismissPopover() { popover = .None }

  // MARK: Popover enumeration
  private enum Popover {
    case None, Files, NoteAttributes, Instrument, Mixer
    var view: PopoverView? {
      switch self {
        case .Files:      return MIDIPlayerViewController.currentInstance?.filesPopoverView
        case .NoteAttributes:   return MIDIPlayerViewController.currentInstance?.noteAttributesPopoverView
        case .Instrument: return MIDIPlayerViewController.currentInstance?.instrumentPopoverView
        case .Mixer:      return MIDIPlayerViewController.currentInstance?.mixerPopoverView
        case .None:       return nil
      }
    }
    var button: ImageButtonView? {
      switch self {
        case .Files:      return MIDIPlayerViewController.currentInstance?.filesButton
        case .NoteAttributes:   return MIDIPlayerViewController.currentInstance?.noteAttributesButton
        case .Instrument: return MIDIPlayerViewController.currentInstance?.instrumentButton
        case .Mixer:      return MIDIPlayerViewController.currentInstance?.mixerButton
        case .None:       return nil
      }
    }
  }

  private var popover = Popover.None {
    didSet {
      guard oldValue != popover else { return }
      oldValue.view?.hidden = true; oldValue.button?.selected = false; popover.view?.hidden = false
      if popover == .None { state.remove(.PopoverActive) } else if oldValue == .None { state.insert(.PopoverActive) }
    }
  }

  // MARK: - Files

  @IBOutlet weak var filesButton: ImageButtonView!
  @IBOutlet weak var saveButton: ImageButtonView!
  @IBOutlet weak var fileNameLabel: LabelButton!

  @IBAction private func fileName() {

  }

  // MARK: - Tracks

  @IBOutlet weak var trackNameLabel: LabelButton!

  @IBAction private func trackName() {

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

  /** sliders */
  @IBAction private func mixer() { if case .Mixer = popover { popover = .None } else { popover = .Mixer } }

  private weak var mixerViewController: MixerViewController!
  @IBOutlet private weak var mixerPopoverView: PopoverView!

  // MARK: - Instrument

  @IBOutlet weak var instrumentButton: ImageButtonView!

  /** instrument */
  @IBAction private func instrument() { if case .Instrument = popover { popover = .None } else { popover = .Instrument } }

  private weak var instrumentViewController: InstrumentViewController!
  @IBOutlet private weak var instrumentPopoverView: PopoverView!

  // MARK: - NoteAttributes

  @IBOutlet weak var noteAttributesButton: ImageButtonView!
  private weak var noteAttributesViewController: NoteAttributesViewController!

  /** noteAttributes */
  @IBAction private func noteAttributes() { if case .NoteAttributes = popover { popover = .None } else { popover = .NoteAttributes } }

  @IBOutlet private weak var noteAttributesPopoverView: PopoverView!

  // MARK: - Undo

  @IBOutlet weak var revertButton: ImageButtonView!

  /** revert */
  @IBAction private func revert() { (midiPlayerSceneView?.scene as? MIDIPlayerScene)?.revert() }


  // MARK: - Transport

  @IBOutlet weak var recordButton: ImageButtonView!
  @IBOutlet weak var playPauseButton: ImageButtonView!
  @IBOutlet weak var stopButton: ImageButtonView!

  /** record */
  @IBAction func record() { Sequencer.recording = !Sequencer.recording }

  /** play */
  @IBAction func play() { guard !playing else { return }; playing = true }

  /** stop */
  @IBAction func stop() {
    guard playing, let playerScene = playerScene else { return }
    playerScene.midiPlayer.reset()
    playing = false
  }

  // MARK: ControlImage enumeration
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

  private(set) var playing: Bool {
    get { return state ∋ .PlayerPlaying }
    set {
      guard newValue != playing, let playerScene = playerScene else { return }
      if newValue {
        do { try AudioManager.start() } catch { logError(error) }
        playerScene.paused = false
      } else {
        do { try AudioManager.stop() } catch { logError(error) }
        playerScene.paused = true
      }
      state ⊻= .PlayerPlaying
    }
  }

  // MARK: - Scene-relatd properties

  @IBOutlet weak var midiPlayerSceneView: SKView!

  private var playerScene: MIDIPlayerScene? { return midiPlayerSceneView.scene as? MIDIPlayerScene }

  // MARK: - Managing state

  private var notificationReceptionist: NotificationReceptionist?

  /**
  nodeCountDidChange:

  - parameter notification: NSNotification
  */
  private func nodeCountDidChange(notification: NSNotification) {
    let isEmptyField = (playerScene?.midiPlayer.midiNodes.count ?? 0) == 0
    guard (state ∋ .MIDINodeAdded && isEmptyField)
       || (state ∌ .MIDINodeAdded && !isEmptyField) else { return }
    state ⊻= .MIDINodeAdded
    if state ∋ .MIDINodeAdded && !playing { play() }
  }

  /**
  trackCountDidChange:

  - parameter notification: NSNotification
  */
  private func trackCountDidChange(notification: NSNotification) {
    let isEmptySequence = Sequencer.sequence.tracks.count == 0
    guard (state ∋ .TrackAdded && isEmptySequence)
      || (state ∌ .TrackAdded && !isEmptySequence) else { return }
    state ⊻= .TrackAdded
  }

  /**
  fileDidLoad:

  - parameter notification: NSNotification
  */
  private func fileDidLoad(notification: NSNotification) {
    state.insert(.FileLoaded)
  }

  /**
  fileDidUnload:

  - parameter notification: NSNotification
  */
  private func fileDidUnload(notification: NSNotification) {
    state.remove(.FileLoaded)
  }

  /** initializeReceptionist */
  private func initializeReceptionist() {

    guard notificationReceptionist == nil else { return }

    typealias Callback = NotificationReceptionist.Callback

    let queue = NSOperationQueue.mainQueue()

    let nodeCallback: Callback = (MIDIPlayerNode.self, queue, nodeCountDidChange)
    let trackCallback: Callback = (MIDISequence.self, queue, trackCountDidChange)
    let fileLoadedCallback: Callback = (Sequencer.self, queue, fileDidLoad)
    let fileUnloadedCallback: Callback = (Sequencer.self, queue, fileDidUnload)

    let callbacks: [NotificationReceptionist.Notification:NotificationReceptionist.Callback] = [
      MIDIPlayerNode.Notification.NodeAdded.name.value: nodeCallback,
      MIDIPlayerNode.Notification.NodeRemoved.name.value: nodeCallback,
      MIDISequence.Notification.TrackAdded.name.value: trackCallback,
      MIDISequence.Notification.TrackRemoved.name.value: trackCallback,
      Sequencer.Notification.FileLoaded.name.value: fileLoadedCallback,
      Sequencer.Notification.FileUnloaded.name.value: fileUnloadedCallback
    ]

    notificationReceptionist = NotificationReceptionist(callbacks: callbacks)

  }

  private struct State: OptionSetType {
    let rawValue: Int
    static let Default           = State(rawValue: 0b0000_0000)
    static let PopoverActive     = State(rawValue: 0b0000_0001)
    static let PlayerPlaying     = State(rawValue: 0b0000_0010)
    static let PlayerFieldActive = State(rawValue: 0b0000_0100)
    static let MIDINodeAdded     = State(rawValue: 0b0000_1000)
    static let TrackAdded        = State(rawValue: 0b0001_0000)
    static let PlayerRecording   = State(rawValue: 0b0010_0000)
    static let FileLoaded        = State(rawValue: 0b0100_0000)
  }

  private var state: State = [] {
    didSet {
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
          fileNameLabel.text = currentFile[..<currentFile.endIndex.advancedBy(-4)]
        } else {
          fileNameLabel.text = nil
        }
        fileNameLabel.hidden = fileNameLabel.text == nil
      }
    }
  }

}
