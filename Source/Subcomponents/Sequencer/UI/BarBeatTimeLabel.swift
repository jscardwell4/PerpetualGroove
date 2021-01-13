//
//  BarBeatTimeLabel.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/18/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Combine
import Foundation
import MIDI
import MoonKit
import UIKit

// MARK: - BarBeatTimeLabel

/// A view for displaying a transport's bar beat time.
final class BarBeatTimeLabel: UIView
{
  // MARK: Stored Properties

  /// Flag indicating whether the label's transport is currently being jogged.
  private var jogging = false

  /// The bar beat time being displayed by the label. Changing the value of this
  /// property causes the label to mark as dirty the frame of each of the label's
  /// components whose content has changed.
  private var currentTime: BarBeatTime = .zero
  {
    didSet
    {
      // Check that the value has actually changed.
      guard currentTime != oldValue else { return }

      // Refresh the label's components.
      refresh(for: currentTime, oldTime: oldValue)
    }
  }

  /// The unique identifier used when registering predicated callbacks with `transport`.
  private let callbackIdentifier = UUID()

  /// Subscription for `didBeginJogging` notifications.
  private var didBeginJoggingSubscription: Cancellable?

  /// Subscription for `didEndJogging` notifications.
  private var didEndJoggingSubscription: Cancellable?

  /// Subscription for `didJog` notifications.
  private var didJogSubscription: Cancellable?

  /// Subscription for `didReset` notifications.
  private var didResetSubscription: Cancellable?

  /// Subscription for the published `controller.transport` property.
  private var transportSubscription: Cancellable?

  /// The transport whose bar beat time is being displayed by the label.
  /// Changing the value of this property cause notification registrations
  /// for the old value to be removed and notification registrations for
  /// the new value to be added. In addition, the current time displayed
  /// by the label is updated with the new value's time unless the new
  /// value is `nil`.
  private weak var transport: Transport?
  {
    willSet
    {
      transport?.time.removePredicatedCallback(with: callbackIdentifier)
      didBeginJoggingSubscription?.cancel()
      didEndJoggingSubscription?.cancel()
      didJogSubscription?.cancel()
      didResetSubscription?.cancel()
    }
    didSet
    {
      // Check that the value has actually changed.
      guard let transport = transport else { return }

      // Register the predicated callback with the new transport.
      assert(transport.time.callbackRegistered(with: callbackIdentifier) == false)
      transport.time.register(callback: { self.currentTime = $0 },
                              predicate: { _ in true },
                              identifier: callbackIdentifier)

      didBeginJoggingSubscription = NotificationCenter.default
        .publisher(for: .transportDidBeginJogging, object: transport)
        .sink { _ in self.jogging = true }

      didEndJoggingSubscription = NotificationCenter.default
        .publisher(for: .transportDidEndJogging, object: transport)
        .sink { _ in self.jogging = false }

      didJogSubscription = NotificationCenter.default
        .publisher(for: .transportDidJog, object: transport)
        .sink
        {
          guard self.jogging, let jogTime = $0.jogTime else { return }
          self.currentTime = jogTime
        }

      didResetSubscription = NotificationCenter.default
        .publisher(for: .transportDidReset, object: transport)
        .sink
        {
          guard let time = $0.time else { return }
          self.currentTime = time
        }

      // Set the current time to the transport's time.
      currentTime = transport.time.barBeatTime
    }
  }

  // MARK: Initializing

  /// Overridden to invoke `setup()`.
  override init(frame: CGRect) { super.init(frame: frame); setup() }

  /// Overridden to invoke `setup()`.
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

  /// Registers to receive `didChangeTransport` notifications from the sequencer
  /// and sets `transport` to the sequencer's current transport. When building
  /// for interface builder this method does nothing.
  private func setup()
  {

    // Register to receive notifications from the sequencer when it changes transports.
    transportSubscription = sequencer.$transport.sink { self.transport = $0 }

    // Set `transport` to the sequencer's current transport.
    transport = sequencer.transport

  }

  // MARK: Computed Properties

  /// Overridden to return size calculated by combining all the label's components.
  override var intrinsicContentSize: CGSize { Component.combinedSize }

  // MARK: Drawing

  /// Overridden to perform custom drawing for each component visible within
  /// `rect` with content derived from the label's current bar beat time.
  override func draw(_ rect: CGRect)
  {
    // Get the graphics  context.
    guard let context = UIGraphicsGetCurrentContext() else { return }

    // Push the context to preserve its original state.
    UIGraphicsPushContext(context)

    // Get the transform for centering the components within `rect`.
    let transform = Component.originTransform(for: rect)

    // Get the components visible in `rect`.
    let components = Component.components(for: rect.applying(transform))

    // Apply the centering transform to the context by concatenating with
    // the context's current transform.
    context.concatenate(transform)

    // Draw each visible component.
    for component in components
    {
      // Draw the component with the current time.
      component.draw(currentTime)
    }

    // Return the graphics context to its original state.
    UIGraphicsPopContext()
  }

  /// Refreshes the portion of the label corresponding to `component`.
  private func refresh(component: Component)
  {
    // Get the inversion of the transform used to center drawn components.
    let transform = Component.originTransform(for: bounds).inverted()

    // Get the component's frame with inverted transform applied.
    let rect = component.frame.applying(transform)

    // Mark the calculated rectangle as dirty.
    setNeedsDisplay(rect)
  }

