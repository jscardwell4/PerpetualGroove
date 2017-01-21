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

/// A tool for modifying the generator assigned to new or existing midi nodes.
final class GeneratorTool: PresentingNodeSelectionTool {

  /// Overridden to trigger secondary content presentation when `active && mode == .new`.
  /// - seealso: `NodeSelectionTool.active`
  override var active: Bool  {
    didSet {
      guard active != oldValue && active && mode == .new else { return }
      MIDINodePlayer.playerContainer?.presentContent(for: self)
    }
  }

  /// Enumeration of the supported modes for which the tool can be configured.
  enum Mode {

    /// The tool is used to configure the generator assigned to new node placements.
    case new

    /// The tool is used to configure the generator assigned to an existing node.
    case existing

  }

  /// Specifies whether the generator is applied to new or existing nodes.
  let mode: Mode

  /// Initialize with a player node and mode.
  init(playerNode: MIDINodePlayerNode, mode: Mode) {
    self.mode = mode
    super.init(playerNode: playerNode)
  }

  /// Callback for changes to the secondary content's generator.
  private func didChangeGenerator(_ generator: AnyMIDIGenerator) {

    // Check that there is a node selected.
    guard let node = node else { return }

    // Register an action for undoing the changes to the node's generator.
    MIDINodePlayer.undoManager.registerUndo(withTarget: node) {
      [initialGenerator = node.generator] node in

      node.generator = initialGenerator

      // Register an action for redoing the changes to the node's generator.
      MIDINodePlayer.undoManager.registerUndo(withTarget: node) {
        $0.generator = generator
      }

    }

    // Actually change the node's generator.
    node.generator = generator

  }

  /// Overridden to return an instance of `GeneratorViewController` configured for `mode`.
  override var secondaryContent: SecondaryContent {

    // Check that there is not already a controller to return.
    guard _secondaryContent == nil else { return _secondaryContent! }

    // Create the controller.
    let secondaryContent = GeneratorViewController.viewController(for: mode)

    switch mode {

      case .existing:
        // Configure the controller to modify the generator for an existing node.

        // Check that there is a node selected.
        guard let node = node else {
          fatalError("cannot show view controller when no node has been selected")
        }

        // Load the node's generator into the controller.
        secondaryContent.loadGenerator(node.generator)

        // Set the change callback to use the tool's method.
        secondaryContent.didChangeGenerator = weakMethod(self, GeneratorTool.didChangeGenerator)

        // Connect the previous and next actions.
        secondaryContent.previousAction = weakMethod(self, NodeSelectionTool.previousNode)
        secondaryContent.nextAction = weakMethod(self, NodeSelectionTool.nextNode)
        secondaryContent.supportedActions ∪= [.previous, .next]

        // Set the disabled actions depending on the number of nodes in the player.
        secondaryContent.disabledActions = player.midiNodes.count > 1 ? [.none] : [.previous, .next]

        //TODO: Add cancel/confirm actions?

      case .new:
        // Configure the controller to modify the generator given to new nodes.

        // Assign a closure for handling generator changes.
        secondaryContent.didChangeGenerator = {

          // Update the add tool's generator with the new generator value.
          MIDINodePlayer.addTool?.generator = $0

          // Play a note through the instrument of the current track of the current sequence using the
          // new generator.
          Sequence.current?.currentTrack?.instrument.playNote($0)

        }

    }

    return secondaryContent

  }

  /// Overridden to deselect the tool when it is the current tool of `MIDINodePlayer` and `mode == .new`
  /// in addition to actions performed in `super.didHide(content:dismissalAction:)`.
  override func didHide(content: SecondaryContent, dismissalAction: DismissalAction) {

    // Invoke super.
    super.didHide(content: content, dismissalAction: dismissalAction)

    // Check that the tool is the current tool and `mode == .new`.
    guard MIDINodePlayer.currentTool.tool === self && mode == .new else { return }

    // Clear the player's current tool.
    MIDINodePlayer.currentTool = .none

  }

  /// Overridden to be a noop unless `mode == .existing`.
  override func didSelectNode() {

    // Check the tool's mode.
    guard mode == .existing else { return }

    super.didSelectNode()

  }

  /// Overridden to be a noop when `mode != .existing`.
  override func touchesBegan(_ touches: Set<UITouch>) {
    guard mode == .existing else { return }
    super.touchesBegan(touches)
  }

  /// Overridden to be a noop when `mode != .existing`.
  override func touchesEnded(_ touches: Set<UITouch>) {
    guard mode == .existing else { return }
    super.touchesBegan(touches)
  }

  /// Overridden to be a noop when `mode != .existing`.
  override func touchesMoved(_ touches: Set<UITouch>) {
    guard mode == .existing else { return }
    super.touchesMoved(touches)
  }

  /// Overridden to be a noop when `mode != .existing`.
  override func touchesCancelled(_ touches: Set<UITouch>) {
    guard mode == .existing else { return }
    super.touchesCancelled(touches)
  }

}

/// `UIViewController` subclass providing an interface for configuring a generator.
final class GeneratorViewController: UIViewController, SecondaryContent {

