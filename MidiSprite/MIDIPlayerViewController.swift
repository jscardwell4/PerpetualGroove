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
import Eveleth
import Chameleon
import typealias AudioToolbox.MusicDeviceGroupID

final class MIDIPlayerViewController: UIViewController {

  // MARK: - IBOutlet views and controls

  @IBOutlet weak var tempoSlider: Slider!
  @IBOutlet weak var tempoLabel: UILabel!
  @IBOutlet weak var templateBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var instrumentBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var playPauseBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var stopBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var mixerBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var saveBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var revertBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var popoverBlur: UIVisualEffectView!
  @IBOutlet weak var skView: SKView!

  // MARK: - IBAction methods

  /** dismissPopover */
  @IBAction private func dismissPopover() { popover = .None }

  /** tempoSliderValueDidChange */
  @IBAction private func tempoSliderValueDidChange() { Sequencer.tempo = Double(tempoSlider.value) }

  /** revert */
  @IBAction private func revert() { (skView?.scene as? MIDIPlayerScene)?.revert() }

  /** sliders */
  @IBAction private func mixer() { if case .Mixer = popover { popover = .None } else { popover = .Mixer } }

  /** instrument */
  @IBAction private func instrument() { if case .Instrument = popover { popover = .None } else { popover = .Instrument } }

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

  /** skipBack */
  @IBAction func skipBack() { logDebug("skipBack() not yet implemented") }

  /** record */
  @IBAction func record() { logDebug("record() not yet implemented") }

  /** play */
  @IBAction func play() {
    guard !playing else { return }
    playing = true
  }

  /** stop */
  @IBAction func stop() {
    guard playing, let playerScene = playerScene else { return }
    playerScene.midiPlayer.reset()
    playing = false
  }

  /** metronome */
  @IBAction func metronome() { Metronome.on = !Metronome.on }

  /** template */
  @IBAction private func template() { if case .Template = popover { popover = .None } else { popover = .Template } }

  // MARK: - Scene-relatd properties

  private var playerScene: MIDIPlayerScene? { return skView.scene as? MIDIPlayerScene }

  // MARK: - Managing state

  private var notificationReceptionist: NotificationReceptionist?

  private struct State: OptionSetType {
    let rawValue: Int
    static let Default           = State(rawValue: 0b0000_0000)
    static let PopoverActive     = State(rawValue: 0b0000_0001)
    static let PlayerPlaying     = State(rawValue: 0b0000_0010)
    static let PlayerFieldActive = State(rawValue: 0b0000_0100)
    static let MIDINodeAdded     = State(rawValue: 0b0000_1000)
    static let TrackAdded        = State(rawValue: 0b0001_0000)
    static let PlayerRecording   = State(rawValue: 0b0010_0000)
  }

  private var state: State = []

  /** updateState */
  private func updateUIState() {
    revertBarButtonItem.enabled = state ∋ .MIDINodeAdded && state ∌ .PopoverActive // We have a node and aren't showing popover
    saveBarButtonItem.enabled = state ∋ .TrackAdded && state ∌ .PopoverActive // We have a track and aren't showing popover
    stopBarButtonItem.enabled = state ∋ .PlayerPlaying
    (state ∋ .PlayerPlaying ? ControlImage.Pause : ControlImage.Play).decorateBarButtonItem(playPauseBarButtonItem)
    popoverBlur.hidden = state ∌ .PopoverActive

  }

  private enum ControlImage {
    case Pause, Play
    func decorateBarButtonItem(item: ImageBarButtonItem) {
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
      updateUIState()
    }
  }

  // MARK: - Popover management

  private enum Popover {
    case None, Template, Instrument, Mixer
    var view: PopoverView? {
      guard let delegate = UIApplication.sharedApplication().delegate,
                window = delegate.window,
                controller = window?.rootViewController as? MIDIPlayerViewController else { return nil }
      switch self {
        case .Template:   return controller.templatePopoverView
        case .Instrument: return controller.instrumentPopoverView
        case .Mixer:      return controller.mixerPopoverView
        case .None:       return nil
      }
    }
  }

  private var popover = Popover.None {
    didSet {
      guard oldValue != popover else { return }
      oldValue.view?.hidden = true; popover.view?.hidden = false
      state ⊻= .PopoverActive
      updateUIState()
    }
  }

  // MARK: - Popover content view controllers

  private var _mixerViewController: MixerViewController?
  private var mixerViewController: MixerViewController {
    guard _mixerViewController == nil else { return _mixerViewController! }
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    _mixerViewController = storyboard.instantiateViewControllerWithIdentifier("Mixer") as? MixerViewController
    guard _mixerViewController != nil else { fatalError("failed to instantiate mixer view controller from storyboard") }
    addChildViewController(_mixerViewController!)
    return _mixerViewController!
  }

