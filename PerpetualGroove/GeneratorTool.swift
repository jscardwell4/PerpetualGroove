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

final class GeneratorTool: NodeSelectionTool, SecondaryControllerContentDelegate {//, ConfigurableToolType {

  override var active: Bool  {
    didSet {
      logDebug("[\(mode)] oldValue = \(oldValue)  active = \(active)")
      guard active != oldValue && active && mode == .New else { return }
      MIDIPlayer.playerContainer?.presentContentForDelegate(self)
    }
  }

  enum Mode { case New, Existing }
  let mode: Mode

  /**
   initWithPlayerNode:mode:

   - parameter playerNode: MIDIPlayerNode
   - parameter mode: Mode
  */
  init(playerNode: MIDIPlayerNode, mode: Mode) {
    self.mode = mode
    super.init(playerNode: playerNode)
  }

  /**
   didChangeGenerator:

   - parameter generator: MIDIGenerator
  */
  private func didChangeGenerator(generator: MIDIGenerator) {
    guard let node = node else { return }
    MIDIPlayer.undoManager.registerUndoWithTarget(node) {
      [initialGenerator = node.generator] node in
      node.generator = initialGenerator
      MIDIPlayer.undoManager.registerUndoWithTarget(node) {
        $0.generator = generator
      }
    }
    node.generator = generator
  }

  var secondaryContent: SecondaryControllerContent {
    guard _secondaryContent == nil else { return _secondaryContent! }

    let storyboard = UIStoryboard(name: "Generator", bundle: nil)
    let secondaryContent: GeneratorViewController

    switch mode {

      case .Existing:
        guard let node = node else {
          fatalError("cannot show view controller when no node has been chosen")
        }
        secondaryContent = storyboard.instantiateViewControllerWithIdentifier("GeneratorWithArrows")
                           as! GeneratorViewController
        secondaryContent.loadGenerator(node.generator)
        secondaryContent.didChangeGenerator = weakMethod(self, GeneratorTool.didChangeGenerator)
        secondaryContent.previousAction = weakMethod(self, NodeSelectionTool.previousNode)
        secondaryContent.nextAction = weakMethod(self, NodeSelectionTool.nextNode)
        secondaryContent.supportedActions ∪= [.Previous, .Next]
        secondaryContent.disabledActions = player.midiNodes.count > 1 ? [.None] : [.Previous, .Next]
        //TODO: Add cancel/confirm actions?

      case .New:
        secondaryContent = storyboard.instantiateViewControllerWithIdentifier("Generator")
                           as! GeneratorViewController
        secondaryContent.didChangeGenerator = {
          MIDIPlayer.addTool?.generator = $0
          Sequencer.sequence?.currentTrack?.instrument.playNote($0)
        }

    }


    return secondaryContent
  }

  /** didHideContent */
  override func didHideContent(dismissalAction: SecondaryControllerContainer.DismissalAction) {
    super.didHideContent(dismissalAction)
    guard MIDIPlayer.currentTool.toolType === self && mode == .New else { return }
    MIDIPlayer.currentTool = .None
  }

  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard mode == .Existing else { return }
    super.touchesBegan(touches, withEvent: event)
  }

  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard mode == .Existing else { return }
    super.touchesBegan(touches, withEvent: event)
  }

  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard mode == .Existing else { return }
    super.touchesMoved(touches, withEvent: event)
  }

  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    guard mode == .Existing else { return }
    super.touchesCancelled(touches, withEvent: event)
  }

  /** didSelectNode */
  override func didSelectNode() {
    guard active && mode == .Existing && node != nil else { return }
    MIDIPlayer.playerContainer?.presentContentForDelegate(self)
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

  var didChangeGenerator: ((MIDIGenerator) -> Void)?

  /** refresh */
  private func refresh() {
    guard isViewLoaded() else { return }
    pitchPicker.selection = generator.root.natural.index
    switch generator.root.modifier {
      case .Flat?:  modifierPicker.selection = 0
      case .Sharp?: modifierPicker.selection = 2
      default:      modifierPicker.selection = 1
    }
    octavePicker.selection   = generator.octave.index
    durationPicker.selection = generator.duration.index
    velocityPicker.selection = generator.velocity.index
    switch generator {
      case .Note: chordPicker.selection = 0
      case .Chord(let generator):
        if let pattern = Chord.ChordPattern.StandardChordPattern(rawValue: generator.chord.pattern.rawValue) {
          chordPicker.selection = pattern.index
        } else {
          chordPicker.selection = 0
        }
    }
  }

  private var loading = false
  func loadGenerator(generator: MIDIGenerator) {
    loading = true
    self.generator = generator
    loading = false
  }

  private(set) var generator = MIDIGenerator(NoteGenerator()) {
    didSet {
      guard !loading else { return }
      didChangeGenerator?(generator)
    }
  }

  /** didPickPitch */
  @IBAction func didPickPitch() {
    generator.root.natural = Natural.allCases[pitchPicker.selection]
  }

  /** didPickOctave */
  @IBAction func didPickOctave() {
    generator.octave = Octave.allCases[octavePicker.selection]
  }

  /** didPickModifier */
  @IBAction func didPickModifier() {
    switch modifierPicker.selection {
      case 0: generator.root.modifier = .Flat
      case 2: generator.root.modifier = .Sharp
      default: generator.root.modifier = nil
    }
  }

  /** didPickChord */
  @IBAction func didPickChord() {
    let newValue: Chord.ChordPattern.StandardChordPattern?
    switch chordPicker.selection {
      case 0: newValue = nil
      case let idx: newValue = Chord.ChordPattern.StandardChordPattern.allCases[idx - 1]
    }
    switch (generator, newValue) {
      case let (.Note(generator), newValue?):
        self.generator = MIDIGenerator(ChordGenerator(pattern: newValue.pattern, generator: generator))
      case (.Chord(var generator), let newValue?):
        generator.chord.pattern = newValue.pattern; self.generator = MIDIGenerator(generator)
      case (.Chord(let generator), nil):
        self.generator = MIDIGenerator(NoteGenerator(generator: generator))
      default:
        break
    }
  }

  /** didPickDuration */
  @IBAction func didPickDuration() {
    generator.duration = Duration.allCases[durationPicker.selection]
  }

  /** didPickVelocity */
  @IBAction func didPickVelocity() {
    generator.velocity = Velocity.allCases[velocityPicker.selection]
  }

  /** viewDidLoad */
  override func viewDidAppear(animated: Bool) { super.viewDidAppear(animated); refresh() }
  
 }

