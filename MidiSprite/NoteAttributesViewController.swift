//
//  NoteAttributesViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/17/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class NoteAttributesViewController: UIViewController {

  @IBOutlet weak var notePicker:     InlinePickerView!
  @IBOutlet weak var durationPicker: InlinePickerView!
  @IBOutlet weak var velocityPicker: InlinePickerView!

  typealias Note     = NoteAttributes.Note
  typealias Duration = NoteAttributes.Duration
  typealias Velocity = NoteAttributes.Velocity

  override func updateViewConstraints() {
    logDebug(view.constraints.map({$0.description}).joinWithSeparator("\n"), asynchronous: false)
    super.updateViewConstraints()
  }

  /** didPickNote */
  @IBAction func didPickNote() { Sequencer.currentNoteAttributes.note = Note.allCases[notePicker.selection] }

  /** didPickDuration */
  @IBAction func didPickDuration() { Sequencer.currentNoteAttributes.duration = Duration.allCases[durationPicker.selection] }

  /** didPickVelocity */
  @IBAction func didPickVelocity() { Sequencer.currentNoteAttributes.velocity = Velocity.allCases[velocityPicker.selection] }

  /** auditionValues */
  @IBAction func auditionValues() { Sequencer.auditionCurrentNote() }
  
  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    notePicker.selection = Sequencer.currentNoteAttributes.note.index
    durationPicker.selection = Sequencer.currentNoteAttributes.duration.index
    velocityPicker.selection = Sequencer.currentNoteAttributes.velocity.index
    logDebug(view.constraints.map({$0.description}).joinWithSeparator("\n"), asynchronous: false)
  }
 }
