//
//  MIDIPlayerViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import Eveleth
import MoonKit
import Chameleon
import typealias AudioToolbox.MusicDeviceGroupID

final class MIDIPlayerViewController: UIViewController {

  // MARK: - UIViewController overridden methods -

  // MARK: View loading and layout

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    midiPlayerSceneView.ignoresSiblingOrder = true

    midiPlayerSceneView.presentScene(MIDIPlayerScene(size: midiPlayerSceneView.bounds.size))
    playerScene!.paused = true

    initializeReceptionist()

    filesPopoverView.hidden = true
    view.addSubview(filesPopoverView)

    mixerPopoverView.hidden = true
    view.addSubview(mixerPopoverView)

    instrumentPopoverView.hidden = true
    view.addSubview(instrumentPopoverView)

    templatePopoverView.hidden = true
    view.addSubview(templatePopoverView)

    view.setNeedsUpdateConstraints()

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
    adjustPopover(templatePopoverView, templateButton)
    adjustPopover(mixerPopoverView, mixerButton)
    adjustPopover(instrumentPopoverView, instrumentButton)
  }

  // MARK: Constraints

  /** updateViewConstraints */
  override func updateViewConstraints() {
    super.updateViewConstraints()

    guard let filesPopover = _filesPopoverView,
              mixerPopover = _mixerPopoverView,
              templatePopover = _templatePopoverView,
              instrumentPopover = _instrumentPopoverView
      else { return }

    func addConstraints(id: Identifier, _ popoverView: PopoverView, _ presentingView: UIView) {
      guard view.constraintsWithIdentifier(id).count == 0 else { return }
      view.constrain(
        [popoverView.centerX => presentingView.centerX -!> 999] --> (id + "CenterX"),
        [ popoverView.top => popoverBlur.top,
          popoverView.width ≤ (UIScreen.mainScreen().bounds.width - 10),
          popoverView.left ≥ view.left + 5,
          popoverView.right ≤ view.right - 5 ] --> id
      )
    }

    addConstraints(Identifier(self, "FilesPopover"), filesPopover, filesButton)
    addConstraints(Identifier(self, "MixerPopover"), mixerPopover, mixerButton)
    addConstraints(Identifier(self, "TemplatePopover"), templatePopover, templateButton)
    addConstraints(Identifier(self, "InstrumentPopover"),  instrumentPopover, instrumentButton)
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

  // MARK: Memory

  /** didReceiveMemoryWarning */
  override func didReceiveMemoryWarning() {
    logDebug("")
    super.didReceiveMemoryWarning()
    if let templatePopover = _templatePopoverView where templatePopover.hidden == false {
      templatePopover.removeFromSuperview()
      _templatePopoverView = nil
    }

    if let mixerPopover = _mixerPopoverView where mixerPopover.hidden == true {
      mixerPopover.removeFromSuperview()
      _mixerPopoverView = nil
    }

    if let instrumentPopover = _instrumentPopoverView where instrumentPopover.hidden == true {
      instrumentPopover.removeFromSuperview()
      _instrumentPopoverView = nil
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
  @IBAction func metronome() { Metronome.on = !Metronome.on }

  // MARK: - Popovers

  @IBOutlet weak var popoverBlur: UIVisualEffectView!

  /** dismissPopover */
  @IBAction private func dismissPopover() { popover = .None }

  // MARK: Popover enumeration
  private enum Popover {
    case None, Files, Template, Instrument, Mixer
    var view: PopoverView? {
      guard let delegate = UIApplication.sharedApplication().delegate,
                window = delegate.window,
                controller = window?.rootViewController as? MIDIPlayerViewController else { return nil }
      switch self {
        case .Files:      return controller.filesPopoverView
        case .Template:   return controller.templatePopoverView
        case .Instrument: return controller.instrumentPopoverView
        case .Mixer:      return controller.mixerPopoverView
        case .None:       return nil
      }
    }
    var button: ImageButtonView? {
      guard let delegate = UIApplication.sharedApplication().delegate,
                window = delegate.window,
                controller = window?.rootViewController as? MIDIPlayerViewController else { return nil }
      switch self {
        case .Files:      return controller.filesButton
        case .Template:   return controller.templateButton
        case .Instrument: return controller.instrumentButton
        case .Mixer:      return controller.mixerButton
        case .None:       return nil
      }
    }
  }

  private var popover = Popover.None {
    didSet {
      guard oldValue != popover else { return }
      oldValue.view?.hidden = true; oldValue.button?.selected = false; popover.view?.hidden = false
      if popover == .None { state.remove(.PopoverActive) } else if oldValue == .None { state ∪= .PopoverActive }
    }
  }

  // MARK: - Files

  @IBOutlet weak var filesButton: ImageButtonView!
  @IBOutlet weak var saveButton: ImageButtonView!
  @IBOutlet weak var fileNameLabel: LabelButton!

  @IBAction private func fileName() {

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

  private var _filesViewController: FilesViewController?
  private var filesViewController: FilesViewController {
    guard _filesViewController == nil else { return _filesViewController! }
    _filesViewController = FilesViewController()
    _filesViewController!.didSelectFile = { [unowned self] in Sequencer.currentFile = $0; self.popover = .None }
    _filesViewController!.didDeleteFile = { guard Sequencer.currentFile == $0 else { return }; Sequencer.currentFile = nil }
    guard _filesViewController != nil else { fatalError("failed to instantiate file view controller from storyboard") }
    addChildViewController(_filesViewController!)
    return _filesViewController!
  }

  private var _filesPopoverView: PopoverView?
  private var filesPopoverView: PopoverView {
    guard _filesPopoverView == nil else { return _filesPopoverView! }
    _filesPopoverView = PopoverView(autolayout: true)
    _filesPopoverView!.backgroundColor = .popoverBackgroundColor
    _filesPopoverView!.location = .Top
    _filesPopoverView!.nametag = "filePopover"
    _filesPopoverView!.arrowHeight = .popoverArrowHeight
    _filesPopoverView!.arrowWidth = .popoverArrowWidth

    let fileView = filesViewController.view
    _filesPopoverView!.contentView.addSubview(fileView)
    _filesPopoverView!.constrain(𝗩|fileView|𝗩, 𝗛|fileView|𝗛)

    return _filesPopoverView!
  }


 // MARK: - Mixer

  @IBOutlet weak var mixerButton: ImageButtonView!

  /** sliders */
  @IBAction private func mixer() { if case .Mixer = popover { popover = .None } else { popover = .Mixer } }

  private var _mixerViewController: MixerViewController?
  private var mixerViewController: MixerViewController {
    guard _mixerViewController == nil else { return _mixerViewController! }
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    _mixerViewController = storyboard.instantiateViewControllerWithIdentifier("Mixer") as? MixerViewController
    guard _mixerViewController != nil else { fatalError("failed to instantiate mixer view controller from storyboard") }
    addChildViewController(_mixerViewController!)
    return _mixerViewController!
  }

  private var _mixerPopoverView: PopoverView?
  private var mixerPopoverView: PopoverView {
    guard _mixerPopoverView == nil else { return _mixerPopoverView! }
    _mixerPopoverView = PopoverView(autolayout: true)
    _mixerPopoverView!.backgroundColor = .popoverBackgroundColor
    _mixerPopoverView!.location = .Top
    _mixerPopoverView!.nametag = "mixerPopover"
    _mixerPopoverView!.arrowHeight = .popoverArrowHeight
    _mixerPopoverView!.arrowWidth = .popoverArrowWidth

    let mixerView = mixerViewController.view
    _mixerPopoverView!.contentView.addSubview(mixerView)
    _mixerPopoverView!.constrain(𝗩|mixerView|𝗩, 𝗛|mixerView|𝗛)

    return _mixerPopoverView!
  }

  // MARK: - Instrument

  @IBOutlet weak var instrumentButton: ImageButtonView!

  /** instrument */
  @IBAction private func instrument() { if case .Instrument = popover { popover = .None } else { popover = .Instrument } }

  private var _instrumentViewController: InstrumentViewController?
  private var instrumentViewController: InstrumentViewController {
    guard _instrumentViewController == nil else { return _instrumentViewController! }
    _instrumentViewController = InstrumentViewController()
    addChildViewController(_instrumentViewController!)
    return _instrumentViewController!
  }

  private var _instrumentPopoverView: PopoverView?
  private var instrumentPopoverView: PopoverView {
    guard _instrumentPopoverView == nil else { return _instrumentPopoverView! }
    _instrumentPopoverView = PopoverView(autolayout: true)
    _instrumentPopoverView!.backgroundColor = .popoverBackgroundColor
    _instrumentPopoverView!.location = .Top
    _instrumentPopoverView!.nametag = "instrumentPopover"
    _instrumentPopoverView!.arrowHeight = .popoverArrowHeight
    _instrumentPopoverView!.arrowWidth = .popoverArrowWidth

    let instrumentView = instrumentViewController.view
    instrumentView.constrain(instrumentView.width ≥ 400)
    _instrumentPopoverView!.contentView.addSubview(instrumentView)
    _instrumentPopoverView!.constrain(𝗩|instrumentView|𝗩, 𝗛|instrumentView|𝗛)

    return _instrumentPopoverView!
  }

  // MARK: - Template

  @IBOutlet weak var templateButton: ImageButtonView!

  private var _templateViewController: TemplateViewController?
  private var templateViewController: TemplateViewController {
    guard _templateViewController == nil else { return _templateViewController! }
    _templateViewController = TemplateViewController()
    addChildViewController(_templateViewController!)
    return _templateViewController!
  }

  /** template */
  @IBAction private func template() { if case .Template = popover { popover = .None } else { popover = .Template } }

  private var _templatePopoverView: PopoverView?
  private var templatePopoverView: PopoverView {
    guard _templatePopoverView == nil else { return _templatePopoverView! }
    _templatePopoverView = PopoverView(autolayout: true)
    _templatePopoverView!.backgroundColor = .popoverBackgroundColor
    _templatePopoverView!.location = .Top
    _templatePopoverView!.nametag = "templatePopover"
    _templatePopoverView!.arrowHeight = .popoverArrowHeight
    _templatePopoverView!.arrowWidth = .popoverArrowWidth

    let templateView = templateViewController.view
    templateView.constrain(templateView.width ≥ 400)
    _templatePopoverView!.contentView.addSubview(templateView)
    _templatePopoverView!.constrain(𝗩|templateView|𝗩, 𝗛|templateView|𝗛)

    return _templatePopoverView!
  }

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

  /** initializeReceptionist */
  private func initializeReceptionist() {

    guard notificationReceptionist == nil else { return }

    typealias Callback = NotificationReceptionist.Callback

    let nodeCountDidChange: (NSNotification) -> Void = {
      [unowned self] _ in
      let isEmptyField = (self.playerScene?.midiPlayer.midiNodes.count ?? 0) == 0
      guard (self.state ∋ .MIDINodeAdded && isEmptyField)
         || (self.state ∌ .MIDINodeAdded && !isEmptyField) else { return }
      self.state ⊻= .MIDINodeAdded
    }

    let trackCountDidChange: (NSNotification) -> Void = {
      [unowned self] _ in
      let isEmptySequence = Sequencer.sequence.tracks.count == 0
      guard (self.state ∋ .TrackAdded && isEmptySequence)
         || (self.state ∌ .TrackAdded && !isEmptySequence) else { return }
      self.state ⊻= .TrackAdded
    }

    let fileDidLoad: (NSNotification) -> Void = { [unowned self] _ in self.state.insert(.FileLoaded) }
    let fileDidUnload: (NSNotification) -> Void = { [unowned self] _ in self.state.remove(.FileLoaded) }

    let queue = NSOperationQueue.mainQueue()

    let nodeCallback: Callback = (MIDIPlayerNode.self, queue, nodeCountDidChange)
    let trackCallback: Callback = (Sequence.self, queue, trackCountDidChange)
    let fileLoadedCallback: Callback = (Sequencer.self, queue, fileDidLoad)
    let fileUnloadedCallback: Callback = (Sequencer.self, queue, fileDidUnload)

    let callbacks: [NotificationReceptionist.Notification:NotificationReceptionist.Callback] = [
      MIDIPlayerNode.Notification.NodeAdded.name.value: nodeCallback,
      MIDIPlayerNode.Notification.NodeRemoved.name.value: nodeCallback,
      Sequence.Notification.TrackAdded.name.value: trackCallback,
      Sequence.Notification.TrackRemoved.name.value: trackCallback,
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
