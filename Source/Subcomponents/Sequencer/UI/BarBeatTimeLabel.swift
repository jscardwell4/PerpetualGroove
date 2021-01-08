//
//  BarBeatTimeLabel.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 9/18/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit
import UIKit
import MIDI
import Combine

/// A view for displaying a transport's bar beat time.
@IBDesignable
final class BarBeatTimeLabel: UIView {

  /// An enumeration of the segments from which the bar beat time display is composed.
  private enum Component {

    /// The number of bars.
    case bar

    /// The character separating the number of bars and the number of beats.
    case barBeatDivider

    /// The number of beats.
    case beat

    /// The character separating the number of beats and the number of subbeats.
    case beatSubbeatDivider

    /// The number of subbeats.
    case subbeat

    /// The width used for each character when drawing components.
    static let characterWidth: CGFloat = 26

    /// The height used for each character when drawing components.
    static let characterHeight: CGFloat = 43

    /// The total number of characters when displaying all components.
    static let combinedCount: CGFloat = 9

    /// The combined size of all the components.
    static let combinedSize = CGSize(width: characterWidth * combinedCount, height: characterHeight)

    /// Returns a transform that translates a
    static func originTransform(for bounds: CGRect) -> CGAffineTransform {

      // Calculate the width and height deltas.
      let (𝝙width, 𝝙height) = *(bounds.size - combinedSize)

      // Return a transform that translates x by the width delta and translates y by the height delta.
      return CGAffineTransform(translationX: 𝝙width, y: 𝝙height)
    }

    /// The union of all the elements in `frames`.
    var frame: CGRect { return frames.reduce(.zero) { $0.union($1) } }

    /// A collection of frames for each of the component's characters.
    var frames: [CGRect] {

      switch self {

        case .bar:
          return [
            CGRect(x: 0, y: 0, width: 26, height: 43),
            CGRect(x: 26, y: 0, width: 26, height: 43),
            CGRect(x: 52, y: 0, width: 26, height: 43)
          ]

        case .barBeatDivider:
          return [CGRect(x: 78, y: 0, width: 26, height: 43)]

        case .beat:
          return [CGRect(x: 104, y: 0, width: 26, height: 43)]

        case .beatSubbeatDivider:
          return [CGRect(x: 130, y: 0, width: 26, height: 43)]

        case .subbeat:
          return [
            CGRect(x: 156, y: 0, width: 26, height: 43),
            CGRect(x: 182, y: 0, width: 26, height: 43),
            CGRect(x: 208, y: 0, width: 26, height: 43)
          ]

      }

    }

    /// The dictionary of attributes used to draw a component's text.
    static let characterAttributes: [NSAttributedString.Key:Any] = [
      .font: UIFont.largeDisplayFont,
      .foregroundColor: UIColor.primaryColor,
      .paragraphStyle: NSParagraphStyle.paragraphStyleWithAttributes(alignment: .center)
    ]

    /// Returns an array of all component's whose frame intersects `rect`.
    static func components(for rect: CGRect) -> [Component] {

      return [.bar, .barBeatDivider, .beat, .beatSubbeatDivider, .subbeat].filter {
        $0.frames.first(where: {$0.intersects(rect)}) != nil
      }

    }

    /// Draws the component using the current graphics context.
    /// - Parameter time: The bar beat time from which the component's text is derived.
    func draw(_ time: BarBeatTime) {

      // Create a variable to hold the characters composing the component's text.
      let characters: String

      // Initialize `characters` with text for the component derived from `time`.
      switch self {

        case .bar:
          // Return the number of bars in `time` adding 1 to the zero-based value and padding with
          // leading zeros until the string contains 3 characters.

          characters = String(time.bar + 1, radix: 10, minCount: 3)

        case .barBeatDivider:
          // Always return the character used to divide the number of bars and the number of beats.

          characters = ":"

        case .beat:
          // Return the number of beats in `time` adding 1 to the zero-based value.

          characters = String(time.beat + 1)

        case .beatSubbeatDivider:
          // Always return the character used to divide the number of beats and the number of subbeats.

          characters = "."

        case .subbeat:
          // Return the number of subbeats in `time` adding 1 to the zero-based value and padding with
          // leading zeros until the string contains 3 characters.

          characters = String(time.subbeat + 1, radix: 10, minCount: 3)

      }

      // Iterate the component's characters and frames.
      for (character, frame) in zip(characters, frames) {

        // Draw the character in the frame.
        String(character).draw(in: frame, withAttributes: Component.characterAttributes)

      }

    }

  }