  private var _instrumentViewController: InstrumentViewController?
  private var instrumentViewController: InstrumentViewController {
    guard _instrumentViewController == nil else { return _instrumentViewController! }
    _instrumentViewController = InstrumentViewController()
    addChildViewController(_instrumentViewController!)
    return _instrumentViewController!
  }

  private var _templateViewController: TemplateViewController?
  private var templateViewController: TemplateViewController {
    guard _templateViewController == nil else { return _templateViewController! }
    _templateViewController = TemplateViewController()
    addChildViewController(_templateViewController!)
    return _templateViewController!
  }

  // MARK: - Popover views

  private var _mixerPopoverView: PopoverView?
  private var mixerPopoverView: PopoverView {
    guard _mixerPopoverView == nil else { return _mixerPopoverView! }
    _mixerPopoverView = PopoverView(autolayout: true)
    _mixerPopoverView!.location = .Top
    _mixerPopoverView!.nametag = "mixerPopover"

    let mixerView = mixerViewController.view
    _mixerPopoverView!.contentView.addSubview(mixerView)
    _mixerPopoverView!.constrain(𝗩|mixerView|𝗩, 𝗛|mixerView|𝗛)

    return _mixerPopoverView!
  }

  private var _instrumentPopoverView: PopoverView?
  private var instrumentPopoverView: PopoverView {
    guard _instrumentPopoverView == nil else { return _instrumentPopoverView! }
    _instrumentPopoverView = PopoverView(autolayout: true)
    _instrumentPopoverView!.location = .Top
    _instrumentPopoverView!.nametag = "instrumentPopover"

    let instrumentView = instrumentViewController.view
    _instrumentPopoverView!.contentView.addSubview(instrumentView)
    _instrumentPopoverView!.constrain(𝗩|instrumentView|𝗩, 𝗛|instrumentView|𝗛)

    return _instrumentPopoverView!
  }

  private var _templatePopoverView: PopoverView?
  private var templatePopoverView: PopoverView {
    guard _templatePopoverView == nil else { return _templatePopoverView! }
    _templatePopoverView = PopoverView(autolayout: true)
    _templatePopoverView!.location = .Top
    _templatePopoverView!.nametag = "templatePopover"

    let templateView = templateViewController.view
    _templatePopoverView!.contentView.addSubview(templateView)
    _templatePopoverView!.constrain(𝗩|templateView|𝗩, 𝗛|templateView|𝗛)

    return _templatePopoverView!
  }

  // MARK: - UIViewController overridden methods

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    tempoLabel.font = Eveleth.shadowFontWithSize(16)

    tempoSlider.setThumbImage(AssetManager.sliderThumbImage, forState: .Normal)
    tempoSlider.setMinimumTrackImage(AssetManager.sliderMinTrackImage, forState: .Normal)
    tempoSlider.setMaximumTrackImage(AssetManager.sliderMaxTrackImage, forState: .Normal)
    tempoSlider.thumbOffset = AssetManager.sliderThumbOffset
    tempoSlider.trackShowsThroughThumb = true
    tempoSlider.valueLabelOffset = AssetManager.sliderLabelValueOffset
    tempoSlider.valueLabel.font = AssetManager.sliderLabelValueFont
    tempoSlider.valueLabel.textColor = AssetManager.sliderLabelValueColor
    tempoSlider.valueLabelHidden = false
    tempoSlider.labelTextForValue = {String(Int($0))}

    // Configure the view.
    //    skView.showsFPS = true
    //    skView.showsNodeCount = true

    /* Sprite Kit applies additional optimizations to improve rendering performance */
    skView.ignoresSiblingOrder = true

    skView.presentScene(MIDIPlayerScene(size: skView.bounds.size))
    playerScene!.paused = true

