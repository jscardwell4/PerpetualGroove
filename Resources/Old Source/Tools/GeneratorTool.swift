//
//  GeneratorTool.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/2/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Common
import MIDI
import MoonDev
import SpriteKit
import UIKit

// MARK: - GeneratorTool

/// A tool for modifying the generator assigned to new or existing midi nodes.
@available(iOS 14.0, *)
public final class GeneratorTool: PresentingNodeSelectionTool
{
  /// Overridden to trigger secondary content presentation when `active && mode == .new`.
  /// - seealso: `NodeSelectionTool.active`
//  override public var active: Bool
//  {
//    didSet
//    {
//      guard active != oldValue, active, mode == .new else { return }
//      player.playerContainer?.presentContent(for: self, completion: { _ in })
//    }
//  }

  /// Enumeration of the supported modes for which the tool can be configured.
  public enum Mode
  {
    /// The tool is used to configure the generator assigned to new node placements.
    case new

    /// The tool is used to configure the generator assigned to an existing node.
    case existing
  }

  /// Specifies whether the generator is applied to new or existing nodes.
  public let mode: Mode

  /// Initialize with a player node and mode.
  public init(playerNode: PlayerNode, mode: Mode)
  {
    self.mode = mode
    super.init(playerNode: playerNode)
  }

  /// Callback for changes to the secondary content's generator.
  private func didChangeGenerator(_ generator: AnyGenerator)
  {
    // Check that there is a node selected.
    guard let node = node else { return }

    // Register an action for undoing the changes to the node's generator.
    player.undoManager.registerUndo(withTarget: node)
    {
      [initialGenerator = node.generator] node in

      node.generator = initialGenerator

      // Register an action for redoing the changes to the node's generator.
      player.undoManager.registerUndo(withTarget: node) { $0.generator = generator }
    }

    // Actually change the node's generator.
    node.generator = generator
  }

  /// Overridden to return an instance of `GeneratorViewController` configured for `mode`.
  override public var secondaryContent: SecondaryContent
  {
    // Check that there is not already a controller to return.
    guard _secondaryContent == nil else { return _secondaryContent! }

    // Create the controller.
    let secondaryContent = GeneratorViewController.viewController(for: mode)

    switch mode
    {
      case .existing:
        // Configure the controller to modify the generator for an existing node.

        // Check that there is a node selected.
        guard let node = node
        else
        {
          fatalError("cannot show view controller when no node has been selected")
        }

        // Load the node's generator into the controller.
        secondaryContent.loadGenerator(node.generator)

        // Set the change callback to use the tool's method.
        secondaryContent.didChangeGenerator = weakCapture(
          of: self,
          block: GeneratorTool.didChangeGenerator
        )

        // Connect the previous and next actions.
        secondaryContent.previousAction =
          weakCapture(of: self, block: NodeSelectionTool.previousNode)
        secondaryContent.nextAction =
          weakCapture(of: self, block: NodeSelectionTool.nextNode)
        secondaryContent.supportedActions.insert([.previous, .next])

        // Set the disabled actions depending on the number of nodes in the player.
        secondaryContent.disabledActions = playerNode.midiNodes.count > 1
          ? [.none]
          : [.previous, .next]

      // TODO: Add cancel/confirm actions?

      case .new:
        // Configure the controller to modify the generator given to new nodes.

        // Assign a closure for handling generator changes.
        secondaryContent.didChangeGenerator = {
          // Update the add tool's generator with the new generator value.
          player.addTool?.generator = $0

          // Play a note through the instrument of the current track of the current
          // sequence using the new generator.
          sequence?.currentTrack?.instrument.playNote($0)
        }
    }

    return secondaryContent
  }

  /// Overridden to deselect the tool when it is the current tool of `NodePlayer`
  /// and `mode == .new` in addition to actions performed in
  /// `super.didHide(content:dismissalAction:)`.
  override public func didHide(content: SecondaryContent,
                               dismissalAction: DismissalAction)
  {
    // Invoke super.
    super.didHide(content: content, dismissalAction: dismissalAction)

    // Check that the tool is the current tool and `mode == .new`.
    guard player.currentTool.tool === self, mode == .new else { return }

    // Clear the player's current tool.
    player.currentTool = .none
  }

  /// Overridden to be a noop unless `mode == .existing`.
  override public func didSelectNode()
  {
    // Check the tool's mode.
    guard mode == .existing else { return }

    super.didSelectNode()
  }

  /// Overridden to be a noop when `mode != .existing`.
  override public func touchesBegan(_ touches: Set<UITouch>)
  {
    guard mode == .existing else { return }
    super.touchesBegan(touches)
  }

  /// Overridden to be a noop when `mode != .existing`.
  override public func touchesEnded(_ touches: Set<UITouch>)
  {
    guard mode == .existing else { return }
    super.touchesBegan(touches)
  }

  /// Overridden to be a noop when `mode != .existing`.
  override public func touchesMoved(_ touches: Set<UITouch>)
  {
    guard mode == .existing else { return }
    super.touchesMoved(touches)
  }

  /// Overridden to be a noop when `mode != .existing`.
  override public func touchesCancelled(_ touches: Set<UITouch>)
  {
    guard mode == .existing else { return }
    super.touchesCancelled(touches)
  }
}

// MARK: - GeneratorViewController

