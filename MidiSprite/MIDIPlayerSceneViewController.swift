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

class MIDIPlayerSceneViewController: UIViewController {

  @IBOutlet weak var tempoSlider: Slider!
  @IBOutlet weak var tempoLabel: UILabel!
  @IBOutlet weak var skView: SKView!
  @IBOutlet weak var templateBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var playPauseBarButtonItem: ImageBarButtonItem!
  @IBOutlet weak var stopBarButtonItem: ImageBarButtonItem!

  private var playerScene: MIDIPlayerScene? { return skView?.scene as? MIDIPlayerScene }
  private var midiPlayer: MIDIPlayerNode? { return playerScene?.midiPlayer }

  private(set) var playing = false {
    didSet {
      guard let playerScene = playerScene else { return }
      if playing {
        do { try MIDIManager.start() } catch { logError(error) }
        playerScene.paused = false
        playPauseBarButtonItem.image = UIImage(named: "pause")
        playPauseBarButtonItem.highlightedImage = UIImage(named: "pause-selected")
        playing = true
      } else {
        do { try MIDIManager.stop() } catch { logError(error) }
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
  @IBAction func sliders() { MSLogDebug("sliders() not yet implemented") }

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
    stopBarButtonItem.tintColor = Chameleon.flatGrayDark
  }

  /** template */
  @IBAction func template() { templatePopover?.hidden = false }

  private var templatePopover: PopoverFormView?

  /**
  generateTemplatePopover

  - returns: PopoverFormView
  */
  private func generateTemplatePopover() -> PopoverFormView {
    guard templatePopover == nil else { return templatePopover! }
    guard let window = view.window else { fatalError("cannot generate the template popover without a window") }

    templatePopover = PopoverFormView(form: generateTemplateForm(), backdrop: window.blurredSnapshot()) { $0.hidden = true }
    templatePopover!.blur = false
    templatePopover!.location = .Top
    templatePopover!.nametag = "popover"
    templatePopover!.formView.labelFont = Eveleth.lightFontWithSize(14)
    templatePopover!.formView.labelTextColor = Chameleon.kelleyPearlBush
    templatePopover!.formView.controlFont = Eveleth.thinFontWithSize(14)
    templatePopover!.formView.controlTextColor = Chameleon.quietLightLobLollyDark
    templatePopover!.formView.controlSelectedFont = Eveleth.regularFontWithSize(14)
    templatePopover!.formView.controlSelectedTextColor = Chameleon.quietLightLobLolly
    templatePopover!.formView.tintColor = Chameleon.flatWhiteDark

    return templatePopover!
  }

  private var templateForm: Form?

  /**
  generateTemplateForm

  - returns: Form
  */
  private func generateTemplateForm() -> Form {
    guard templateForm == nil else { return templateForm! }
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
    channelField.incrementImage = UIImage(named: "increment")
    channelField.decrementImage = UIImage(named: "decrement")

    let fields = [typeField, noteField, velocityField, durationField, soundSetField, programField, channelField]

    templateForm =  Form(fields: fields) {
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

    return templateForm!
  }

  static let sliderThumbImage = UIImage(named: "marker1")?.recoloredImageWithColor(Chameleon.kelleyPearlBush)
  static let sliderMinTrackImage = UIImage(named: "line1")?.imageWithColor(rgb(146, 135, 120))
  static let sliderMaxTrackImage = UIImage(named: "line1")?.imageWithColor(rgb(246, 243, 240))
  static let sliderThumbOffset = UIOffset(horizontal: 0, vertical: -16)

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    stopBarButtonItem.tintColor = Chameleon.flatGrayDark
    
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
    guard let window = view.window, presentingView = templateBarButtonItem.customView else { return }

    let popoverView = generateTemplatePopover()
    popoverView.hidden = true
    window.addSubview(popoverView)

    let necessaryWidth = (popoverView.intrinsicContentSize().width / 2) + 2
    let windowWidth = window.bounds.width
    let presentingViewFrame = presentingView.frame
    let halfPresentingViewWidth = presentingViewFrame.width / 2
    let spaceToLeft = presentingViewFrame.minX + halfPresentingViewWidth
    let spaceToRight = windowWidth - presentingViewFrame.maxX + halfPresentingViewWidth

    let offset: CGFloat
    switch (spaceToLeft > necessaryWidth, spaceToRight > necessaryWidth) {
      case (true, false):                offset = necessaryWidth - spaceToRight
      case (false, true):                offset = necessaryWidth - spaceToLeft
      case (true, true), (false, false): offset = 0
    }

    popoverView.xOffset = offset

    let id = MoonKit.Identifier(self, "Popover")
    window.constrain(
      popoverView.centerX => presentingView.centerX - offset --> id,
      popoverView.top => presentingView.bottom --> id
    )
  }

  /**
  viewDidDisappear:

  - parameter animated: Bool
  */
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    templateForm = nil
    templatePopover = nil
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
    super.didReceiveMemoryWarning()
    templateForm = nil
    templatePopover = nil
    MSLogDebug("")
  }

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  override func prefersStatusBarHidden() -> Bool { return true }
}