  /// The transport whose bar beat time is being displayed by the label. Changing the value of this
  /// property cause notification registrations for the old value to be removed and notification
  /// registrations for the new value to be added. In addition, the current time displayed by the label
  /// is updated with the new value's time unless the new value is `nil`.
  private weak var transport: Transport! {

    didSet {

      // Check that the value has actually changed.
      guard transport !== oldValue else { return }

      // Set the current time to the transport's time.
      currentTime = transport.time.barBeatTime

      // Get the old transport if it existed.
      if let oldTransport = oldValue {

        // Remove the predicated callback from the old transport.
        oldTransport.time.removePredicatedCallback(with: callbackIdentifier)

        // Remove all remaining registrations for the old transport.
        receptionist.stopObserving(object: oldValue)
      }

      // Check that the new value is not `nil`.
      guard let transport = transport else { return }

      assert(transport.time.callbackRegistered(with: callbackIdentifier) == false)

      // Register the predicated callback with the new transport.
      transport.time.register(callback: weakCapture(of: self, block:BarBeatTimeLabel.didUpdateTime),
                              predicate: {_ in true},
                              identifier: callbackIdentifier)

      // Register for reset and jogging-related notifications from the new transport.
      receptionist.observe(name: .didBeginJogging, from: transport,
                           callback: weakCapture(of: self, block:BarBeatTimeLabel.didBeginJogging))

      receptionist.observe(name: .didEndJogging, from: transport,
                           callback: weakCapture(of: self, block:BarBeatTimeLabel.didEndJogging))

      receptionist.observe(name: .didJog, from: transport,
                           callback: weakCapture(of: self, block:BarBeatTimeLabel.didJog))

      receptionist.observe(name: .didReset, from: transport,
                           callback: weakCapture(of: self, block:BarBeatTimeLabel.didReset))

    }

  }

  /// Flag indicating whether the label's transport is currently being jogged.
  private var isJogging = false

  /// Overridden to perform custom drawing for each component visible within `rect` with content derived
  /// from the label's current bar beat time.
  override func draw(_ rect: CGRect) {

    // Get the graphics  context.
    guard let context = UIGraphicsGetCurrentContext() else { return }

    // Push the context to preserve its original state.
    UIGraphicsPushContext(context)

    // Get the transform for centering the components within `rect`.
    let transform = Component.originTransform(for: rect)

    // Get the components visible in `rect`.
    let components = Component.components(for: rect.applying(transform))

    // Apply the centering transform to the context by concatenating with the context's current transform.
    context.concatenate(transform)

    // Draw each visible component.
    for component in components {

      // Draw the component with the current time.
      component.draw(currentTime)

    }

    // Return the graphics context to its original state.
    UIGraphicsPopContext()

  }

  /// Refreshes the portion of the label corresponding to `component`.
  private func refresh(component: Component) {

    // Get the inversion of the transform used to center drawn components.
    let transform = Component.originTransform(for: bounds).inverted()

    // Get the component's frame with inverted transform applied.
    let rect = component.frame.applying(transform)

    // Mark the calculated rectangle as dirty.
    setNeedsDisplay(rect)

  }

