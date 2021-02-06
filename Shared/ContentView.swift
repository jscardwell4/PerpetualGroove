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

  // MARK: Components

  /// The `􀆉` button.
  private func backButton(_ currentLayout: LayoutPreference) -> some View
  {
    Button
    {
      UIApplication.shared.windows.first?.rootViewController?
        .dismiss(animated: true) {}
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
    .layout(currentLayout[.backButton])
  }

  /// The sequence name.
  private func nameField(_ currentLayout: LayoutPreference) -> some View
  {
    HStack
    {
      Spacer()
      SequenceNameField().environmentObject(sequencer.sequence) // Provide the sequence.
      Spacer()
    }
    .layout(currentLayout[.nameField])
  }

  /// The leading navigation bar item.
  private func leadingItem(_ currentLayout: LayoutPreference) -> some View
  {
    HStack { backButton(currentLayout); nameField(currentLayout) }
      .layout(currentLayout[.leadingItem])
  }

  /// The player's toolbar.
  private func toolbar(_ currentLayout: LayoutPreference) -> some View
  {
    Toolbar()
      .environmentObject(sequencer.sequence)
      .environmentObject(sequencer.player)
      .layout(currentLayout[.toolbar])
  }

  /// The trailing navigation bar item.
  private func trailingItem(_ currentLayout: LayoutPreference) -> some View
  {
    HStack { toolbar(currentLayout) }
      .layout(currentLayout[.trailingItem])
  }

  /// The mixer.
  private func mixer(_ currentLayout: LayoutPreference) -> some View
  {
    MixerView()
      .environmentObject(Mixer(sequence: sequencer.sequence)) // Provide the mixer model.
      .layout(currentLayout[.mixer])
      .softwareKeyboardAdaptive() // Adapt to software keyboard.
  }

  /// The player.
  private func player(_ currentLayout: LayoutPreference) -> some View
  {
    PlayerView()
      .environmentObject(sequencer.player) // Provider the player.
      .layout(currentLayout[.player])
  }

  /// The mixer and player in a horizontal stack.
  private func topStack(_ currentLayout: LayoutPreference) -> some View
  {
    HStack { mixer(currentLayout); Spacer(); player(currentLayout) }
      .layout(currentLayout[.topStack])
  }

  /// The transport.
  private func transport(_ currentLayout: LayoutPreference) -> some View
  {
    TransportView()
      .environmentObject(sequencer.transport) // Provide the transport.
      .layout(currentLayout[.transport])
  }

  /// The transport in a horizontal stack.
  private func bottomStack(_ currentLayout: LayoutPreference) -> some View
  {
    HStack { transport(currentLayout) }
      .layout(currentLayout[.bottomStack])
  }

  /// All of the view's components combined.
  private func content(_ currentLayout: LayoutPreference) -> some View
  {
    VStack { topStack(currentLayout); bottomStack(currentLayout) }
      .background(Color.backgroundColor1.edgesIgnoringSafeArea(.all))
      .layout(currentLayout[.rootStack])
      .navigationBarItems(leading: leadingItem(currentLayout),
                          trailing: trailingItem(currentLayout))
      .navigationBarBackButtonHidden(true)
      .navigationTitle("")
  }

  var body: some View { GeometryReader { content(LayoutPreference(geometry: $0)) } }
}

// MARK: - LayoutPreference

private struct LayoutPreference
{
  let geometry: GeometryProxy
  private var preferences: [LayoutKey: FramePreference] = [:]

  subscript(key: LayoutKey) -> FramePreference { preferences[key] ?? FramePreference() }

  init(geometry proxy: GeometryProxy)
  {
    geometry = proxy

    switch (proxy.size.width, proxy.size.height)
    {
      case (1_194, _): // iPad Pro (11-inch)
        SupportedConfiguration.iPad11ʺLandscape.load(into: &preferences)

      default:
        break
    }
  }

  enum SupportedConfiguration: String
  {
    case iPad11ʺLandscape
    case unspecified

