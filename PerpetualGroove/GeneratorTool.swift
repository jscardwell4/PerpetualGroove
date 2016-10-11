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
      MIDIPlayer.playerContainer?.presentContent(for: self)
    }
  }

  let mode: Mode

  init(playerNode: MIDIPlayerNode, mode: Mode) {
    self.mode = mode
    super.init(playerNode: playerNode)
  }

  private func didChangeGenerator(_ generator: AnyMIDIGenerator) {
    guard let node = node else { return }

    MIDIPlayer.undoManager.registerUndo(withTarget: node) {
      [initialGenerator = node.generator] node in

      node.generator = initialGenerator

      MIDIPlayer.undoManager.registerUndo(withTarget: node) {
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
        secondaryContent.supportedActions ∪= [.Previous, .Next]
        secondaryContent.disabledActions = player.midiNodes.count > 1 ? [.None] : [.Previous, .Next]
        //TODO: Add cancel/confirm actions?

      case .new:
        secondaryContent.didChangeGenerator = {
          MIDIPlayer.addTool?.generator = $0
          Sequencer.sequence?.currentTrack?.instrument.playNote($0)
        }

    }

    return secondaryContent
  }

  override func didHide(content: SecondaryControllerContent,
                        dismissalAction: SecondaryControllerContainer.DismissalAction)
  {
    super.didHide(content: content, dismissalAction: dismissalAction)
    guard MIDIPlayer.currentTool.tool === self && mode == .new else { return }
    MIDIPlayer.currentTool = .none
  }

  override func didSelectNode() {
    guard active && mode == .existing && node != nil else { return }
    MIDIPlayer.playerContainer?.presentContent(for: self)
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

  var supportedActions: SecondaryControllerContainer.SupportedActions = [.Cancel, .Confirm]
  var disabledActions: SecondaryControllerContainer.SupportedActions = .None

  @IBOutlet weak var pitchPicker:    InlinePickerView!
  @IBOutlet weak var octavePicker:   InlinePickerView!
  @IBOutlet weak var durationPicker: InlinePickerView!
  @IBOutlet weak var velocityPicker: InlinePickerView!
  @IBOutlet weak var modifierPicker: InlinePickerView!
  @IBOutlet weak var chordPicker:    InlinePickerView! {
    didSet {
      chordPicker?.labels = ["–"] + Chord.Pattern.Standard.allCases.map {$0.name}
    }
  }

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

