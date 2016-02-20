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

final class GeneratorTool: NodeSelectionTool, ConfigurableToolType {

  override var active: Bool  {
    didSet {
      logDebug("[\(mode)] oldValue = \(oldValue)  active = \(active)")
      guard active != oldValue && active && mode == .New else { return }
      MIDIPlayer.playerContainer?.presentControllerForTool(self)
    }
  }

  enum Mode { case New, Existing }
  let mode: Mode

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.MIDIFileContext
    return receptionist
  }()


  /**
   initWithPlayerNode:mode:

   - parameter playerNode: MIDIPlayerNode
   - parameter mode: Mode
  */
  init(playerNode: MIDIPlayerNode, mode: Mode) {
    self.mode = mode
    super.init(playerNode: playerNode)
    receptionist.observe(MIDIPlayer.Notification.DidAddNode,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, GeneratorTool.didAddNode))
    receptionist.observe(MIDIPlayer.Notification.DidRemoveNode,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, GeneratorTool.didRemoveNode))

  }

  /**
   didAddNode:

   - parameter notification: NSNotification
  */
  private func didAddNode(notification: NSNotification) {
    guard active && mode == .Existing && player.midiNodes.count == 2 else { return }
    _viewController?.navigationArrows = [.Previous, .Next]
  }

  /**
   didRemoveNode:

   - parameter notification: NSNotification
   */
  private func didRemoveNode(notification: NSNotification) {
    guard active && mode == .Existing && player.midiNodes.count < 2 else { return }
    _viewController?.navigationArrows = [.None]
  }

  /** previousNode */
  private func previousNode() {
    let nodes = player.midiNodes
    guard let node = node, let idx = Array(nodes.generate()).indexOf(node) else { return }
    self.node = idx + 1 < nodes.endIndex ? nodes[idx + 1] : nodes[nodes.startIndex]
  }

  /** nextNode */
  private func nextNode() {
    let nodes = player.midiNodes
    guard let node = node, let idx = Array(nodes.generate()).indexOf(node) else { return }
    self.node = idx - 1 >= nodes.startIndex ? nodes[idx - 1] : nodes[nodes.endIndex - 1]
  }

  var isShowingViewController: Bool { return _viewController != nil }

  /**
   didChangeGenerator:

   - parameter generator: MIDIGenerator
  */
  private func didChangeGenerator(generator: MIDIGenerator) {
    node?.generator = generator
  }

  private weak var _viewController: GeneratorViewController?
  var viewController: SecondaryContentViewController {
    guard _viewController == nil else { return _viewController! }

    let storyboard = UIStoryboard(name: "Generator", bundle: nil)
    let viewController: GeneratorViewController

    switch mode {

      case .Existing:
        guard let node = node else {
          fatalError("cannot show view controller when no node has been chosen")
        }
        viewController = storyboard.instantiateViewControllerWithIdentifier("GeneratorWithArrows")
                           as! GeneratorViewController
        viewController.loadGenerator(node.generator)
        viewController.didChangeGenerator = weakMethod(self, GeneratorTool.didChangeGenerator)
        viewController.previousAction = weakMethod(self, GeneratorTool.previousNode)
        viewController.nextAction = weakMethod(self, GeneratorTool.nextNode)
        //TODO: Add cancel/confirm actions?

      case .New:
        viewController = storyboard.instantiateViewControllerWithIdentifier("Generator")
                           as! GeneratorViewController
        viewController.didChangeGenerator = {
          MIDIPlayer.addTool?.generator = $0
          Sequencer.sequence?.currentTrack?.instrument.playNote($0)
        }

    }

    viewController.navigationArrows = player.midiNodes.count > 1 ? [.Previous, .Next] : [.None]
    return viewController
  }

  /** didShowViewController */
  func didShowViewController(viewController: SecondaryContentViewController) {
    _viewController = viewController as? GeneratorViewController
  }

  /** didHideViewController */
  func didHideViewController(viewController: SecondaryContentViewController) {
    guard active && viewController === _viewController else { return }
    switch mode {
      case .New: if MIDIPlayer.currentTool.toolType === self { MIDIPlayer.currentTool = .None }
      case .Existing: node = nil
    }
  }

  /**
   nodeAtPoint:

   - parameter point: CGPoint

   - returns: [Weak<MIDINode>]
   */
  private func nodeAtPoint(point: CGPoint?) -> MIDINode? {
    guard let point = point where player.containsPoint(point) else { return nil }
    return player.nodesAtPoint(point).flatMap({$0 as? MIDINode}).first
  }


  /**
   touchesBegan:withEvent:

   - parameter touches: Set<UITouch>
   - parameter event: UIEvent?
  */
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard mode == .Existing else { return }
    super.touchesBegan(touches, withEvent: event)
  }

  /** didSelectNode */
  override func didSelectNode() {
    guard active && mode == .Existing && node != nil else { return }
    MIDIPlayer.playerContainer?.presentControllerForTool(self)
  }
}

final class GeneratorViewController: SecondaryContentViewController {

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
    initialGenerator = generator
    self.generator = generator
    loading = false
  }

  private(set) var initialGenerator: MIDIGenerator?

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

