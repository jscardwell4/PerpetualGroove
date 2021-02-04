//
//  ContentView.swift
//  Shared
//
//  Created by Jason Cardwell on 1/19/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import Documents
import MIDI
import MoonDev
import Sequencing
import SoundFont
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - ContentView

/// The main content.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ContentView: View
{
  // MARK: Environment
  
  /// The shared sequencer instance loaded into the environment by `GrooveApp`.
  @EnvironmentObject var sequencer: Sequencer

  /// The file configuration for the open document loaded into the
  /// environment by `GrooveApp`.
  @Environment(\.openDocument) var openDocument: FileDocumentConfiguration<Document>?

  // MARK: Components

  /// The `􀆉` button.
  private func backButton(_ currentLayout: LayoutPreference) -> some View
  {
    Button
    {
      UIApplication.shared.windows.first?.rootViewController?
        .dismiss(animated: true){}
    }
    label:
    {
      Image(systemName: "chevron.left")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(minHeight: 14, idealHeight: 14, maxHeight: 14)
    }
    .accentColor(.primaryColor1)
    .contentShape(Rectangle())
    .layout(currentLayout.backButton)
  }

  /// The sequence name.
  private func nameField(_ currentLayout: LayoutPreference) -> some View
  {
    HStack
    {
      Spacer()
      SequenceNameField()
        .environmentObject(sequencer.sequence) // Provide the sequence.
    }
    .layout(currentLayout.nameField)
  }

  /// The mixer.
  private func mixer(_ currentLayout: LayoutPreference) -> some View
  {
    MixerView()
      .environmentObject(Mixer(sequence: sequencer.sequence)) // Provide the mixer model.
      .layout(currentLayout.mixer) // Apply `currentLayout` to the mixer.
      .softwareKeyboardAdaptive() // Adapt to software keyboard.
  }

  /// The player.
  private func player(_ currentLayout: LayoutPreference) -> some View
  {
    PlayerView()
      .environmentObject(sequencer.player) // Provider the player.
      .layout(currentLayout.player) // Apply `currentLayout` to the player.
  }

  /// The transport.
  private func transport(_ currentLayout: LayoutPreference) -> some View
  {
    TransportView()
      .environmentObject(sequencer.transport) // Provide the transport.
      .layout(currentLayout.transport) // Apply `currentLayout` to the transport.
  }

  /// The mixer and player in a horizontal stack.
  private func mixerPlayerStack(_ currentLayout: LayoutPreference) -> some View
  {
    HStack
    {
      mixer(currentLayout)
      Spacer()
      player(currentLayout)
    }
    .layout(currentLayout.mixerPlayer) // Apply `currentLayout` to the stack.
  }

  /// All of the view's components combined.
  private func content(_ proxy: GeometryProxy) -> some View
  {
    let layout = LayoutPreference(proxy: proxy)

    return VStack { mixerPlayerStack(layout); transport(layout) }
      .navigationBarItems(leading: backButton(layout), trailing: nameField(layout))
      .background(Color.backgroundColor1.edgesIgnoringSafeArea(.all))
      .navigationBarBackButtonHidden(true)
      .navigationTitle("")
  }

  var body: some View { GeometryReader { content($0) } }

}

// MARK: - LayoutPreference

private struct LayoutPreference
{
  let mixer: FramePreference
  let player: FramePreference
  let mixerPlayer: FramePreference
  let transport: FramePreference
  let nameField: FramePreference
  let backButton: FramePreference

  init(proxy: GeometryProxy)
  {
    let 𝘸 = proxy.size.width
    let 𝘩 = proxy.size.height
    switch (𝘸, 𝘩)
    {
      case (1_194, _): // iPad Pro (11-inch)

        let 𝘩_top: CGFloat = 566
        let 𝘩_bottom: CGFloat = 200

        mixer = FramePreference(height: .required(value: 𝘩_top))
        player = FramePreference(height: .required(value: 𝘩_top))
        mixerPlayer = FramePreference(height: .required(value: 𝘩_top - 10))
        transport = FramePreference(
          width: .required(value: 𝘸),
          height: .overUnder(value: 𝘩_bottom, amount: 50)
        )
        nameField = FramePreference(
          width: .explicit(min: 𝘸 / 2 - 44, ideal: 𝘸 - 44, max: 𝘸),
          height: .overUnder(value: 34, amount: 10),
          alignment: .trailing,
          padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 88)
        )
        backButton = FramePreference(height: .overUnder(value: 34, amount: 10))

      default:
        mixer = FramePreference()
        player = FramePreference()
        mixerPlayer = FramePreference()
        transport = FramePreference()
        nameField = FramePreference()
        backButton = FramePreference()
    }
  }
}