  /// Returns a new controller instantiated from `Generator.storyboard`. When `mode == .existing`, the
  /// controller's view contains an additional row of controls consisting of left and right arrows
  /// which correspond to the controller's `previousAction` and `nextAction`.
  static func viewController(for mode: GeneratorTool.Mode) -> GeneratorViewController {

    let storyboard = UIStoryboard(name: "Generator", bundle: nil)
    let identifier = mode == .new ? "Generator" : "GeneratorWithArrows"
    let controller = storyboard .instantiateViewController(withIdentifier: identifier)

    return controller as! GeneratorViewController

  }

  /// The action to perform when the right arrow button is pressed.
  var nextAction: (() -> Void)? = nil

  /// The action to perform when the left arrow button is pressed.
  var previousAction: (() -> Void)? = nil

  /// Actions supported by the controller. The default is to support the `cancel` and `confirm` actions.
  var supportedActions: SecondaryControllerContainer.SupportedActions = [.cancel, .confirm]

  /// The supported actions which are currently disabled but still visible. The default is `none`.
  var disabledActions: SecondaryControllerContainer.SupportedActions = .none

  /// Control for selecting the generator's pitch.
  @IBOutlet weak var pitchSelector: PitchSelector!

  /// Control for selecting the generator's octave.
  @IBOutlet weak var octaveSelector: OctaveSelector!

  /// Control for selecting the generator's duration.
  @IBOutlet weak var durationSelector: DurationSelector!

  /// Control for selecting the generator's velocity.
  @IBOutlet weak var velocitySelector: VelocitySelector!

  /// Control for selecting the generator's pitch modifier.
  @IBOutlet weak var modifierSelector: PitchModifierSelector!

  /// Control for selecting the generator's chord.
  @IBOutlet weak var chordSelector: ChordSelector!

  /// Handler invoked whenever a change is made to `generator` unless the change is made 
  /// via `loadGenerator(:)`.
  var didChangeGenerator: ((AnyMIDIGenerator) -> Void)?


  /// Flag indicating whether `generator` is being updated via `loadGenerator(:)`.
  private var isLoading = false

  /// Replaces `self.generator` with `generator`. Before the assignment, `isLoading` is set to `true`; and,
  /// after assignment `isLoading` is set to `false`.
  func loadGenerator(_ generator: AnyMIDIGenerator) {
    isLoading = true
    self.generator = generator
    isLoading = false
  }

  /// The configured generator. Modifying this property triggers invocation of `didChangeGenerator` unless
  /// `isLoading == true`.
  private(set) var generator = AnyMIDIGenerator() {
    didSet {
      guard !isLoading else { return }
      didChangeGenerator?(generator)
    }
  }

  /// Updates `generator` with the selected pitch.
  @IBAction
  func didSelectPitch() {
    generator.root.natural = Natural.allCases[pitchSelector.selection]
  }

  /// Updates `generator` with the selected octave.
  @IBAction
  func didSelectOctave() {
    generator.octave = Octave.allCases[octaveSelector.selection]
  }

  /// Updates `generator` with the selected pitch modifier.
  @IBAction
  func didSelectModifier() {
    switch modifierSelector.selection {
      case 0:  generator.root.modifier = .flat
      case 2:  generator.root.modifier = .sharp
      default: generator.root.modifier = nil
    }
  }

  /// Updates `generator` with the selected chord.
  @IBAction
  func didSelectChord() {

    switch generator {

      case let .note(generator) where chordSelector.selection > 0:
        let standardPattern = Chord.Pattern.Standard(index: chordSelector.selection - 1)
        let chordPattern = Chord.Pattern(standardPattern)
        self.generator = .chord(ChordGenerator(pattern: chordPattern, generator: generator))

      case var .chord(generator) where chordSelector.selection > 0:
        let standardPattern = Chord.Pattern.Standard(index: chordSelector.selection - 1)
        generator.chord.pattern = Chord.Pattern(standardPattern)
        self.generator = AnyMIDIGenerator(generator)

      case let .chord(generator):
        self.generator = .note(NoteGenerator(generator: generator))

      default:
        break
    }
    
  }

  /// Updates `generator` with the selected note duration.
  @IBAction
  func didSelectDuration() {
    generator.duration = Duration.allCases[durationSelector.selection]
  }

  /// Updates `generator` with the selected note velocity.
  @IBAction
  func didSelectVelocity() {
    generator.velocity = Velocity.allCases[velocitySelector.selection]
  }

  /// Overridden to update controls with current values from `generator`.
  override func viewDidAppear(_ animated: Bool) {

    super.viewDidAppear(animated)

    pitchSelector.selection = generator.root.natural.index

    switch generator.root.modifier {
      case (.flat)?:  modifierSelector.selection = 0
      case (.sharp)?: modifierSelector.selection = 2
      default:        modifierSelector.selection = 1
    }

    octaveSelector.selection   = generator.octave.index
    durationSelector.selection = generator.duration.index
    velocitySelector.selection = generator.velocity.index

    switch generator {
      case .note:                 chordSelector.selection = 0
      case .chord(let generator): chordSelector.selection = generator.chord.pattern.standardIndex ?? 0
    }

  }
  
 }

