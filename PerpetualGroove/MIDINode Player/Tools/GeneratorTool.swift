//
//  GeneratorTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/2/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

final class GeneratorTool: PresentingNodeSelectionTool {

  override var active: Bool  {
    didSet {
      guard active != oldValue && active && mode == .new else { return }
      MIDINodePlayer.playerContainer?.presentContent(for: self)
    }
  }

  let mode: Mode

  init(playerNode: MIDINodePlayerNode, mode: Mode) {
    self.mode = mode
    super.init(playerNode: playerNode)
  }

  private func didChangeGenerator(_ generator: AnyMIDIGenerator) {
    guard let node = node else { return }

    MIDINodePlayer.undoManager.registerUndo(withTarget: node) {
      [initialGenerator = node.generator] node in

      node.generator = initialGenerator

      MIDINodePlayer.undoManager.registerUndo(withTarget: node) {
        $0.generator = generator
      }

    }

    node.generator = generator
  }

  override var secondaryContent: SecondaryControllerContent {
    guard _secondaryContent == nil else { return _secondaryContent! }

    let secondaryContent = GeneratorViewController.viewController(for: mode)

    switch mode {

      case .existing:
        guard let node = node else {
          fatalError("cannot show view controller when no node has been chosen")
        }
        secondaryContent.loadGenerator(node.generator)
        secondaryContent.didChangeGenerator = weakMethod(self, GeneratorTool.didChangeGenerator)
        secondaryContent.previousAction = weakMethod(self, NodeSelectionTool.previousNode)
        secondaryContent.nextAction = weakMethod(self, NodeSelectionTool.nextNode)
        secondaryContent.supportedActions ∪= [.previous, .next]
        secondaryContent.disabledActions = player.midiNodes.count > 1 ? [.none] : [.previous, .next]
        //TODO: Add cancel/confirm actions?

      case .new:
        secondaryContent.didChangeGenerator = {
          MIDINodePlayer.addTool?.generator = $0
          Sequencer.sequence?.currentTrack?.instrument.playNote($0)
        }

    }

    return secondaryContent
  }

  override func didHide(content: SecondaryControllerContent,
                        dismissalAction: SecondaryControllerContainer.DismissalAction)
  {
    super.didHide(content: content, dismissalAction: dismissalAction)
    guard MIDINodePlayer.currentTool.tool === self && mode == .new else { return }
    MIDINodePlayer.currentTool = .none
  }

  override func didSelectNode() {
    guard active && mode == .existing && node != nil else { return }
    MIDINodePlayer.playerContainer?.presentContent(for: self)
  }

}

extension GeneratorTool/*: TouchReceiver*/ {

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard mode == .existing else { return }
    super.touchesBegan(touches, with: event)
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard mode == .existing else { return }
    super.touchesBegan(touches, with: event)
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard mode == .existing else { return }
    super.touchesMoved(touches, with: event)
  }

  override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
    guard mode == .existing else { return }
    super.touchesCancelled(touches, with: event)
  }

}

extension GeneratorTool {

  enum Mode { case new, existing }

}

final class GeneratorViewController: UIViewController, SecondaryControllerContent {

  static func viewController(for mode: GeneratorTool.Mode) -> GeneratorViewController {
    let storyboard = UIStoryboard(name: "Generator", bundle: nil)
    let identifier: String
    switch mode {
      case .new:      identifier = "Generator"
      case .existing: identifier = "GeneratorWithArrows"
    }
    return storyboard.instantiateViewController(withIdentifier: identifier) as! GeneratorViewController
  }

  var nextAction: (() -> Void)? = nil
  var previousAction: (() -> Void)? = nil

  var supportedActions: SecondaryControllerContainer.SupportedActions = [.cancel, .confirm]
  var disabledActions: SecondaryControllerContainer.SupportedActions = .none

  @IBOutlet weak var pitchPicker:    PitchSelector!
  @IBOutlet weak var octavePicker:   OctaveSelector!
  @IBOutlet weak var durationPicker: DurationSelector!
  @IBOutlet weak var velocityPicker: VelocitySelector!
  @IBOutlet weak var modifierPicker: PitchModifierSelector!
  @IBOutlet weak var chordPicker:    ChordSelector!