// MARK: - FramePreference

private struct FramePreference
{
  let width: SizePreference
  let height: SizePreference
  let alignment: Alignment
  let padding: EdgeInsets

  /// Default initializer with parameters matching properties.
  /// - Parameters:
  ///   - width: The width preference.
  ///   - height: The height preference.
  ///   - alignment: The frame alignment.
  ///   - padding: The padding insets.
  init(width: SizePreference = .unspecified,
       height: SizePreference = .unspecified,
       alignment: Alignment = .center,
       padding: EdgeInsets = .init())
  {
    self.width = width
    self.height = height
    self.alignment = alignment
    self.padding = padding
  }

  /// Initializing with required sizes.
  /// - Parameters:
  ///   - width: The required width or `nil` to leave unspecified.
  ///   - height: The required height or `nil` to leave unspecified.
  ///   - alignment: The frame alignment.
  ///   - padding: The padding insets.
  init(width: CGFloat?,
       height: CGFloat?,
       alignment: Alignment = .center,
       padding: EdgeInsets = .init())
  {
    self.init(width: width == nil ? .unspecified : .required(value: width!),
              height: height == nil ? .unspecified : .required(value: height!),
              alignment: alignment,
              padding: padding)
  }

  /// Initializing with over-under sizes.
  /// - Parameters:
  ///   - width: The ideal width or `nil` to leave unspecified.
  ///   - overUnderWidth: The over-under value or `nil` to require `width` if non-nil.
  ///   - height: The ideal height or `nil` to leave unspecified.
  ///   - overUnderHeight: The over-under value or `nil` to require `height` if non-nil.
  ///   - alignment: The frame alignment.
  ///   - padding: The padding insets.
  init(width: CGFloat?,
       overUnderWidth: CGFloat?,
       height: CGFloat?,
       overUnderHeight: CGFloat?,
       alignment: Alignment = .center,
       padding: EdgeInsets = .init())
  {
    self.init(width: width == nil
      ? .unspecified
      : (overUnderWidth == nil
        ? .required(value: width!)
        : .overUnder(value: width!, amount: overUnderWidth!)),
      height: height == nil
        ? .unspecified
        : (overUnderHeight == nil
          ? .required(value: height!)
          : .overUnder(value: height!, amount: overUnderHeight!)),
      alignment: alignment,
      padding: padding)
  }

  /// Initializing with explicit sizes.
  /// - Parameters:
  ///   - minWidth: The min width or `nil` to rely on `idealWidth` and/or `maxWidth`.
  ///   - idealWidth: The ideal width or `nil` to rely on `minWidth` and/or `maxWidth`.
  ///   - maxWidth: The max width or `nil` to rely on `minWidth` and/or `idealWidth`.
  ///   - minHeight: The min height or `nil` to rely on `idealHeight` and/or `maxHeight`.
  ///   - idealHeight: he ideal height or `nil` to rely on `minHeight` and/or `maxHeight`.
  ///   - maxHeight: The max height or `nil` to rely on `minHeight` and/or `idealHeight`.
  ///   - alignment: The frame alignment.
  ///   - padding: The padding insets.
  init(minWidth: CGFloat?,
       idealWidth: CGFloat?,
       maxWidth: CGFloat?,
       minHeight: CGFloat?,
       idealHeight: CGFloat?,
       maxHeight: CGFloat?,
       alignment: Alignment = .center,
       padding: EdgeInsets = .init())
  {
    let width: SizePreference

    switch (minWidth, idealWidth, maxWidth)
    {
      case let (𝘸_min?, 𝘸_ideal?, 𝘸_max?):
        width = .explicit(min: 𝘸_min, ideal: 𝘸_ideal, max: 𝘸_max)
      case let (𝘸_min?, 𝘸_ideal?, nil):
        width = .explicit(min: 𝘸_min, ideal: 𝘸_ideal, max: 𝘸_ideal)
      case let (𝘸_min?, nil, 𝘸_max?):
        width = .explicit(min: 𝘸_min, ideal: (𝘸_min + 𝘸_max) / 2, max: 𝘸_max)
      case let (nil, 𝘸_ideal?, 𝘸_max?):
        width = .explicit(min: 𝘸_ideal, ideal: 𝘸_ideal, max: 𝘸_max)
      case let (𝘸_min?, nil, nil):
        width = .required(value: 𝘸_min)
      case let (nil, nil, 𝘸_max?):
        width = .required(value: 𝘸_max)
      case let (nil, 𝘸_ideal?, nil):
        width = .required(value: 𝘸_ideal)
      case (nil, nil, nil):
        width = .unspecified
    }

    let height: SizePreference

    switch (minHeight, idealHeight, maxHeight)
    {
      case let (𝘩_min?, 𝘩_ideal?, 𝘩_max?):
        height = .explicit(min: 𝘩_min, ideal: 𝘩_ideal, max: 𝘩_max)
      case let (𝘩_min?, 𝘩_ideal?, nil):
        height = .explicit(min: 𝘩_min, ideal: 𝘩_ideal, max: 𝘩_ideal)
      case let (𝘩_min?, nil, 𝘩_max?):
        height = .explicit(min: 𝘩_min, ideal: (𝘩_min + 𝘩_max) / 2, max: 𝘩_max)
      case let (nil, 𝘩_ideal?, 𝘩_max?):
        height = .explicit(min: 𝘩_ideal, ideal: 𝘩_ideal, max: 𝘩_max)
      case let (𝘩_min?, nil, nil):
        height = .required(value: 𝘩_min)
      case let (nil, nil, 𝘩_max?):
        height = .required(value: 𝘩_max)
      case let (nil, 𝘩_ideal?, nil):
        height = .required(value: 𝘩_ideal)
      case (nil, nil, nil):
        height = .unspecified
    }

    self.init(width: width, height: height, alignment: alignment, padding: padding)
  }

}

