//
//  TransportView.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/10/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import MIDI
import MoonKit
import SwiftUI

// MARK: - TransportView

/// A view for controlling the sequencer's transport.
public struct TransportView: View
{
  /// The indicated recording state of the transport.
  @State private var isRecording: Bool = false

  /// The indicated playback state of the transport.
  @State private var isPlaying: Bool = false

  /// The indicated paused-playback state of the transport.
  @State private var isPaused: Bool = false

  /// The indicated jogging state of the transport.
  @State private var isJogging: Bool = false

  /// The indicated number of beats per minute.
  @State private var tempo: Float = 120

  /// The indicated state of inclusion for the metronome.
  @State private var metronomeIsOn: Bool = false

  /// The current bar beat time being displayed.
  @State private var currentTime: BarBeatTime = 1∶1.124

  /// The image used on the record button.
  private let recordImage = Image("record", bundle: bundle)

  /// The image used on the play/pause button when the clock is stopped or paused.
  private let playImage = Image("play", bundle: bundle)

  /// The image used on the play/pause button when the clock is running.
  private let pauseImage = Image("pause", bundle: bundle)

  /// The image used on the stop button.
  private let stopImage = Image("stop", bundle: bundle)

  /// The image used on the metronome button.
  private let metronomeImage = Image("metronome", bundle: bundle)
    .resizable(resizingMode: .stretch)

  /// Action invoked by the record button.
  private func recordButtonAction()
  {
    isRecording.toggle()
    transport.recording = isRecording
  }

  /// Action invoked by the play/pause button.
  private func playButtonAction()
  {
    isPaused = isPlaying ^ isPaused
    transport.paused = isPaused
    isPlaying = isPlaying ^ isPaused
    transport.playing = isPlaying
  }

  /// Action invoked by the stop button.
  private func stopButtonAction() {
    transport.reset()
  }

  /// Action invoked by the metronome button.
  private func metronomeButtonAction() {
    metronomeIsOn.toggle()
  }

  /// The view's body.
  public var body: some View
  {
    // Fully enclose all the components in a horizontal stack.
    HStack
    {
      // Group together the record, play, and stop buttons.
      Group
      {
        // Create the record button.
        Button(action: recordButtonAction, label: { recordImage })
          .accentColor(isRecording ? .highlightColor : .primaryColor2)

        // Create the play/pause button.
        Button(
          action: playButtonAction,
          label: { isPlaying && !isPaused ? pauseImage : playImage }
        )
        .accentColor(isPlaying && !isPaused ? .primaryColor2 : .primaryColor1)

        // Create the stop button.
        Button(action: stopButtonAction, label: { stopImage })
          .disabled(!isPlaying)
          .accentColor(isPlaying ? .primaryColor1 : .disabledColor)
      }

      // Add space between the group of buttons and the jog wheel.
      Spacer()

      // Add the jog wheel.
      JogWheel()
        .frame(
          width: 150,
          height: 150,
          alignment: /*@START_MENU_TOKEN@*/ .center/*@END_MENU_TOKEN@*/
        )

      // Add space between the jog wheel and the stack to follow.
      Spacer()

      // Create a vertical stack for the remaining controls.
      VStack
      {
        TempoSlider(value: $tempo)
          .frame(
            minWidth: 200,
            idealWidth: 300,
            maxWidth: 400,
            minHeight: 75,
            idealHeight: 75,
            maxHeight: 75,
            alignment: .center
          )
        HStack
        {
          Spacer()

          // Create the metronome button.
          Button(action: metronomeButtonAction, label: {metronomeImage})
            .aspectRatio(contentMode: .fit)
            .frame(width: 44, alignment: .center)
            .accentColor(metronomeIsOn ? .highlightColor : .primaryColor1)

          Spacer()

          // Create the bar beat time display.
          Clock(currentTime: $currentTime)

          Spacer()
        }
      }
      .frame(height: 200, alignment: .center)
    }

    .padding()
  }

  public init(transport: Transport)
  {
    isRecording = transport.recording
    isPlaying = transport.playing
    isPaused = transport.paused
    isJogging = transport.jogging
    tempo = Float(transport.clock.beatsPerMinute)
    metronomeIsOn = metronome.isOn
    currentTime = transport.time.barBeatTime
  }

}

// MARK: - TransportView_Previews

struct TransportView_Previews: PreviewProvider
{

  static var previews: some View
  {
    TransportView(transport: transport)
    .previewLayout(.sizeThatFits)
    .preferredColorScheme(.dark)
  }
}
