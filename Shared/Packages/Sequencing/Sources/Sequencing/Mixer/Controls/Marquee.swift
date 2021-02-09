//
//  Marquee.swift
//
//
//  Created by Jason Cardwell on 1/24/21.
//
import Common
import MoonDev
import SwiftUI

// MARK: - Marquee

/// A view for displaying a piece of text, optionally scrolling if the
/// text is too long to fit without truncating.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct Marquee: View, Identifiable
{
  /// The bus for which this marquee serves as a control.
  @EnvironmentObject var bus: Bus

  /// Indicates whether the software keyboard is active.
  @Environment(\.keyboardIsActive) var keyboardIsActive: Bool

  /// Unique identifier for keyboard requests.
  let id = UUID()

  /// Triggers marquee scroll animations. The value of `phase` is always
  /// within the range of `0 ... 1` with `0` representing the initial
  /// scroll position and `1` representing the `final` scroll position.
  @State private var phase: CGFloat = .initial

  /// Indicates that the marquee text scroll animation should refresh.
  @State private var refreshScroll = false

  /// Controls how the marquee text is scrolled.
  /// Options are continuous, once, or never.
  @State private var scrollSetting: ScrollSetting = .once

  /// Binding passed to an instance of `MarqueeEffect` for animation feedback.
  @State private var didScroll = false

  /// Enumeration of possible scroll settings.
  fileprivate enum ScrollSetting
  {
    /// Scroll continuously when the text warrants.
    case continuous

    /// Scroll once when the text warrants.
    case once

    /// Never animate truncated text.
    case never

    /// The repeat count for the scroll settting's animation.
    var repeatCount: Int { self == .continuous ? .max : 0 }
  }

  /// Indicates whether the marquee text is actively being edited.
  @State private var isEditing = false

  /// Indicates whether the marquee text should be clipped.
  @State private var shouldClip = true

  /// The backing store used with the `KeyboardPreferenceKey`.
  @State private var keyboardRequest: KeyboardRequest? = nil

  @State private var requiredWidth: CGFloat? = nil

  /// Derived property encapsulating animation logic.
  private var animation: Animation?
  {
    // Ensure we are meant to be animating.
    guard !keyboardIsActive, !isEditing,
          !didScroll || scrollSetting == .continuous
    else { return nil }

    DispatchQueue.main.async
    {
      withAnimation(.delayedScroll(setting: scrollSetting)) { self.phase = .final }
    }

    return .scroll(setting: scrollSetting)
  }

  /// The view's body is composed of a simple piece of text.
  var body: some View
  {
      GeometryReader
      {
        proxy in

        TextField("Track Name", text: bus.$displayName)
        {
          [wasEditing = isEditing] isEditing in

          if isEditing ^ wasEditing
          {
            keyboardRequest = isEditing ? KeyboardRequest(id: id, proxy: proxy) : nil
            self.isEditing = isEditing
            shouldClip = !isEditing
            requiredWidth = shouldClip ? bus.displayName.requiredWidth : nil
          }
        }
        .marquee(required: bus.displayName.requiredWidth,
                 proxy: proxy,
                 phase: phase,
                 didScroll: $didScroll)
        .animation(animation)
        .frame(width: proxy.size.width)
        .commonTextField(isEditing: $isEditing)
        .busLabel()
        .preference(key: KeyboardPreferenceKey.self, value: keyboardRequest.asArray)
        .clipped()
      }
      .frame(width: 80, height: 20, alignment: .center)
  }
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension String
{
  /// Calculates the width required to display `text` in its entirety.
  /// - Returns: The required width.
  fileprivate var requiredWidth: CGFloat
  {
    let textStorage = NSTextStorage()
    let font = UIFont(name: "Triump-Rg-Rock-02", size: 14)!
    textStorage.addAttribute(.font, value: font, range: NSRange())
    textStorage.mutableString.setString(self)

    // Create a container to define how the text will be laid out.
    let container = NSTextContainer()
    container.lineBreakMode = .byCharWrapping
    container.lineFragmentPadding = 0
    container.maximumNumberOfLines = 1

    // Set the text container with the view's height and unlimited width
    container.size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 20)

    let manager = NSLayoutManager()
    manager.usesFontLeading = false
    manager.addTextContainer(container)
    textStorage.addLayoutManager(manager)

    // Get the glyph range and the bounding rect for laying out all the glyphs
    let range = manager.glyphRange(
      forCharacterRange: NSRange(0 ..< count),
      actualCharacterRange: nil
    )
    manager.ensureLayout(forGlyphRange: range)

    return manager.boundingRect(forGlyphRange: range, in: container).width
  }
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension View
{
  fileprivate func marquee(required: CGFloat,
                           proxy: GeometryProxy,
                           phase: CGFloat,
                           didScroll: Binding<Bool>) -> some View
  {
    modifier(MarqueeEffect(required: required,
                           proxy: proxy,
                           phase: phase,
                           didScroll: didScroll).ignoredByLayout())
  }
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension Animation
{
  fileprivate static func scroll(setting: Marquee.ScrollSetting) -> Animation?
  {
    setting == .never ? nil : Animation
      .linear
      .speed(0.125)
      .repeatCount(setting.repeatCount, autoreverses: false)
  }

  fileprivate static func delayedScroll(setting: Marquee.ScrollSetting) -> Animation?
  {
    scroll(setting: setting)?.delay(2)
  }
}

extension CGFloat
{
  fileprivate static let initial: CGFloat = 0
  fileprivate static let final: CGFloat = 1
}

// MARK: - MarqueeEffect

/// A geometry effect for the marquee text.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
private struct MarqueeEffect: GeometryEffect
{
  /// The width the marquee text would require to avoid clipping.
  let required: CGFloat

  /// The width available before clipping.
  let useable: CGFloat

  /// The relative difference between `required` and `useable`.
  /// This value takes into account `marginOfError`.
  let 𝝙: CGFloat

  /// The progressive phase for the marquee text.
  /// This is the effect's `animatableData`. The value of this property
  /// represents the current scroll location of the marquee text as expressed
  /// by a value in the range of `0 ... 1`.
  var phase: CGFloat

  @Binding var didScroll: Bool

  init(required: CGFloat, proxy: GeometryProxy, phase: CGFloat, didScroll: Binding<Bool>)
  {
    self.required = required
    useable = proxy.size.width - marginOfError // Calculate a safe cutoff width.
    𝝙 = useable < required // Initialize 𝝙 dependent on whether `text` fits in `size`.
      ? (required - useable) + marginOfError // Requires scrolling.
      : 0 // All the text fits. No scrolling.

    self.phase = phase // Store the specified phase.
    _didScroll = didScroll // Store the feedback binding.
  }

  /// The animatableData simply wraps `phase`.
  var animatableData: CGFloat
  {
    get { phase }
    set
    {
      if newValue == 1,
         !didScroll { DispatchQueue.main.async { [self] in didScroll = true } }
      phase = newValue
    }
  }

  /// Calculates the marquee effect transform for a given size.
  /// - Parameter size: The size of the marquee text's bounding frame.
  /// - Returns: The calculated transform given `size`.
  func effectValue(size: CGSize) -> ProjectionTransform
  {
    // Ensure the text requires scrolling; otherwise, return the identity transform.
    guard 𝝙 != 0 else { return ProjectionTransform() }

    let offset: CGFloat // Declare a variable for the calculated offset.

    switch phase
    {
      case ..<0.5:
        // The marquee text is in the process of sliding off the left edge.

        let phaseʹ = phase / 0.5
        let phase0 = 𝝙
        let phase1 = -required - 𝝙 - marginOfError
        let total = phase0 - phase1
        let covered = -phaseʹ * total
        offset = phase0 + covered

      default /* case 0.5... */:
        // The marquee text is in the process of sliding in from the right edge.

        let phaseʹ = (phase - 0.5) / 0.5
        let phase0 = 𝝙 + useable + marginOfError
        let phase1 = 𝝙
        let total = phase0 - phase1
        let covered = -phaseʹ * total
        offset = phase0 + covered
    }

    return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
  }

  /// Safe zone padding used to ensure no characters are clipped.
  private let marginOfError: CGFloat = 5
}