// MARK: - SizePreference

private enum SizePreference
{
  case unspecified
  case required(value: CGFloat)
  case overUnder(value: CGFloat, amount: CGFloat)
  case explicit(min: CGFloat, ideal: CGFloat, max: CGFloat)

  init() { self = .unspecified }

  init(_ value: CGFloat) { self = .required(value: value) }

  init(_ value: CGFloat, _ amount: CGFloat)
  {
    self = .overUnder(value: value, amount: amount)
  }

  init(_ min: CGFloat, _ ideal: CGFloat, _ max: CGFloat)
  {
    self = .explicit(min: min, ideal: ideal, max: max)
  }
}

// MARK: - ApplyFramePreference

private struct ApplyFramePreference: ViewModifier
{
  let preference: FramePreference

  func body(content: Content) -> some View
  {

    var minWidth: CGFloat?, idealWidth: CGFloat?, maxWidth: CGFloat?
    var minHeight: CGFloat?, idealHeight: CGFloat?, maxHeight: CGFloat?

    switch preference.width
    {
      case .unspecified:
        minWidth = nil; idealWidth = nil; maxWidth = nil
      case let .required(value: 𝘸):
        minWidth = 𝘸; idealWidth = 𝘸; maxWidth = 𝘸
      case let .overUnder(value: 𝘸, amount: a):
        minWidth = 𝘸 - a; idealWidth = 𝘸; maxWidth = 𝘸 + a
      case let .explicit(min: 𝘸_min, ideal: 𝘸_ideal, max: 𝘸_max):
        minWidth = 𝘸_min; idealWidth = 𝘸_ideal; maxWidth = 𝘸_max
    }
    switch preference.height
    {
      case .unspecified:
        minHeight = nil; idealHeight = nil; maxHeight = nil
      case let .required(value: 𝘩):
        minHeight = 𝘩; idealHeight = 𝘩; maxHeight = 𝘩
      case let .overUnder(value: 𝘩, amount: a):
        minHeight = 𝘩 - a; idealHeight = 𝘩; maxHeight = 𝘩 + a
      case let .explicit(min: 𝘩_min, ideal: 𝘩_ideal, max: 𝘩_max):
        minHeight = 𝘩_min; idealHeight = 𝘩_ideal; maxHeight = 𝘩_max
    }

    return content
      .frame(minWidth: minWidth, idealWidth: idealWidth, maxWidth: maxWidth,
             minHeight: minHeight, idealHeight: idealHeight, maxHeight: maxHeight,
             alignment: preference.alignment)
      .padding(preference.padding)

  }
}

extension View
{
  fileprivate func layout(_ preference: FramePreference) -> some View
  {
    modifier(ApplyFramePreference(preference: preference))
  }
}
