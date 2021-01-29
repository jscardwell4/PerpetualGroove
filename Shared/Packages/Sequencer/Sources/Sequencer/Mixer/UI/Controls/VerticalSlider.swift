//
//  VerticalSlider.swift
//
//
//  Created by Jason Cardwell on 1/22/21.
//
import MoonDev
import SwiftUI

// MARK: - VerticalSlider

/// A vertical slider control attached to a float value clamped to `0 ... 1`.
struct VerticalSlider: View
{
  /// The slider's value.
  @Binding var value: Float

  /// The vertical offset calculated for `value`.
  private var valueOffset: CGFloat { VerticalSlider.offset(for: value) }

  /// Calculates the vertical offset along the slider track that corresponds with
  /// the specified value.
  /// - Parameter value: The value for which to calculate an offset.
  /// - Returns: The corresponding offset for `value`.
  private static func offset(for value: Float) -> CGFloat
  {
    let h = trackSize.height - pillSize.height
    return h - CGFloat(value) * h
  }

  /// Calculates the slider value corresponding with a specified offset.
  /// - Parameter offset: The offset for which to calculate a value.
  /// - Returns: The corresponding value for `offset`.
  private static func value(for offset: CGFloat) -> Float
  {
    let h = trackSize.height - pillSize.height
    return 1 - Float((h - offset) / h)
  }

  /// The gesture state for the view's drag gesture.
  @GestureState private var dragOffset: CGFloat = 0

  /// The predetermined size for the slider's pill button.
  private static let pillSize = CGSize(width: 60, height: 20)

  /// The predetermined offset for the slider's pill button's x position.
  private static let pillOffset: CGFloat =
  {
    let midPill = pillSize.width * 0.5
    let midFrame = sliderSize.width * 0.5
    return midPill + (midFrame - midPill)
  }()

  /// The view serving as the slider's pill button.
  private var pill: some View
  {
    Image("vertical_thumb", bundle: .module)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: VerticalSlider.pillSize.width,
             height: VerticalSlider.pillSize.height,
             alignment: .center)
      .foregroundColor(Color(#colorLiteral(red: 0.7302821875, green: 0.7035630345, blue: 0.6637413502, alpha: 1)))
      .zIndex(1)
      .gesture(drag)
  }

  /// The drag gesture attached to `pill`.
  private var drag: some Gesture
  {
    DragGesture().updating($dragOffset)
    {
      v, s, _ in
      s = v.translation.height
    }
    .onEnded
    {
      v in
      self.value -= VerticalSlider.value(for: v.translation.height)
    }

  }

  /// The predetermined width of the slider's track.
  private static let trackSize = CGSize(width: 8, height: 180)

  /// The predetermined size of the slider.
  private static let sliderSize = CGSize(width: pillSize.width + pillSize.height,
                                         height: trackSize.height)

  /// The view serving as the slider's track.
  private var track: some View
  {
    Image("vertical_track", bundle: .module)
      .resizable(capInsets: EdgeInsets(), resizingMode: .tile)
      .foregroundColor(Color(#colorLiteral(red: 0.3598591387, green: 0.3248813152, blue: 0.2747731805, alpha: 1)))
      .frame(width: VerticalSlider.trackSize.width)
  }

  /// The slider's body is composed of a track image and a pill button
  /// controlled by a drag gesture.
  var body: some View
  {
    ZStack
    {
      track
        .frame(height: VerticalSlider.trackSize.height - VerticalSlider.pillSize.height)
      pill
        .position(x: VerticalSlider.pillOffset,
                  y: min((valueOffset + dragOffset), VerticalSlider.trackSize.height))
        // TODO: Add limit in the other direction.
        .animation(.interactiveSpring())
    }
    .frame(width: VerticalSlider.sliderSize.width,
           height: VerticalSlider.sliderSize.height,
           alignment: .top)
  }

  /// Initializing with an existing value.
  /// - Parameter value: The value to assign to the slider.
  init(value: Binding<Float>)
  {
    _value = value
  }
}