/// `UIViewController` subclass providing an interface for configuring a generator.
@available(iOS 14.0, *)
final class GeneratorViewController: UIViewController, SecondaryContent
{
  /// Returns a new controller instantiated from `Generator.storyboard`.
  /// When `mode == .existing`, the controller's view contains an additional
  /// row of controls consisting of left and right arrows which correspond
  /// to the controller's `previousAction` and `nextAction`.
  static func viewController(for mode: GeneratorTool.Mode) -> GeneratorViewController
  {
    let storyboard = UIStoryboard(name: "Generator", bundle: nil)
    let identifier = mode == .new ? "Generator" : "GeneratorWithArrows"
    let controller = storyboard.instantiateViewController(withIdentifier: identifier)

    return controller as! GeneratorViewController
  }

  /// The action to perform when the right arrow button is pressed.
  var nextAction: (() -> Void)?

  /// The action to perform when the left arrow button is pressed.
  var previousAction: (() -> Void)?

  /// Actions supported by the controller. The default is to support the `cancel`
  /// and `confirm` actions.
  var supportedActions: SecondaryControllerContainer.SupportedActions = [.cancel, .confirm]

  /// The supported actions which are currently disabled but still visible.
  /// The default is `none`.
  var disabledActions: SecondaryControllerContainer.SupportedActions = .none

  /// Control for selecting the generator's pitch.
//  @IBOutlet var pitchSelector: PitchSelector!

  /// Control for selecting the generator's octave.
//  @IBOutlet var octaveSelector: OctaveSelector!

  /// Control for selecting the generator's duration.
//  @IBOutlet var durationSelector: DurationSelector!

  /// Control for selecting the generator's velocity.
//  @IBOutlet var velocitySelector: VelocitySelector!

  /// Control for selecting the generator's pitch modifier.
//  @IBOutlet var modifierSelector: PitchModifierSelector!

  /// Control for selecting the generator's chord.
//  @IBOutlet var chordSelector: ChordSelector!

  /// Handler invoked whenever a change is made to `generator` unless the change is made
  /// via `loadGenerator(:)`.
  var didChangeGenerator: ((AnyGenerator) -> Void)?

  /// Flag indicating whether `generator` is being updated via `loadGenerator(:)`.
  private var isLoading = false

  /// Replaces `self.generator` with `generator`. Before the assignment, `isLoading`
  /// is set to `true`; and, after assignment `isLoading` is set to `false`.
  func loadGenerator(_ generator: AnyGenerator)
  {
    isLoading = true
    self.generator = generator
    isLoading = false
  }

  /// The configured generator. Modifying this property triggers invocation of
  /// `didChangeGenerator` unless `isLoading == true`.
  private(set) var generator = AnyGenerator()
  {
    didSet
    {
      guard !isLoading else { return }
      didChangeGenerator?(generator)
    }
  }

  /// Updates `generator` with the selected pitch.
  @IBAction
  func didSelectPitch()
  {
//    generator.root.natural = Natural.allCases[pitchSelector.selection]
  }

  /// Updates `generator` with the selected octave.
  @IBAction
  func didSelectOctave()
  {
//    generator.octave = Octave.allCases[octaveSelector.selection]
  }

  /// Updates `generator` with the selected pitch modifier.
  @IBAction
  func didSelectModifier()
  {
//    switch modifierSelector.selection
//    {
//      case 0: generator.root.modifier = .flat
//      case 2: generator.root.modifier = .sharp
//      default: generator.root.modifier = nil
//    }
  }

  /// Updates `generator` with the selected chord.
  @IBAction
  func didSelectChord()
  {
//    switch generator
//    {
//      case let .note(generator) where chordSelector.selection > 0:
//        let standardPattern = Chord.Pattern.Standard(index: chordSelector.selection - 1)
//        let chordPattern = Chord.Pattern(standardPattern)
//        self.generator = .chord(ChordGenerator(pattern: chordPattern,
//                                               generator: generator))
//
//      case var .chord(generator) where chordSelector.selection > 0:
//        let standardPattern = Chord.Pattern.Standard(index: chordSelector.selection - 1)
//        generator.chord.pattern = Chord.Pattern(standardPattern)
//        self.generator = AnyGenerator(generator)
//
//      case let .chord(generator):
//        self.generator = .note(NoteGenerator(generator: generator))
//
//      default:
//        break
//    }
  }

  /// Updates `generator` with the selected note duration.
  @IBAction
  func didSelectDuration()
  {
//    generator.duration = Duration.allCases[durationSelector.selection]
  }

  /// Updates `generator` with the selected note velocity.
  @IBAction
  func didSelectVelocity()
  {
//    generator.velocity = Velocity.allCases[velocitySelector.selection]
  }

  /// Overridden to update controls with current values from `generator`.
//  override func viewDidAppear(_ animated: Bool)
//  {
//    super.viewDidAppear(animated)
//
//    pitchSelector.selection = generator.root.natural.index
//
//    switch generator.root.modifier
//    {
//      case (.flat)?: modifierSelector.selection = 0
//      case (.sharp)?: modifierSelector.selection = 2
//      default: modifierSelector.selection = 1
//    }
//
//    octaveSelector.selection = generator.octave.index
//    durationSelector.selection = generator.duration.index
//    velocitySelector.selection = generator.velocity.index
//
//    switch generator
//    {
//      case .note:
//        chordSelector.selection = 0
//      case let .chord(generator):
//        chordSelector.selection = generator.chord.pattern.standardIndex ?? 0
//    }
//  }
}