    guard notificationReceptionist == nil else { return }
    let nodeCountDidChange: (NSNotification) -> Void = {
      [unowned self] _ in
      let isEmptyField = (self.playerScene?.midiPlayer.midiNodes.count ?? 0) == 0
      guard (self.state ∋ .MIDINodeAdded && isEmptyField)
         || (self.state ∌ .MIDINodeAdded && !isEmptyField) else { return }
      self.state ⊻= .MIDINodeAdded
      self.updateUIState()
    }
    let trackCountDidChange: (NSNotification) -> Void = {
      [unowned self] _ in
      let isEmptySequence = Sequencer.sequence.tracks.count == 0
      guard (self.state ∋ .TrackAdded && isEmptySequence)
         || (self.state ∌ .TrackAdded && !isEmptySequence) else { return }
      self.state ⊻= .TrackAdded
      self.updateUIState()
    }
    let queue = NSOperationQueue.mainQueue()
    let nodeCallback: NotificationReceptionist.Callback = (MIDIPlayerNode.self, queue, nodeCountDidChange)
    let trackCallback: NotificationReceptionist.Callback = (Sequence.self, queue, trackCountDidChange)
    let callbacks: [NotificationReceptionist.Notification:NotificationReceptionist.Callback] = [
      MIDIPlayerNode.Notification.NodeAdded.rawValue: nodeCallback,
      MIDIPlayerNode.Notification.NodeRemoved.rawValue: nodeCallback,
      Sequence.Notification.TrackAdded.rawValue: trackCallback,
      Sequence.Notification.TrackRemoved.rawValue: trackCallback
    ]
    notificationReceptionist = NotificationReceptionist(callbacks: callbacks)

  }

  /**
  viewDidAppear:

  - parameter animated: Bool
  */
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    guard let templatePresentingView = templateBarButtonItem.customView,
              mixerPresentingView = mixerBarButtonItem.customView,
              instrumentPresentingView = instrumentBarButtonItem.customView else { return }

    // Add template popover, initially hidden

    let templatePopover = templatePopoverView
    templatePopover.hidden = true
    view.addSubview(templatePopover)

    var necessaryWidth = (templatePopover.intrinsicContentSize().width / 2) + 2
    let viewWidth = view.bounds.width
    var presentingViewFrame = templatePresentingView.frame
    var halfPresentingViewWidth = presentingViewFrame.width / 2
    var spaceToLeft = presentingViewFrame.minX + halfPresentingViewWidth
    var spaceToRight = viewWidth - presentingViewFrame.maxX + halfPresentingViewWidth

    var offset: CGFloat
    switch (spaceToLeft > necessaryWidth, spaceToRight > necessaryWidth) {
      case (true, false):                offset = necessaryWidth - spaceToRight
      case (false, true):                offset = necessaryWidth - spaceToLeft
      case (true, true), (false, false): offset = 0
    }

    templatePopover.xOffset = offset

    // Add mixer popover, initially hidden

    let mixerPopover = mixerPopoverView
    mixerPopover.hidden = true

    view.addSubview(mixerPopover)

    necessaryWidth = (mixerPopover.intrinsicContentSize().width / 2) + 2
    presentingViewFrame = mixerPresentingView.frame
    halfPresentingViewWidth = presentingViewFrame.width / 2
    spaceToLeft = presentingViewFrame.minX + halfPresentingViewWidth
    spaceToRight = viewWidth - presentingViewFrame.maxX + halfPresentingViewWidth

    switch (spaceToLeft > necessaryWidth, spaceToRight > necessaryWidth) {
      case (true, false):                offset = necessaryWidth - spaceToRight
      case (false, true):                offset = necessaryWidth - spaceToLeft
      case (true, true), (false, false): offset = 0
    }

    mixerPopover.xOffset = offset

    // Add instrument popover, initially hidden

    let instrumentPopover = instrumentPopoverView
    instrumentPopover.hidden = true

    view.addSubview(instrumentPopover)

    necessaryWidth = (instrumentPopover.intrinsicContentSize().width / 2) + 2
    presentingViewFrame = instrumentPresentingView.frame
    halfPresentingViewWidth = presentingViewFrame.width / 2
    spaceToLeft = presentingViewFrame.minX + halfPresentingViewWidth
    spaceToRight = viewWidth - presentingViewFrame.maxX + halfPresentingViewWidth

    switch (spaceToLeft > necessaryWidth, spaceToRight > necessaryWidth) {
      case (true, false):                offset = necessaryWidth - spaceToRight
      case (false, true):                offset = necessaryWidth - spaceToLeft
      case (true, true), (false, false): offset = 0
    }

    instrumentPopover.xOffset = offset

    view.setNeedsUpdateConstraints()

  }

  /** updateViewConstraints */
  override func updateViewConstraints() {
    super.updateViewConstraints()

    guard let mixerPopover = _mixerPopoverView,
              mixerButton = mixerBarButtonItem?.customView,
              templatePopover = _templatePopoverView,
              templateButton = templateBarButtonItem?.customView,
              instrumentPopover = _instrumentPopoverView,
              instrumentButton = instrumentBarButtonItem?.customView
      else { return }

    var id = MoonKit.Identifier(self, "MixerPopover")
    if view.constraintsWithIdentifier(id).count == 0 {
      view.constrain([
        mixerPopover.centerX => mixerButton.centerX - mixerPopover.xOffset,
        mixerPopover.top => mixerButton.bottom
      ] --> id)
    }

    id = MoonKit.Identifier(self, "TemplatePopover")
    if view.constraintsWithIdentifier(id).count == 0 {
      view.constrain([
        templatePopover.centerX => templateButton.centerX - templatePopover.xOffset,
        templatePopover.top => templateButton.bottom
      ] --> id)
    }

    id = MoonKit.Identifier(self, "InstrumenetPopover")
    if view.constraintsWithIdentifier(id).count == 0 {
      view.constrain([
        instrumentPopover.centerX => instrumentButton.centerX - instrumentPopover.xOffset,
        instrumentPopover.top => instrumentButton.bottom
      ] --> id)
    }

  }

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

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  override func prefersStatusBarHidden() -> Bool { return true }
}
