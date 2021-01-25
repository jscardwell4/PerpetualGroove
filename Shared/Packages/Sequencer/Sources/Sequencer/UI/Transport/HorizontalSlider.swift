//
//  HorizontalSlider.swift
//
//
//  Created by Jason Cardwell on 1/25/21.
//
import Combine
import func MoonDev.logi
import SwiftUI

// MARK: - HorizontalSlider

/// A horizontal slider control attached to an unsigned integer value
/// clamped to `24 ... 400`.
struct HorizontalSlider: View
{
  /// The slider's value.
  @Binding var value: UInt16

  /// The range of allowable values for `value`.
  static var valueRange: ClosedRange<UInt16> { 24 ... 400 }

  /// Calculates the horizontal offset along the slider track that corresponds with
  /// the specified value.
  /// - Parameters:
  ///   - value: The value for which to calculate an offset.
  ///   - trackWidth: The width of the slider's track.
  /// - Returns: The corresponding offset for `value`.
  private func valueOffset(for trackWidth: CGFloat) -> CGFloat
  {
    (CGFloat(value - HorizontalSlider.valueRange.lowerBound)
      / CGFloat(HorizontalSlider.valueRange.count)) * trackWidth
  }

  /// Calculates the slider value corresponding with a specified offset.
  /// - Parameters:
  ///   - offset: The offset for which to calculate a value.
  ///   - trackWidth: The total width of the slider's track.
  /// - Returns: The corresponding value for `offset`.
  private static func value(for offset: CGFloat, trackWidth: CGFloat) -> UInt16
  {
    min(HorizontalSlider.valueRange.upperBound,
        UInt16(max(0, (offset / trackWidth) * CGFloat(HorizontalSlider.valueRange.count)))
          + HorizontalSlider.valueRange.lowerBound)
  }

  /// The gesture state for the view's drag gesture.
  @GestureState private var dragOffset: CGFloat = 0

  /// Generates the view serving as the slider's thumb button.
  private func thumb(for trackWidth: CGFloat) -> some View
  {
    ZStack
    {
      Text("\(value)")
        .font(Font.custom("EvelethRegular", size: 12))
        .foregroundColor(Color("valueLabelTextColor", bundle: .module))
        .offset(y: -6)
      Image("horizontal_thumb", bundle: .module)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .fixedSize()
        .frame(alignment: .bottom)
        .foregroundColor(Color("thumbColor", bundle: .module))
        .zIndex(1)
        .gesture(DragGesture().updating($dragOffset)
        {
         [self] v, s, _ in
          s = v.translation.width
          value = HorizontalSlider.value(for: valueOffset(for: trackWidth) + s,
                                         trackWidth: trackWidth)
        })
    }
  }

  /// The predetermined width of the slider's track.
  private static let trackHeight: CGFloat = 14

  /// The predetermined size of the slider.
  private static let sliderHeight: CGFloat = 44

  /// `track` colored and sized for the minimum value side of the slider.
  private func minTrack(for trackWidth: CGFloat) -> some View
  {
    track.foregroundColor(Color("trackMinColor", bundle: .module))
      .frame(width: max(0, valueOffset(for: trackWidth) + dragOffset))
  }

  /// `track` colored and sized for the maximum value side of the slider.
  private func maxTrack(for trackWidth: CGFloat) -> some View
  {
    track.foregroundColor(Color("trackMaxColor", bundle: .module))
      .frame(width: max(0, trackWidth - valueOffset(for: trackWidth) - dragOffset))
  }

  /// The view serving as the slider's track.
  private var track: some View
  {
    Image("horizontal_track", bundle: .module)
      .resizable(capInsets: EdgeInsets(), resizingMode: .tile)
      .frame(height: 8)
  }

  /// The slider's body is composed of a track image and a thumb button
  /// controlled by a drag gesture.
  var body: some View
  {
    GeometryReader
    {
      geometry in

      ZStack(alignment: .sliderAlignment)
      {
        HStack(spacing: 0)
        {
          minTrack(for: geometry.size.width - 36)
          maxTrack(for: geometry.size.width - 36)
            .alignmentGuide(.slider, computeValue: { d in d[.leading] })
        }
        .frame(width: geometry.size.width - 18)
        thumb(for: geometry.size.width - 36)
          .alignmentGuide(.slider, computeValue: { d in d[.center] })
          .offset(x: max(0, min(dragOffset, geometry.size.width - 36)), y: 0)
          .animation(.interactiveSpring())

      }
    }
    .frame(height: HorizontalSlider.sliderHeight)
  }

  /// Initializing with an existing value.
  /// - Parameter value: The value to assign to the slider.
  init(value: Binding<UInt16>)
  {
    _value = value
  }
}

extension VerticalAlignment
{
  private enum SliderVerticalAlignment: AlignmentID
  {
    static func defaultValue(in d: ViewDimensions) -> CGFloat
    {
      d[.bottom]
    }
  }

  static let slider = VerticalAlignment(SliderVerticalAlignment.self)
}

extension HorizontalAlignment
{
  private enum SliderHorizontalAlignment: AlignmentID
  {
    static func defaultValue(in d: ViewDimensions) -> CGFloat
    {
      d[.leading]
    }
  }

  static let slider =
    HorizontalAlignment(SliderHorizontalAlignment.self)
}

extension Alignment
{
  static let sliderAlignment = Alignment(horizontal: .slider, vertical: .slider)
}

// MARK: - HorizontalSlider_Previews

struct HorizontalSlider_Previews: PreviewProvider
{
  static var previews: some View
  {
    HorizontalSlider(value: .constant(24))
      .frame(width: 300)
      .previewDisplayName("24")
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    HorizontalSlider(value: .constant(99))
      .frame(width: 300)
      .previewDisplayName("99")
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    HorizontalSlider(value: .constant(174))
      .frame(width: 300)
      .previewDisplayName("174")
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    HorizontalSlider(value: .constant(249))
      .frame(width: 300)
      .previewDisplayName("249")
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
    HorizontalSlider(value: .constant(400))
      .frame(width: 300)
      .previewDisplayName("400")
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
  }
}
