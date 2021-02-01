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

/// A view for displaying a piece of text, scrolling once if the
/// text is too long to fit in its entirety.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct Marquee: View, Identifiable
{
  /// The bus for which this marquee serves as a control.
  @EnvironmentObject var bus: Bus

  @Environment(\.keyboardIsActive) var keyboardIsActive: Bool

  let id = UUID()

  /// Flag used to trigger marquee scroll animation.
  @State private var phase: Phase = .initial

  fileprivate enum Phase: CGFloat { case initial = 0, final = 1 }

  /// Flag indicating whether the marquee text is actively being edited.
  @State private var isEditing = false

  /// Flag for controlling how the marquee text is scrolled.
  @State private var scrollSetting: ScrollSetting = .once

  @State private var didScroll = false

  fileprivate enum ScrollSetting
  {
    case continuous, once, never
    var repeatCount: Int { self == .continuous ? .max : 0 }
  }

  /// The backing store used with the `KeyboardPreferenceKey`.
  @State private var keyboardRequest: KeyboardRequest? = nil

  @State private var suppressAnimation = false

  /// Derived property encapsulating animation logic.
  private var animation: Animation
  {
    Animation.linear.speed(0.125).repeatCount(scrollSetting.repeatCount,
                                              autoreverses: false)
  }

  /// The view's body is composed of a simple piece of text.
  var body: some View
  {
    GeometryReader
    {
      proxy in

      TextField("Track Name", text: bus.displayName)
      {
        [wasEditing = isEditing] isEditing in

        if isEditing ^ wasEditing
        {
          keyboardRequest = isEditing
            ? KeyboardRequest(id: id, frame: proxy.frame(in: .global))
            : nil

          self.isEditing = isEditing
        }
      }
      onCommit: { keyboardRequest = nil }
      .multilineTextAlignment(.center)
      .autocapitalization(.none)
      .disableAutocorrection(true)
      .preference(key: KeyboardPreferenceKey.self,
                  value: [keyboardRequest].compactMap { $0 })
      .marquee(text: bus.displayName.wrappedValue,
               size: proxy.size,
               phase: scrollSetting == .never
                || (scrollSetting == .once && didScroll)
                ? .final
                : phase,
               didScroll: $didScroll)
      .animation(animation)
      .onAppear
      {
        if scrollSetting != .never,
           !(scrollSetting == .once && didScroll)
        {
          phase = .final
        }
      }
      .busLabel(isEditing: isEditing)
      .fixedSize(horizontal: true, vertical: false)
      .frame(width: proxy.size.width)
    }
    .frame(width: 80, height: 20, alignment: .center)
    .clipped(antialiased: true)
    .onChange(of: keyboardIsActive) { suppressAnimation = $0 }
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
  fileprivate func marquee(text: String,
                           size: CGSize,
                           phase: Marquee.Phase,
                           didScroll: Binding<Bool>) -> some View
  {
    marquee(text: text, size: size, phase: phase.rawValue, didScroll: didScroll)
  }

  fileprivate func marquee(text: String,
                           size: CGSize,
                           phase: CGFloat,
                           didScroll: Binding<Bool>) -> some View
  {
    modifier(MarqueeEffect(text: text,
                           size: size,
                           phase: phase,
                           didScroll: didScroll))
  }
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

  /// Initializing with text, size, and alignment.
  /// - Parameters:
  ///   - text: The current value being displayed by the marquee.
  ///   - size: The size of the marquee's bounding frame.
  ///   - phase: The scroll alignment expressed as a value in the range of `0 ... 1`.
  init(text: String, size: CGSize, phase: CGFloat, didScroll: Binding<Bool>)
  {
    required = text.requiredWidth // Capture the required width for the displayed text.
    useable = size.width - marginOfError // Calculate a safe cutoff width.
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
      if newValue == 1, !didScroll { DispatchQueue.main.async {[self] in didScroll = true } }
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