  var didChangeGenerator: ((AnyMIDIGenerator) -> Void)?

  private func refresh() {
    guard isViewLoaded else { return }

    pitchPicker.selection = generator.root.natural.index

    switch generator.root.modifier {
      case .flat?:  modifierPicker.selection = 0
      case .sharp?: modifierPicker.selection = 2
      default:      modifierPicker.selection = 1
    }

    octavePicker.selection   = generator.octave.index
    durationPicker.selection = generator.duration.index
    velocityPicker.selection = generator.velocity.index

    switch generator {
      case .note:                 chordPicker.selection = 0
      case .chord(let generator): chordPicker.selection = generator.chord.pattern.standardIndex ?? 0
    }
  }

  private var loading = false

  func loadGenerator(_ generator: AnyMIDIGenerator) {
    loading = true
    self.generator = generator
    loading = false
  }

  private(set) var generator = AnyMIDIGenerator() {
    didSet {
      guard !loading else { return }
      didChangeGenerator?(generator)
    }
  }

  @IBAction func didPickPitch() {
    generator.root.natural = Natural.allCases[pitchPicker.selection]
  }

  @IBAction func didPickOctave() {
    generator.octave = Octave.allCases[octavePicker.selection]
  }

  @IBAction func didPickModifier() {
    switch modifierPicker.selection {
      case 0:  generator.root.modifier = .flat
      case 2:  generator.root.modifier = .sharp
      default: generator.root.modifier = nil
    }
  }

  @IBAction func didPickChord() {

    switch generator {

      case let .note(generator) where chordPicker.selection > 0:
        let standardPattern = Chord.Pattern.Standard(index: chordPicker.selection - 1)
        let chordPattern = Chord.Pattern(standardPattern)
        self.generator = .chord(ChordGenerator(pattern: chordPattern, generator: generator))

      case var .chord(generator) where chordPicker.selection > 0:
        let standardPattern = Chord.Pattern.Standard(index: chordPicker.selection - 1)
        generator.chord.pattern = Chord.Pattern(standardPattern)
        self.generator = AnyMIDIGenerator(generator)

      case let .chord(generator):
        self.generator = .note(NoteGenerator(generator: generator))

      default:
        break
    }
    
  }

  @IBAction func didPickDuration() {
    generator.duration = Duration.allCases[durationPicker.selection]
  }

  @IBAction func didPickVelocity() {
    generator.velocity = Velocity.allCases[velocityPicker.selection]
  }

  override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); refresh() }
  
 }

final class PitchSelector: InlinePickerContainer {

  override class var contentForInterfaceBuilder: [Any] { return ["A", "B", "C", "D", "E", "F", "G"] }

  override func refresh(picker: InlinePickerView) {
    items = ["A", "B", "C", "D", "E", "F", "G"]
  }

}

final class PitchModifierSelector: InlinePickerContainer {

  private static let images: [UIImage] = {
    #if TARGET_INTERFACE_BUILDER
      return  ["flat", "natural", "sharp"].flatMap {
          [bundle = Bundle(for: DurationSelector.self)] in

          UIImage(named: $0, in: bundle, compatibleWith: nil)
      }
    #else
      return [#imageLiteral(resourceName: "flat"), #imageLiteral(resourceName: "natural"), #imageLiteral(resourceName: "sharp")]
    #endif
  }()

  override class var contentForInterfaceBuilder: [Any] { return images }

  override func refresh(picker: InlinePickerView) {
    items = PitchModifierSelector.images
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: 54, height: super.intrinsicContentSize.height)
  }

}

final class ChordSelector: InlinePickerContainer {

  private static let labels = ["–"] + Chord.Pattern.Standard.allCases.map {$0.name}

  override class var contentForInterfaceBuilder: [Any] {
    return ChordSelector.labels
  }

  override func refresh(picker: InlinePickerView) {
    items = ChordSelector.labels
  }

}

final class OctaveSelector: InlinePickerContainer {

