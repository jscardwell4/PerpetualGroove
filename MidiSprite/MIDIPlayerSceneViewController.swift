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
  @IBOutlet weak var playPauseBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var stopBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var mixerBarButtonItem: ImageBarButtonItem!

  private var playerScene: MIDIPlayerScene? { return skView?.scene as? MIDIPlayerScene }
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
  @IBAction func tempoSliderValueDidChange() { MSLogDebug("value = \(tempoSlider.value)") }

  /** revert */
  @IBAction func revert() { (skView?.scene as? MIDIPlayerScene)?.revert() }

  /** sliders */
  @IBAction func mixer() {
    let mixerPopover = mixerPopoverView
    mixerPopover.hidden = !mixerPopover.hidden
    if !mixerPopover.hidden {
      mixerViewController.updateTracks()
    }
  }

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
    _mixerPopoverView!.constrain(𝗩|-mixerView-|𝗩, 𝗛|-mixerView-|𝗛)

    return _mixerPopoverView!
  }

  /** instrument */
  @IBAction func instrument() { MSLogDebug("instrument() not yet implemented") }

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
  @IBAction func template() { templatePopoverView.hidden = !templatePopoverView.hidden }

  private var _templatePopoverView: PopoverFormView?
  private var templatePopoverView: PopoverFormView {
    guard _templatePopoverView == nil else { return _templatePopoverView! }

    _templatePopoverView = PopoverFormView(form: generateTemplateForm())
    _templatePopoverView!.location                          = .Top
    _templatePopoverView!.nametag                           = "templatePopover"
    _templatePopoverView!.formView.labelFont                = Eveleth.lightFontWithSize(14)
    _templatePopoverView!.formView.labelTextColor           = Chameleon.kelleyPearlBush
    _templatePopoverView!.formView.controlFont              = Eveleth.thinFontWithSize(14)
    _templatePopoverView!.formView.controlTextColor         = Chameleon.quietLightLobLollyDark
    _templatePopoverView!.formView.controlSelectedFont      = Eveleth.regularFontWithSize(14)
    _templatePopoverView!.formView.controlSelectedTextColor = Chameleon.quietLightLobLolly
    _templatePopoverView!.formView.tintColor                = Chameleon.flatWhiteDark

    return _templatePopoverView!
  }

  /**
  generateTemplateForm

  - returns: Form
  */
  private func generateTemplateForm() -> Form {
    guard let player = playerScene?.midiPlayer else { return Form(fields: []) }

    enum FieldName: String { case TextureType = "Type", Note, Velocity, Duration, SoundSet = "Sound Set", Program, Channel }

    let typeField = FormPickerField(name: FieldName.TextureType.rawValue,
                                   value: MIDINode.TextureType.allCases.indexOf(player.textureType) ?? 0,
                                   choices: MIDINode.TextureType.allCases.map { $0.image})

    let noteField = FormPickerField(name: FieldName.Note.rawValue,
                                    value: Int(player.note.value.midi),
                                    choices: MIDINote.allCases.map({$0.rawValue}))

    let velocityField = FormSliderField(name: FieldName.Velocity.rawValue,
                                        value: Float(player.note.velocity),
                                        max: 127,
                                        minTrack: MIDIPlayerSceneViewController.sliderMinTrackImage,
                                        maxTrack: MIDIPlayerSceneViewController.sliderMaxTrackImage,
                                        thumb: MIDIPlayerSceneViewController.sliderThumbImage,
                                        offset: MIDIPlayerSceneViewController.sliderThumbOffset)

    let durationField = FormSliderField(name: FieldName.Duration.rawValue,
                                        precision: 3,
                                        value: Float(player.note.duration),
                                        max: 5,
                                        minTrack: MIDIPlayerSceneViewController.sliderMinTrackImage,
                                        maxTrack: MIDIPlayerSceneViewController.sliderMaxTrackImage,
                                        thumb: MIDIPlayerSceneViewController.sliderThumbImage,
                                        offset: MIDIPlayerSceneViewController.sliderThumbOffset)


    let soundSetField = FormPickerField(name: FieldName.SoundSet.rawValue,
                                        value: SoundSet.allCases.indexOf(player.soundSet) ?? 0,
                                        choices: SoundSet.allCases.map({$0.baseName}))

    let programField = FormPickerField(name: FieldName.Program.rawValue,
                                       value: Int(player.program),
                                       choices: player.soundSet.programs)

    let channelField = FormStepperField(name: FieldName.Channel.rawValue,
                                        value: Double(player.channel ?? 0),
                                        minimumValue: 0,
                                        maximumValue: 15,
                                        stepValue: 1)
    channelField.backgroundImage = UIImage()
    channelField.dividerImage = UIImage()
    channelField.incrementImage = UIImage(named: "up")
    channelField.decrementImage = UIImage(named: "down")

    let fields = [typeField, noteField, velocityField, durationField, soundSetField, programField, channelField]

    let templateForm =  Form(fields: fields) {
      [unowned self] (form: Form, field: FormField) in

      guard let fieldName = FieldName(rawValue: field.name),
            player = self.playerScene?.midiPlayer else { return }

      switch fieldName {
        case .TextureType:
          if let idx = field.value as? Int where MIDINode.TextureType.allCases.indices.contains(idx) {
            let type = MIDINode.TextureType.allCases[idx]
            player.textureType = type
            self.templateBarButtonItem.image = type.image
        }

        case .Note:
          if let midi = field.value as? Int { player.note.value = MIDINote(midi: UInt8(midi)) }

        case .Velocity:
          if let velocity = field.value as? Float { player.note.velocity = UInt8(velocity) }

        case .Duration:
          if let duration = field.value as? Float { player.note.duration = Double(duration) }

        case .SoundSet:
          if let idx = field.value as? Int where SoundSet.allCases.indices.contains(idx) {
            let soundSet = SoundSet.allCases[idx]
            guard player.soundSet != soundSet else { break }
            player.soundSet = soundSet
            player.program = 0
            programField.value = programField.choices.count > 0 ? 0 : -1
            programField.choices = player.soundSet.programs
          }

        case .Program:
          if let idx = field.value as? Int where player.soundSet.programs.indices.contains(idx) { player.program = UInt8(idx) }

        case .Channel:
          if let channel = field.value as? Double { player.channel = MusicDeviceGroupID(channel) }
      }

    }

    return templateForm
  }

  static let sliderThumbImage = UIImage(named: "marker1")?.imageWithColor(Chameleon.kelleyPearlBush)
  static let sliderMinTrackImage = UIImage(named: "line6")?.imageWithColor(rgb(146, 135, 120))
  static let sliderMaxTrackImage = UIImage(named: "line6")?.imageWithColor(rgb(246, 243, 240))
  static let sliderThumbOffset = UIOffset(horizontal: 0, vertical: -16)

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    stopBarButtonItem.tintColor = rgb(51, 50, 49)
    
    tempoLabel.font = Eveleth.shadowFontWithSize(16)
    // For some reason `imageWithColor` doesn't work with kelleyPearlBush but the objc method does
    tempoSlider.setThumbImage(MIDIPlayerSceneViewController.sliderThumbImage, forState: .Normal)
    tempoSlider.setMinimumTrackImage(MIDIPlayerSceneViewController.sliderMinTrackImage, forState: .Normal)
    tempoSlider.setMaximumTrackImage(MIDIPlayerSceneViewController.sliderMaxTrackImage, forState: .Normal)
    tempoSlider.thumbOffset = MIDIPlayerSceneViewController.sliderThumbOffset

    let scene = MIDIPlayerScene(size: skView.bounds.size)

    // Configure the view.
    //    skView.showsFPS = true
    //    skView.showsNodeCount = true

    /* Sprite Kit applies additional optimizations to improve rendering performance */
    skView.ignoresSiblingOrder = true

    skView.presentScene(scene)
    scene.paused = true
}

  /**
  viewDidAppear:

  - parameter animated: Bool
  */
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    guard let templatePresentingView = templateBarButtonItem.customView,
              mixerPresentingView = mixerBarButtonItem.customView else { return }

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

    view.setNeedsUpdateConstraints()

  }

  /** updateViewConstraints */
  override func updateViewConstraints() {
    super.updateViewConstraints()

    guard let mixerPopover = _mixerPopoverView,
              mixerButton = mixerBarButtonItem?.customView,
              templatePopover = _templatePopoverView,
              templateButton = templateBarButtonItem?.customView
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

    if let mixerVC = _mixerViewController, mixerPopover = _mixerPopoverView where mixerPopover.hidden == true {
      mixerVC.willMoveToParentViewController(nil)
      mixerPopover.removeFromSuperview()
      mixerVC.removeFromParentViewController()
      _mixerPopoverView = nil
      _mixerViewController = nil
    }
  }

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  override func prefersStatusBarHidden() -> Bool { return true }
}
