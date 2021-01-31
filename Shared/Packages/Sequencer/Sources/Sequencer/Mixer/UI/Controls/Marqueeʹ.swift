//
//  Marqueeʹ.swift
//
//
//  Created by Jason Cardwell on 1/24/21.
//
import Common
import MoonDev
import SwiftUI

// MARK: - Marqueeʹ

// TODO: Reimplement using `AnyView` to solve double label problem.
/// A view for displaying a piece of text, scrolling once if the
/// text is too long to fit in its entirety.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct Marqueeʹ: View
{
  /// The bus for which this Marqueeʹ serves as a control.
  @EnvironmentObject var bus: Bus

  /// Flag used to trigger marquee scroll animation.
  @State private var alignment: TextAlignment = .leading

  /// Flag controlling whether the marquee text is editable.
  @State private var isEditable = false

  /// Flag indicating whether the marquee text is actively being edited.
  @State private var isEditing = false

  /// Flag indicating whether scrolling should be continuous when enabled.
  @State private var everScroll = false

  /// Flag used to receive animation feedback.
  @State private var didScroll = false
  {
    didSet { if didScroll && !everScroll { isEditable = true } }
  }

  private func text(_ proxy: GeometryProxy) -> AnyView
  {
    isEditable
      ? AnyView(
        TextField("Track Name",
                  text: bus.displayName,
                  onEditingChanged: { self.isEditing = $0 },
                  onCommit:
                  {
                    logi("""
                    <\(#fileID) \(#function)> \
                    renamed track to \(bus.displayName.wrappedValue)
                    """)
                  })
          .multilineTextAlignment(.center)
          .autocapitalization(.none)
          .disableAutocorrection(true)
      )
      : AnyView(
        Text(bus.displayName.wrappedValue)
          .marquee(
            text: bus.displayName.wrappedValue,
            size: proxy.size,
            alignment: alignment,
            didScroll: $didScroll
          )
          .animation(Animation.linear.speed(0.125).repeatCount(everScroll ? .max : 0,
                                                               autoreverses: false))
          .onAppear { alignment = .trailing }
      )
  }

  /// The view's body is composed of a simple piece of text.
  var body: some View
  {
    GeometryReader
    {
      proxy in

      text(proxy)
        .busLabel()
        .fixedSize(horizontal: true, vertical: false)
        .frame(width: proxy.size.width)
    }
    .frame(width: 80, height: 20, alignment: .center)
    .onChange(of: didScroll) { if $0 && !everScroll { isEditable = true } }
    .clipped(antialiased: true)
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
                           alignment: TextAlignment,
                           didScroll: Binding<Bool>) -> some View
  {
    marquee(
      text: text,
      size: size,
      alignment: alignment == .leading ? 0 : 1,
      didScroll: didScroll
    )
  }

  fileprivate func marquee(text: String,
                           size: CGSize,
                           alignment: CGFloat,
                           didScroll: Binding<Bool>) -> some View
  {
    modifier(MarqueeEffect(text: text,
                           size: size,
                           alignment: alignment,
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

  /// The progressive alignment for the marquee text.
  /// This is the effect's `animatableData`. The value of this property
  /// represents the current scroll location of the marquee text as expressed
  /// by a value in the range of `0 ... 1`.
  var alignment: CGFloat

  /// A Binding to allow feedback from the animation.
  @Binding var didScroll: Bool

  /// Initializing with text, size, and alignment.
  /// - Parameters:
  ///   - text: The current value being displayed by the marquee.
  ///   - size: The size of the marquee's bounding frame.
  ///   - alignment: The scroll alignment expressed as a value in the range of `0 ... 1`.
  init(text: String, size: CGSize, alignment: CGFloat, didScroll: Binding<Bool>)
  {
    required = text.requiredWidth // Capture the required width for the displayed text.
    useable = size.width - marginOfError // Calculate a safe cutoff width.
    𝝙 = useable < required // Initialize 𝝙 dependent on whether `text` fits in `size`.
      ? (required - useable) + marginOfError // Requires scrolling.
      : 0 // All the text fits. No scrolling.

    self.alignment = alignment // Store the specified alignment.
    _didScroll = didScroll
  }

  /// The animatableData simply wraps `alignment`.
  var animatableData: CGFloat
  {
    get { alignment }
    set { alignment = newValue }
  }

  /// Calculates the marquee effect transform for a given size.
  /// - Parameter size: The size of the marquee text's bounding frame.
  /// - Returns: The calculated transform given `size`.
  func effectValue(size: CGSize) -> ProjectionTransform
  {
    // Send feedback if this is the end of an animation loop.
    if alignment == 1 { DispatchQueue.main.async { self.didScroll = true } }

    // Ensure the text requires scrolling; otherwise, return the identity transform.
    guard 𝝙 != 0 else { return ProjectionTransform() }

    let offset: CGFloat // Declare a variable for the calculated offset.

    switch alignment
    {
      case ..<0.5:
        // The marquee text is in the process of sliding off the left edge.

        let alignmentʹ = alignment / 0.5
        let alignment0 = 𝝙
        let alignment1 = -required - 𝝙 - marginOfError
        let total = alignment0 - alignment1
        let covered = -alignmentʹ * total
        offset = alignment0 + covered

      default /* case 0.5... */:
        // The marquee text is in the process of sliding in from the right edge.

        let alignmentʹ = (alignment - 0.5) / 0.5
        let alignment0 = 𝝙 + useable + marginOfError
        let alignment1 = 𝝙
        let total = alignment0 - alignment1
        let covered = -alignmentʹ * total
        offset = alignment0 + covered
    }

    return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
  }

  /// Safe zone padding used to ensure no characters are clipped.
  private let marginOfError: CGFloat = 5
}
