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
      logDebug("[\(mode)] oldValue = \(oldValue)  active = \(active)")
      guard active != oldValue && active && mode == .new else { return }
      MIDIPlayer.playerContainer?.presentContent(for: self)
    }
  }

  enum Mode { case new, existing }
  let mode: Mode

  init(playerNode: MIDIPlayerNode, mode: Mode) {
    self.mode = mode
    super.init(playerNode: playerNode)
  }

  fileprivate func didChangeGenerator(_ generator: AnyMIDIGenerator) {
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

    let storyboard = UIStoryboard(name: "Generator", bundle: nil)
    let secondaryContent: GeneratorViewController

    switch mode {

      case .existing:
        guard let node = node else {
          fatalError("cannot show view controller when no node has been chosen")
        }
        secondaryContent = storyboard.instantiateViewController(withIdentifier: "GeneratorWithArrows")
                           as! GeneratorViewController
        secondaryContent.loadGenerator(node.generator)
        secondaryContent.didChangeGenerator = weakMethod(self, GeneratorTool.didChangeGenerator)
        secondaryContent.previousAction = weakMethod(self, NodeSelectionTool.previousNode)
        secondaryContent.nextAction = weakMethod(self, NodeSelectionTool.nextNode)
        secondaryContent.supportedActions ∪= [.Previous, .Next]
        secondaryContent.disabledActions = player.midiNodes.count > 1 ? [.None] : [.Previous, .Next]
        //TODO: Add cancel/confirm actions?

      case .new:
        secondaryContent = storyboard.instantiateViewController(withIdentifier: "Generator")
                           as! GeneratorViewController
        secondaryContent.didChangeGenerator = {
          MIDIPlayer.addTool?.generator = $0
          Sequencer.sequence?.currentTrack?.instrument.playNote($0)
        }

    }

    return secondaryContent
  }

  override func didHide(content: SecondaryControllerContent, dismissalAction: SecondaryControllerContainer.DismissalAction) {
    super.didHide(content: content, dismissalAction: dismissalAction)
    guard MIDIPlayer.currentTool.toolType === self && mode == .new else { return }
    MIDIPlayer.currentTool = .none
  }

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

  override func didSelectNode() {
    guard active && mode == .existing && node != nil else { return }
    MIDIPlayer.playerContainer?.presentContent(for: self)
  }
}

final class GeneratorViewController: UIViewController, SecondaryControllerContent {

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
      chordPicker?.labels = ["–"] + Chord.ChordPattern.StandardChordPattern.allCases.map {$0.name}
    }
  }

  var didChangeGenerator: ((AnyMIDIGenerator) -> Void)?

  fileprivate func refresh() {
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
      case .note: chordPicker.selection = 0
      case .chord(let generator):
        if let pattern = Chord.ChordPattern.StandardChordPattern(rawValue: generator.chord.pattern.rawValue) {
          chordPicker.selection = pattern.index
        } else {
          chordPicker.selection = 0
        }
    }
  }

  fileprivate var loading = false
  func loadGenerator(_ generator: AnyMIDIGenerator) {
    loading = true
    self.generator = generator
    loading = false
  }

  fileprivate(set) var generator = AnyMIDIGenerator(NoteGenerator()) {
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
      case 0: generator.root.modifier = .flat
      case 2: generator.root.modifier = .sharp
      default: generator.root.modifier = nil
    }
  }

  @IBAction func didPickChord() {
    let newValue: Chord.ChordPattern.StandardChordPattern?
    switch chordPicker.selection {
      case 0: newValue = nil
      case let idx: newValue = Chord.ChordPattern.StandardChordPattern.allCases[idx - 1]
    }
    switch (generator, newValue) {
      case let (.note(generator), newValue?):
        self.generator = AnyMIDIGenerator(ChordGenerator(pattern: newValue.pattern, generator: generator))
      case (.chord(var generator), let newValue?):
        generator.chord.pattern = newValue.pattern; self.generator = AnyMIDIGenerator(generator)
      case (.chord(let generator), nil):
        self.generator = AnyMIDIGenerator(NoteGenerator(generator: generator))
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

