//
//  InstrumentViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/19/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Common
import MIDI
import MoonKit
import SoundFont
import UIKit

/// A `UIViewController` subclass for presenting an interface with controls for
/// selecting a sound font, a program within the selected sound font, and a MIDI channel.
public final class InstrumentViewController: UIViewController, SecondaryContent
{
  /// The control for selecting a sound font.
  @IBOutlet public var soundFontSelector: SoundFontSelector!

  /// The control for selecting a program within the selected sound font.
  @IBOutlet public var programSelector: ProgramSelector!

  /// The control for selecting a MIDI channel.
  @IBOutlet public var channelStepper: LabeledStepper!

  /// Action invoked by `soundFontSelector`. This method updates the program selector
  /// and plays a note through `instrument` to demonstrate the current configuration.
  @IBAction public func didSelectSoundFont()
  {
    // Check that there is an instrument to update.
    guard let instrument = instrument else { return }

    // Get the selected sound font.
    let soundFont = SoundFont.bundledFonts[soundFontSelector.selection]

    // Create a preset specifying the selected sound font's first program.
    let preset = Instrument.Preset(soundFont: soundFont,
                                   presetHeader: soundFont[0],
                                   channel: 0)

    do
    {
      // Load the preset into the instrument.
      try instrument.load(preset: preset)

      // Set the program selector's selection to the index of `preset`.
      programSelector.selection = 0

      // Update the program selector's reference to the sound font from which
      // its list of programs is derived.
      programSelector.soundFont = soundFont

      // Play a note through the instrument to allow the user a chance to hear
      // the current configuration.
      instrument.playNote(AnyGenerator())
    }
    catch
    {
      // Just log the error.
      loge("\(error as NSObject)")
    }
  }

  /// Callback invoked when a program is selected. Plays a note through
  /// `instrument` to demonstrate the current configuration.
  @IBAction public func didSelectProgram()
  {
    // Check that there is an instrument.
    guard let instrument = instrument else { return }

    // Create a preset for the current configuration.
    let preset = Instrument.Preset(
      soundFont: instrument.soundFont,
      presetHeader: instrument.soundFont[programSelector.selection],
      channel: UInt8(channelStepper.value)
    )

    do
    {
      // Load `preset` into the instrument.
      try instrument.load(preset: preset)

      // Play a note through the instrument to allow the user a chance to hear the
      // current configuration.
      instrument.playNote(AnyGenerator())
    }
    catch
    {
      // Just log the error.
      loge("\(error as NSObject)")
    }
  }

  /// Callback invoked when a channel is selected. Updates the MIDI channel used
  /// by `instrument`.
  @IBAction public func didChangeChannel()
  {
    // Set instrument's channel using the stepper's value.
    instrument?.channel = UInt8(channelStepper.value)
  }

  /// Returns `instrument` to its initial state by reloading the preset it began with.
  func rollBackInstrument()
  {
    // Check the instrument and the intial preset.
    guard let instrument = instrument,
          let initialPreset = initialPreset
    else
    {
      return
    }

    // Load the initial preset into the to instrument.
    do { try instrument.load(preset: initialPreset) }
    catch { loge("\(error as NSObject)") }
  }

  /// The preset property value of `instrument` at the time `instrument` was set.
  private(set) var initialPreset: Instrument.Preset?

  /// Instrument used by the controller to provide feedback for sound font and
  /// program changes. Setting the value of this property to a value other than
  /// `nil` causes `initialPreset` to be updated with the new instrument's preset,
  /// the sound font selector to select the preset's sound font, the program
  /// selector to select the preset's program, and the channel stepper to update
  /// with the new instrument's MIDI channel.
  public weak var instrument: Instrument?
  {
    didSet
    {
      // Check that there is an instrument, that the view is loaded, and that indexes
      // may be retrieved for the sound font and the program.
      guard let instrument = instrument,
            let soundFontIndex = SoundFont.bundledFonts
              .firstIndex(where: { instrument.soundFont.isEqualTo($0) }),
            let programIndex = instrument.soundFont.presetHeaders
              .firstIndex(of: instrument.preset.presetHeader),
            isViewLoaded
      else
      {
        return
      }

      // Intialize `initialPreset` with the instrument's preset.
      initialPreset = instrument.preset

      // Select the sound font currently used by the instrument.
      soundFontSelector.selectItem(soundFontIndex, animated: true)

      // Update the program selector with the selected sound font.
      programSelector.soundFont = instrument.soundFont

      // Select the program currently used by the instrument.
      programSelector.selectItem(programIndex, animated: true)

      // Update the channel stepper with the MIDI channel currently used by the instrument.
      channelStepper.value = Double(instrument.channel)
    }
  }

  /// Overridden to update the interface unless `Sequencer` has not initialized.
  override public func viewDidLoad()
  {
    super.viewDidLoad()

    // Update the interface.
    soundFontSelector.refreshItems()
  }
}