    func load(into registry: inout [LayoutKey: FramePreference])
    {
      switch self
      {
        case .iPad11ʺLandscape:
          let 𝘸: CGFloat = 1_194
          let 𝘩_topStack: CGFloat = 566
          let 𝘩_bottomStack: CGFloat = 200

          let 𝘸_leadingItem = 𝘸 / 2
          let 𝘩_leadingItem: CGFloat = 44

          let 𝘸_trailingItem = 𝘸_leadingItem
          let 𝘩_trailingItem = 𝘩_leadingItem

          let 𝘩_backButton = 𝘩_leadingItem
          let 𝘸_backButton = 𝘩_backButton
          let pad_backButton = EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)

          let 𝘩_nameField = 𝘩_leadingItem
          let 𝘸_nameField = 𝘸_leadingItem - 𝘸_backButton
          let pad_nameField = EdgeInsets()

          let pad_player = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

          registry[.backButton] = .init(width: .required(𝘸_backButton),
                                        height: .required(𝘩_backButton),
                                        padding: pad_backButton)

          registry[.nameField] = .init(width: .required(𝘸_nameField),
                                       height: .required(𝘩_nameField),
                                       padding: pad_nameField)

          registry[.leadingItem] = .init(width: .required(𝘸_leadingItem),
                                         height: .required(𝘩_leadingItem))

          registry[.toolbar] = .init()

          registry[.trailingItem] = .init(width: .required(𝘸_trailingItem),
                                          height: .required(𝘩_trailingItem))

          registry[.player] = .init(padding: pad_player)

          registry[.topStack] = .init(minHeight: 𝘩_topStack)

          registry[.transport] = .init(width: .required(𝘸))

          registry[.bottomStack] = .init(height: .overUnder(𝘩_bottomStack, 50))

        case .unspecified:
          break
      }
    }
  }

  enum LayoutKey: String, CaseIterable
  {
    case backButton
    case nameField
    case leadingItem
    case toolbar
    case trailingItem
    case mixer
    case player
    case topStack
    case transport
    case bottomStack
    case rootStack
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
    self.init(width: width == nil ? .unspecified : .required(width!),
              height: height == nil ? .unspecified : .required(height!),
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
        ? .required(width!)
        : .overUnder(width!, overUnderWidth!)),
      height: height == nil
        ? .unspecified
        : (overUnderHeight == nil
          ? .required(height!)
          : .overUnder(height!, overUnderHeight!)),
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
  init(minWidth: CGFloat? = nil,
       idealWidth: CGFloat? = nil,
       maxWidth: CGFloat? = nil,
       minHeight: CGFloat? = nil,
       idealHeight: CGFloat? = nil,
       maxHeight: CGFloat? = nil,
       alignment: Alignment = .center,
       padding: EdgeInsets = .init())
  {
    let width: SizePreference

    switch (minWidth, idealWidth, maxWidth)
    {
      case let (𝘸_min?, 𝘸_ideal?, 𝘸_max?):
        width = .explicit(𝘸_min, 𝘸_ideal, 𝘸_max)
      case let (𝘸_min?, 𝘸_ideal?, nil):
        width = .explicit(𝘸_min, 𝘸_ideal, 𝘸_ideal)
      case let (𝘸_min?, nil, 𝘸_max?):
        width = .explicit(𝘸_min, (𝘸_min + 𝘸_max) / 2, 𝘸_max)
      case let (nil, 𝘸_ideal?, 𝘸_max?):
        width = .explicit(𝘸_ideal, 𝘸_ideal, 𝘸_max)
      case let (𝘸_min?, nil, nil):
        width = .required(𝘸_min)
      case let (nil, nil, 𝘸_max?):
        width = .required(𝘸_max)
      case let (nil, 𝘸_ideal?, nil):
        width = .required(𝘸_ideal)
      case (nil, nil, nil):
        width = .unspecified
    }

    let height: SizePreference

    switch (minHeight, idealHeight, maxHeight)
    {
      case let (𝘩_min?, 𝘩_ideal?, 𝘩_max?):
        height = .explicit(𝘩_min, 𝘩_ideal, 𝘩_max)
      case let (𝘩_min?, 𝘩_ideal?, nil):
        height = .explicit(𝘩_min, 𝘩_ideal, 𝘩_ideal)
      case let (𝘩_min?, nil, 𝘩_max?):
        height = .explicit(𝘩_min, (𝘩_min + 𝘩_max) / 2, 𝘩_max)
      case let (nil, 𝘩_ideal?, 𝘩_max?):
        height = .explicit(𝘩_ideal, 𝘩_ideal, 𝘩_max)
      case let (𝘩_min?, nil, nil):
        height = .required(𝘩_min)
      case let (nil, nil, 𝘩_max?):
        height = .required(𝘩_max)
      case let (nil, 𝘩_ideal?, nil):
        height = .required(𝘩_ideal)
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
  case required(_ value: CGFloat)
  case overUnder(_ value: CGFloat, _ amount: CGFloat)
  case explicit(_ min: CGFloat, _ ideal: CGFloat, _ max: CGFloat)

  init() { self = .unspecified }

  init(_ value: CGFloat) { self = .required(value) }

  init(_ value: CGFloat, _ amount: CGFloat)
  {
    self = .overUnder(value, amount)
  }

  init(_ min: CGFloat, _ ideal: CGFloat, _ max: CGFloat)
  {
    self = .explicit(min, ideal, max)
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
      case let .required(𝘸):
        minWidth = 𝘸; idealWidth = 𝘸; maxWidth = 𝘸
      case let .overUnder(𝘸, a):
        minWidth = 𝘸 - a; idealWidth = 𝘸; maxWidth = 𝘸 + a
      case let .explicit(𝘸_min, 𝘸_ideal, 𝘸_max):
        minWidth = 𝘸_min; idealWidth = 𝘸_ideal; maxWidth = 𝘸_max
    }
    switch preference.height
    {
      case .unspecified:
        minHeight = nil; idealHeight = nil; maxHeight = nil
      case let .required(𝘩):
        minHeight = 𝘩; idealHeight = 𝘩; maxHeight = 𝘩
      case let .overUnder(𝘩, a):
        minHeight = 𝘩 - a; idealHeight = 𝘩; maxHeight = 𝘩 + a
      case let .explicit(𝘩_min, 𝘩_ideal, 𝘩_max):
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