  /// Refreshes the label's components whose displayed content have changed given the specified times.
  /// - Parameter time: The new bar beat time that will be displayed by the label's components.
  /// - Parameter oldTime: The bar beat time last used in deriving the displayed content for components.
  private func refresh(for time: BarBeatTime, oldTime: BarBeatTime) {

    // Create an array for accumulating components that need to be refreshed.
    var components: [Component] = []

    // Append the bar component if the two bar values are not equal.
    if time.bar != oldTime.bar { components.append(.bar) }

    // Append the beat component if the two beat values are not equal.
    if time.beat != oldTime.beat { components.append(.beat) }

    // Append the subbeat component if the two subbeat values are not equal.
    if time.subbeat != oldTime.subbeat { components.append(.subbeat) }

    // Check that at least one component needs refreshing.
    guard components.count > 0 else { return }

    // Dispatch a closure refreshing each component on the main queue.
    dispatchToMain {
      [unowned self] in

      // Iterate the components needing to be refreshed.
      for component in components {

        // Refresh the component.
        self.refresh(component: component)

      }

    }

  }

  /// The bar beat time being displayed by the label. Changing the value of this property causes the
  /// label to mark as dirty the frame of each of the label's components whose content has changed.
  private var currentTime: BarBeatTime = .zero {

    didSet {

      // Check that the value has actually changed.
      guard currentTime != oldValue else { return }

      // Refresh the label's components.
      refresh(for: currentTime, oldTime: oldValue)

    }

  }

  /// The unique identifier used when registering predicated callbacks with `transport`.
  private let callbackIdentifier = UUID()

  /// Handles registration/reception of notifications posted by `transport`.
  private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

  /// Overridden to return size calculated by combining all the label's components.
  override var intrinsicContentSize: CGSize {
    return CGSize(width: Component.characterWidth * Component.combinedCount,
                  height: Component.characterHeight)
  }

  /// Callback registered with `transport.time` to be invoked whenever the bar beat time has changed.
  /// Sets the label's current bar beat time to `newTime`.
  private func didUpdateTime(_ newTime: BarBeatTime) {

    // Update the label's bar beat time with the new value.
    currentTime = newTime

  }

  /// Handler for `didBeginJogging` notifications posted by `transport`. Sets `isJogging` to `true`.
  private func didBeginJogging(_ notification: Notification) {

    // Set the jogging flag.
    isJogging = true

  }

  /// Handler for `didJog` notifications posted by `transport`. Sets the label's current bar beat time
  /// to the jog time attached to `notification`.
  private func didJog(_ notification: Notification) {

    // Get the jog time attached to the notification, double checking that the label's jogging flag is set.
    guard isJogging, let jogTime = notification.jogTime else { return }

    // Update the label's bar beat time with the jog time.
    currentTime = jogTime

  }

  /// Handler for `didEndJogging` notifications posted by `transport`. Sets `isJogging` to `false`.
  private func didEndJogging(_ notification: Notification) {

    // Unset the jogging flag.
    isJogging = false

  }

  /// Handler for `didReset` notifications posted by `transport`. Sets the label's current bar beat time
  /// to the time attached to `notification`.
  private func didReset(_ notification: Notification) {

    // Get the time attached to the notification.
    guard let time = notification.time else { return }

    // Update the label's bar beat time with the attached time.
    currentTime = time

  }

  /// Handler for `didChangeTransport` notifications posted by the sequencer. Sets `transport` to the
  /// sequencer's current transport.
  private func didChangeTransport(_ notification: Notification) {

    // Replace `transport` with the sequencer's current transport.
    transport = Controller.shared.transport

  }

  private var subscription: Cancellable?

  /// Registers to receive `didChangeTransport` notifications from the sequencer and sets `transport` to
  /// the sequencer's current transport. When building for interface builder this method does nothing.
  private func setup() {

    // Check that the build target is not interface builder.
    #if !TARGET_INTERFACE_BUILDER

    // Register to receive notifications from the sequencer when it changes transports.
    subscription = Controller.shared.$transport.sink(receiveValue: { self.transport = $0 })

    // Set `transport` to the sequencer's current transport.
    transport = Controller.shared.transport

    #endif

  }

  /// Overridden to invoke `setup()`.
  override init(frame: CGRect) {

    super.init(frame: frame)

    setup()

  }

  /// Overridden to invoke `setup()`.
  required init?(coder aDecoder: NSCoder) {

    super.init(coder: aDecoder)

    setup()

  }

}
