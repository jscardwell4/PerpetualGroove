//
//  MIDIPlayerSceneViewController.swift
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

final class MIDIPlayerSceneViewController: UIViewController {

  @IBOutlet weak var tempoSlider: Slider!
  @IBOutlet weak var tempoLabel: UILabel!
  @IBOutlet weak var skView: SKView!
  @IBOutlet weak var templateBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var instrumentBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var playPauseBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var stopBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var mixerBarButtonItem: ImageBarButtonItem!

  private var playerScene: MIDIPlayerScene?
  private var midiPlayer: MIDIPlayerNode? { return playerScene?.midiPlayer }

  private(set) var playing = false {
    didSet {
      guard let playerScene = playerScene else { return }
      if playing {
        do { try AudioManager.start() } catch { logError(error) }
        playerScene.paused = false
        playPauseBarButtonItem.image = UIImage(named: "pause")
        playPauseBarButtonItem.highlightedImage = UIImage(named: "pause-selected")
        playing = true
      } else {
        do { try AudioManager.stop() } catch { logError(error) }
        playerScene.paused = true
        playPauseBarButtonItem.image = UIImage(named: "play")
        playPauseBarButtonItem.highlightedImage = UIImage(named: "play-selected")
        playing = false
      }
    }
  }

  /** tempoSliderValueDidChange */
  @IBAction func tempoSliderValueDidChange() { TrackManager.tempo = Double(tempoSlider.value) }

  /** revert */
  @IBAction func revert() { (skView?.scene as? MIDIPlayerScene)?.revert() }

  /** sliders */
  @IBAction func mixer() { let mixerPopover = mixerPopoverView; mixerPopover.hidden = !mixerPopover.hidden }

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
    _mixerPopoverView!.location = .Top
    _mixerPopoverView!.nametag = "mixerPopover"

    let mixerView = mixerViewController.view
    _mixerPopoverView!.contentView.addSubview(mixerView)
    _mixerPopoverView!.constrain(𝗩|mixerView|𝗩, 𝗛|mixerView|𝗛)

    return _mixerPopoverView!
  }

  /** instrument */
  @IBAction func instrument() { let instrumentPopover = instrumentPopoverView; instrumentPopover.hidden = !instrumentPopover.hidden }

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
    _instrumentPopoverView!.location = .Top
    _instrumentPopoverView!.nametag = "instrumentPopover"

    let instrumentView = instrumentViewController.view
    _instrumentPopoverView!.contentView.addSubview(instrumentView)
    _instrumentPopoverView!.constrain(𝗩|instrumentView|𝗩, 𝗛|instrumentView|𝗛)

    return _instrumentPopoverView!
  }

  /** save */
  @IBAction func save() { MSLogDebug("save() not yet implemented") }

  /** skipBack */
  @IBAction func skipBack() { MSLogDebug("skipBack() not yet implemented") }

  /** play */
  @IBAction func play() {
    playing = !playing
    stopBarButtonItem.enabled = true
    stopBarButtonItem.tintColor = nil
  }

  /** stop */
  @IBAction func stop() {
    guard let playerScene = playerScene else { return }
    playerScene.midiPlayer.reset()
    playing = false
    stopBarButtonItem.enabled = false
    stopBarButtonItem.tintColor = rgb(51, 50, 49)
  }

  /** template */
  @IBAction func template() { let templatePopover = templatePopoverView; templatePopover.hidden = !templatePopover.hidden }
  private var _templateViewController: TemplateViewController?
  private var templateViewController: TemplateViewController {
    guard _templateViewController == nil else { return _templateViewController! }
    _templateViewController = TemplateViewController()
    addChildViewController(_templateViewController!)
    return _templateViewController!
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

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    stopBarButtonItem.tintColor = rgb(51, 50, 49)
    
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

    playerScene = MIDIPlayerScene(size: skView.bounds.size)

    // Configure the view.
    skView.showsFPS = true
    //    skView.showsNodeCount = true

    /* Sprite Kit applies additional optimizations to improve rendering performance */
    skView.ignoresSiblingOrder = true

    skView.presentScene(playerScene!)
    playerScene!.paused = true
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
    MSLogDebug("")
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