  private static let labels = Octave.allCases.map({"\($0.rawValue)"})

  override class var contentForInterfaceBuilder: [Any] {
    return OctaveSelector.labels
  }

  override func refresh(picker: InlinePickerView) {
    items = OctaveSelector.labels
  }
  
}

final class DurationSelector: InlinePickerContainer {

  private static let images: [UIImage] = {
    #if TARGET_INTERFACE_BUILDER
     return  [
        "DoubleWhole", "DottedWhole", "Whole", "DottedHalf", "Half", "DottedQuarter",
        "Quarter", "DottedEighth", "Eighth", "DottedSixteenth", "Sixteenth",
        "DottedThirtySecond", "ThirtySecond", "DottedSixtyFourth", "SixtyFourth",
        "DottedHundredTwentyEighth", "HundredTwentyEighth", "DottedTwoHundredFiftySixth",
        "TwoHundredFiftySixth"
        ].flatMap {
          [bundle = Bundle(for: DurationSelector.self)] in

          UIImage(named: $0, in: bundle, compatibleWith: nil)
      }
    #else
      return [
        #imageLiteral(resourceName: "DoubleWhole"), #imageLiteral(resourceName: "DottedWhole"), #imageLiteral(resourceName: "Whole"), #imageLiteral(resourceName: "DottedHalf"), #imageLiteral(resourceName: "Half"), #imageLiteral(resourceName: "DottedQuarter"),
        #imageLiteral(resourceName: "Quarter"), #imageLiteral(resourceName: "DottedEighth"), #imageLiteral(resourceName: "Eighth"), #imageLiteral(resourceName: "DottedSixteenth"), #imageLiteral(resourceName: "Sixteenth"),
        #imageLiteral(resourceName: "DottedThirtySecond"), #imageLiteral(resourceName: "ThirtySecond"), #imageLiteral(resourceName: "DottedSixtyFourth"), #imageLiteral(resourceName: "SixtyFourth"),
        #imageLiteral(resourceName: "DottedHundredTwentyEighth"), #imageLiteral(resourceName: "HundredTwentyEighth"), #imageLiteral(resourceName: "DottedTwoHundredFiftySixth"),
        #imageLiteral(resourceName: "TwoHundredFiftySixth")
      ]
    #endif
  }()

  override class var contentForInterfaceBuilder: [Any] { return images }

  override func refresh(picker: InlinePickerView) {
    items = DurationSelector.images
  }
  
}

final class VelocitySelector: InlinePickerContainer {
//𝑝𝑝𝑝, 𝑝𝑝, 𝑝, 𝑚𝑝, 𝑚𝑓, 𝑓, 𝑓𝑓, 𝑓𝑓𝑓
  private static let images: [UIImage] = {
    #if TARGET_INTERFACE_BUILDER
      return  ["𝑝𝑝𝑝", "𝑝𝑝", "𝑝", "𝑚𝑝", "𝑚𝑓", "𝑓", "𝑓𝑓", "𝑓𝑓𝑓"].flatMap {
        [bundle = Bundle(for: DurationSelector.self)] in

        UIImage(named: $0, in: bundle, compatibleWith: nil)
      }
    #else
      return [#imageLiteral(resourceName:"𝑝𝑝𝑝"), #imageLiteral(resourceName:"𝑝𝑝"), #imageLiteral(resourceName:"𝑝"), #imageLiteral(resourceName:"𝑚𝑝"), #imageLiteral(resourceName:"𝑚𝑓"), #imageLiteral(resourceName:"𝑓"), #imageLiteral(resourceName:"𝑓𝑓"), #imageLiteral(resourceName:"𝑓𝑓𝑓")]
    #endif
  }()

  override class var contentForInterfaceBuilder: [Any] { return images }

  override func refresh(picker: InlinePickerView) {
    items = VelocitySelector.images
  }

  @objc func inlinePicker(_ picker: InlinePickerView, contentOffsetForItem item: Int) -> UIOffset {
    switch item {
      case 0...3: return UIOffset(horizontal: 0, vertical: 4)
      default: return .zero
    }
  }
}
