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

class MIDIPlayerSceneViewController: UIViewController {

  @IBOutlet weak var tempoSlider: Slider!
  @IBOutlet weak var tempoLabel: UILabel!
  @IBOutlet weak var skView: SKView!
  @IBOutlet weak var templateBarButtonItem: ImageBarButtonItem!

  private var playerScene: MIDIPlayerScene? { return skView?.scene as? MIDIPlayerScene }
  private var midiPlayer: MIDIPlayerNode? { return playerScene?.midiPlayer }

  /** tempoSliderValueDidChange */
  @IBAction func tempoSliderValueDidChange() { MSLogDebug("value = \(tempoSlider.value)") }

  /** revert */
  @IBAction func revert() { (skView?.scene as? MIDIPlayerScene)?.revert() }

  /** sliders */
  @IBAction func sliders() { MSLogDebug("") }

  /** instrument */
  @IBAction func instrument() { MSLogDebug("") }

  /** save */
  @IBAction func save() { MSLogDebug("") }

  /** skipBack */
  @IBAction func skipBack() { MSLogDebug("") }

  /** play */
  @IBAction func play() { MSLogDebug("") }

  /** stop */
  @IBAction func stop() { MSLogDebug("") }

  /** template */
  @IBAction func template() {

    guard let window = view.window, presentingView = templateBarButtonItem.customView else { return }

    let popoverView = midiNodeTemplatePopover()
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

  private var _midiNodeTemplatePopover: PopoverFormView?

  private func midiNodeTemplatePopover() -> PopoverFormView {
    guard _midiNodeTemplatePopover == nil else { return _midiNodeTemplatePopover! }

    let popoverView = PopoverFormView(form: midiNodeTemplateForm(), dismissal: nil)
    popoverView.location = .Top
    popoverView.nametag = "popover"
    popoverView.formView.labelFont = Eveleth.lightFontWithSize(14)
    popoverView.formView.labelTextColor = Chameleon.kelleyPearlBush
    popoverView.formView.controlFont = Eveleth.thinFontWithSize(14)
    popoverView.formView.controlTextColor = Chameleon.quietLightLobLollyDark
    popoverView.formView.controlSelectedFont = Eveleth.regularFontWithSize(14)
    popoverView.formView.controlSelectedTextColor = Chameleon.quietLightLobLolly
    popoverView.formView.tintColor = Chameleon.flatWhiteDark
    _midiNodeTemplatePopover = popoverView

    return popoverView
  }

  private var _midiNodeTemplateForm: Form?

  /**
  midiNodeTemplateForm

  - returns: Form
  */
  private func midiNodeTemplateForm() -> Form {
    guard _midiNodeTemplateForm == nil else { return _midiNodeTemplateForm! }
    guard let player = playerScene?.midiPlayer else { return Form(fields: []) }

    enum FieldName: String { case TextureType = "Type", Note, Velocity, Duration, SoundSet = "Sound Set", Program, Channel }

    let typeField = FormPickerField(name: FieldName.TextureType.rawValue,
                                   value: MIDINode.TextureType.allCases.indexOf(player.textureType) ?? 0,
                                   choices: MIDINode.TextureType.allCases.map { $0.image})

    let noteField = FormPickerField(name: FieldName.Note.rawValue,
                                    value: Int(player.note.value.midi),
                                    choices: Instrument.MIDINote.all.map({$0.rawValue}))

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
                                        value: Instrument.SoundSet.all.indexOf(player.soundSet) ?? 0,
                                        choices: Instrument.SoundSet.all.map({$0.baseName}))

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

    _midiNodeTemplateForm =  Form(fields: fields) {
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
          if let midi = field.value as? Int { player.note.value = Instrument.MIDINote(midi: UInt8(midi)) }

        case .Velocity:
          if let velocity = field.value as? Float { player.note.velocity = UInt8(velocity) }

        case .Duration:
          if let duration = field.value as? Float { player.note.duration = Double(duration) }

        case .SoundSet:
          if let idx = field.value as? Int where Instrument.SoundSet.all.indices.contains(idx) {
            let soundSet = Instrument.SoundSet.all[idx]
            guard player.soundSet != soundSet else { break }
            player.soundSet = soundSet
            player.program = 0
            programField.value = programField.choices.count > 0 ? 0 : -1
            programField.choices = player.soundSet.programs
          }

        case .Program:
          if let idx = field.value as? Int where player.soundSet.programs.indices.contains(idx) { player.program = UInt8(idx) }

        case .Channel:
          if let channel = field.value as? Double { player.channel = UInt8(channel) }
      }

    }

    return _midiNodeTemplateForm!
  }

  static let sliderThumbImage = UIImage(named: "marker1")?.recoloredImageWithColor(Chameleon.kelleyPearlBush)
  static let sliderMinTrackImage = UIImage(named: "line1")?.imageWithColor(rgb(146, 135, 120))
  static let sliderMaxTrackImage = UIImage(named: "line1")?.imageWithColor(rgb(246, 243, 240))
  static let sliderThumbOffset = UIOffset(horizontal: 0, vertical: -16)

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

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
  }

  /**
  viewDidDisappear:

  - parameter animated: Bool
  */
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    _midiNodeTemplateForm = nil
    _midiNodeTemplatePopover = nil
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
  override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning(); MSLogDebug("") }

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  override func prefersStatusBarHidden() -> Bool { return true }
}
