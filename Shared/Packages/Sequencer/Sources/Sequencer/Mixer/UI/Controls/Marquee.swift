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

// TODO: Reimplement using `AnyView` to solve double label problem.
/// A view for displaying a piece of text, scrolling once if the
/// text is too long to fit in its entirety.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct Marquee: View
{
  /// The track whose name is being displayed by the marquee.
  @EnvironmentObject var track: InstrumentTrack

  /// The width necessary to display `text` in its entirety.
  @State private var fullWidth: CGFloat = 0

  /// The horizontal offset for `text`.
  @State private var textOffset: CGFloat = 0

  @State private var isEditing = false

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

  /// The text to display for the marquee.
  private func text(width: CGFloat) -> AnyView
  {
    if isEditing
    {
      return AnyView(
        TextField("Track Name",
                  text: $track.displayName,
                  onEditingChanged: { self.isEditing = $0 },
                  onCommit:
                  {
                    logi("<\(#fileID) \(#function)> renamed track to \(track.name)")
                  })
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
      )
    }
    else
    {
      if width <= Marquee.safeWidth
      {
        return AnyView(Text(track.displayName))
      }
      else
      {
        return AnyView(HStack { Text(track.displayName); Text(track.displayName) })
      }
    }
  }

  /// The view's body is composed of a simple piece of text.
  var body: some View
  {
    text(width: calculateWidth())
      .busLabel()
      .fixedSize()
      .offset(x: textOffset, y: 0)
      .frame(width: Marquee.fixedWidth,
             height: Marquee.fixedHeight,
             alignment: .leading)
      .clipped(antialiased: true)
      .onTapGesture { self.isEditing = true }
      .onAppear
      {
        [self] in
        let fullWidth = calculateWidth()
        if fullWidth <= Marquee.safeWidth
        {
          textOffset = Marquee.fixedWidth * 0.5 - fullWidth * 0.5
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
    textStorage.mutableString.setString(track.displayName)

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
    let range = manager.glyphRange(
      forCharacterRange: NSRange(0 ..< track.displayName.count),
      actualCharacterRange: nil
    )
    manager.ensureLayout(forGlyphRange: range)

    return manager.boundingRect(forGlyphRange: range, in: container).width
  }
}