  /// Refreshes the label's components whose displayed content have changed given
  /// the specified times.
  ///
  /// - Parameters:
  ///   - time: The new bar beat time that will be displayed by the label's components.
  ///   - oldTime: The last time used in deriving the displayed content for components.
  private func refresh(for time: BarBeatTime, oldTime: BarBeatTime)
  {
    // Create an array for accumulating components that need to be refreshed.
    var components: [Component] = []

    // Append the bar component if the two bar values are not equal.
    if time.bar != oldTime.bar { components.append(.bar) }

    // Append the beat component if the two beat values are not equal.
    if time.beat != oldTime.beat { components.append(.beat) }

    // Append the subbeat component if the two subbeat values are not equal.
    if time.subbeat != oldTime.subbeat { components.append(.subbeat) }

    // Check that at least one component needs refreshing.
    guard !components.isEmpty else { return }

    // Dispatch a closure refreshing each component on the main queue.
    dispatchToMain { components.forEach(self.refresh(component:)) }
  }
}

// MARK: - BarBeatTimeLabel.Component

extension BarBeatTimeLabel
{
  /// An enumeration of the segments from which the bar beat time display is composed.
  enum Component
  {
    /// The total number of bars represented.
    case bar

    /// The character separating the bars from the beats.
    case barBeatDivider

    /// The total number of beats represented.
    case beat

    /// The character separating the beats from the subbeats.
    case beatSubbeatDivider

    /// The total number of subbeats represented.
    case subbeat

    /// The width used for each character when drawing components.
    static let characterWidth: CGFloat = 26

    /// The height used for each character when drawing components.
    static let characterHeight: CGFloat = 43

    /// The total number of characters when displaying all components.
    static let characterCount: CGFloat = 9

    /// The combined size of all the components.
    static let combinedSize = CGSize(width: characterWidth * characterCount,
                                     height: characterHeight)

    /// Returns a transform that translates a
    static func originTransform(for bounds: CGRect) -> CGAffineTransform
    {
      // Calculate the width and height deltas.
      let (𝝙width, 𝝙height) = (bounds.size - combinedSize).unpack

      // Return a transform that translates x by the width delta and translates
      // y by the height delta.
      return CGAffineTransform(translationX: 𝝙width, y: 𝝙height)
    }

    /// The union of all the elements in `frames`.
    var frame: CGRect { frames.reduce(.zero) { $0.union($1) } }

    /// A collection of frames for each of the component's characters.
    var frames: [CGRect]
    {
      let width = Component.characterWidth
      let height = Component.characterHeight

      switch self
      {
        case .bar:
          return [
            CGRect(x: width * 0, y: 0, width: width, height: height),
            CGRect(x: width * 1, y: 0, width: width, height: height),
            CGRect(x: width * 2, y: 0, width: width, height: height),
          ]

        case .barBeatDivider:
          return [CGRect(x: width * 3, y: 0, width: width, height: height)]

        case .beat:
          return [CGRect(x: width * 4, y: 0, width: width, height: height)]

        case .beatSubbeatDivider:
          return [CGRect(x: width * 5, y: 0, width: width, height: height)]

        case .subbeat:
          return [
            CGRect(x: width * 6, y: 0, width: width, height: height),
            CGRect(x: width * 7, y: 0, width: width, height: height),
            CGRect(x: width * 8, y: 0, width: width, height: height),
          ]
      }
    }

    /// The dictionary of attributes used to draw a component's text.
    static let characterAttributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.largeDisplayFont,
      .foregroundColor: UIColor.primaryColor1,
      .paragraphStyle: NSParagraphStyle.paragraphStyleWithAttributes(alignment: .center),
    ]

    /// Returns an array of all component's whose frame intersects `rect`.
    static func components(for rect: CGRect) -> [Component]
    {
      [.bar, .barBeatDivider, .beat, .beatSubbeatDivider, .subbeat].filter
      {
        $0.frames.first(where: { $0.intersects(rect) }) != nil
      }
    }

    /// Draws the component using the current graphics context.
    /// - Parameter time: The bar beat time from which the component's text is derived.
    func draw(_ time: BarBeatTime)
    {
      // Create a variable to hold the characters composing the component's text.
      let characters: String

      // Initialize `characters` with text for the component derived from `time`.
      switch self
      {
        case .bar:
          // Return the number of bars in `time` adding 1 to the zero-based value and
          // padding with leading zeros until the string contains 3 characters.

          characters = String(time.bar + 1, radix: 10, minCount: 3)

        case .barBeatDivider:
          // Always return the character used to divide the number of bars and the
          // number of beats.

          characters = ":"

        case .beat:
          // Return the number of beats in `time` adding 1 to the zero-based value.

          characters = String(time.beat + 1)
          
        case .beatSubbeatDivider:
          // Always return the character used to divide the number of beats and the
          // number of subbeats.

          characters = "."

        case .subbeat:
          // Return the number of subbeats in `time` adding 1 to the zero-based value
          // and padding with leading zeros until the string contains 3 characters.

          characters = String(time.subbeat + 1, radix: 10, minCount: 3)
      }

      // Iterate the component's characters and frames.
      for (character, frame) in zip(characters, frames)
      {
        // Draw the character in the frame.
        String(character).draw(in: frame, withAttributes: Component.characterAttributes)
      }
    }
  }
}
