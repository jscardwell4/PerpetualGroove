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

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct Marquee: View
{
  /// The text being displayed by the marquee.
  @Binding var text: String

  /// The width necessary to display `text` in its entirety.
  @State private var fullWidth: CGFloat = 0

  /// The horizontal offset for `text`.
  @State private var textOffset: CGFloat = 0

  /// The alignment used when framing `text`.
  @State private var frameAlignment: Alignment = .center

  /// The hardcoded marquee width.
  private static let fixedWidth: CGFloat = 80

  /// The hardcoded marquee height.
  private static let fixedHeight: CGFloat = 20

  /// The allowable width before animation kicks in.
  private static let safeWidth: CGFloat = 70

  /// Whether the entirety of `text` is visible without animation.
  private var isStatic: Bool { frameAlignment == .center }

  /// The animation used for scrolling the marquee.
  private var animation: Animation?
  {
    isStatic
      ? nil
      : Animation.default.repeatForever(autoreverses: true).speed(0.125)
  }

  /// The view's body is composed of a simple piece of text.
  var body: some View
  {
    MarqueeText(text: text)
      .fixedSize()
      .offset(x: textOffset, y: 0)
      .frame(width: Marquee.fixedWidth,
             height: Marquee.fixedHeight,
             alignment: .leading)
      .clipped(antialiased: true)
      .onAppear
      {
        [self] in
        let fullWidth = calculateWidth()
        if fullWidth <= Marquee.safeWidth
        {
          textOffset = (Marquee.fixedWidth - fullWidth) / 2
        }
        else
        {
          withAnimation(Animation.default.speed(0.125))
          {
            textOffset = -(fullWidth + 20)
          }
        }
      }
  }

  /// Calculates the width required to display `text` in its entirety.
  /// - Returns: The required width.
  private func calculateWidth() -> CGFloat
  {
    let textStorage = NSTextStorage()
    let font = UIFont(name: "Triump-Rg-Rock-02", size: 14)!
    textStorage.addAttribute(.font, value: font, range: NSRange())
    textStorage.mutableString.setString(text)

    // Create a container to define how the text will be laid out.
    let container = NSTextContainer()
    container.lineBreakMode = .byCharWrapping
    container.lineFragmentPadding = 0
    container.maximumNumberOfLines = 1

    // Set the text container with the view's height and unlimited width
    container.size = CGSize(width: .greatestFiniteMagnitude, height: Marquee.fixedHeight)

    let manager = NSLayoutManager()
    manager.usesFontLeading = false
    manager.addTextContainer(container)
    textStorage.addLayoutManager(manager)

    // Get the glyph range and the bounding rect for laying out all the glyphs
    let range = manager.glyphRange(forCharacterRange: NSRange(0 ..< text.count),
                                   actualCharacterRange: nil)
    manager.ensureLayout(forGlyphRange: range)

    return manager.boundingRect(forGlyphRange: range, in: container).width
  }

  struct MarqueeText: View
  {
    let text: String

    var body: some View
    {
      HStack
      {
        Text(text)
        Text(text)
      }
      .busLabel()
    }
  }
}

// MARK: - Marquee_Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct Marquee_Previews: PreviewProvider
{
  static var previews: some View
  {
    Marquee(text: .constant("Bus 1"))
      .previewDisplayName("Short Name")
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .border(Color.white, width: 1)
      .padding()
    Marquee(text: .constant("73 Wide Rhodes"))
      .previewDisplayName("Long Name")
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .border(Color.white, width: 1)
      .padding()
    Marquee.MarqueeText(text: "73 Wide Rhodes")
      .previewDisplayName("Double Text")
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .border(Color.white, width: 1)
      .padding()
  }
}
