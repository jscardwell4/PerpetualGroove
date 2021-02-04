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
  /// The shared sequencer instance loaded into the environment by `GrooveApp`.
  @EnvironmentObject var sequencer: Sequencer

  /// The file configuration for the open document loaded into the
  /// environment by `GrooveApp`.
  @Environment(\.openDocument) var openDocument: FileDocumentConfiguration<Document>?

  var body: some View
  {
    GeometryReader
    {
      proxy in

      let currentLayout = Layout(proxy: proxy)
      let mixer = Mixer(sequence: sequencer.sequence)

      VStack
      {
        HStack
        {
          MixerView()
            .environmentObject(mixer)
            .layout(currentLayout.mixer)
            .softwareKeyboardAdaptive()
          Spacer()
          PlayerView()
            .environmentObject(sequencer.player)
            .layout(currentLayout.player)
        }
        .layout(currentLayout.mixerPlayer)

        TransportView()
          .environmentObject(sequencer.transport)
          .layout(currentLayout.transport)
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          HStack
          {
            Spacer()
            SequenceNameField().environmentObject(sequencer.sequence)
              .padding()
          }
          .layout(currentLayout.toolbar)
        }
      }
    }
    .background(Color.backgroundColor1.edgesIgnoringSafeArea(.all))
    .navigationItem { decorate($0) }
  }

  private func decorate(_ navigationItem: UINavigationItem)
  {
    navigationItem.title = ""

    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()

    navigationItem.standardAppearance = appearance
    navigationItem.scrollEdgeAppearance = appearance
  }

  private var navigationBar: UINavigationBar
  {
    guard let window = UIApplication.shared.windows.first,
          let root = window.rootViewController,
          let navigation = root.presentedViewController as? UINavigationController
    else
    {
      fatalError("\(#fileID) \(#function) Faied to retrieve navigation bar.")
    }
    return navigation.navigationBar
  }

  private func goBack()
  {
    #if canImport(UIKit)
    UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true) {}
    #endif
  }

  private struct Layout
  {
    let mixer: FramePreference
    let player: FramePreference
    let mixerPlayer: FramePreference
    let transport: FramePreference
    let toolbar: FramePreference

    init(proxy: GeometryProxy)
    {
      let 𝘸 = proxy.size.width
      let 𝘩 = proxy.size.height
      switch (𝘸, 𝘩)
      {
        case (1_194, _): // iPad Pro (11-inch)

          let 𝘩_top: CGFloat = 566
          let 𝘩_bottom: CGFloat = 200

          mixer = FramePreference(
            requiredHeight: 𝘩_top,
            padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
          )
          player = FramePreference(
            requiredHeight: 𝘩_top,
            padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
          )
          mixerPlayer = FramePreference(
            requiredHeight: 𝘩_top - 10,
            padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
          )
          transport = FramePreference(
            requiredWidth: 𝘸,
            minHeight: 𝘩_bottom - 50,
            idealHeight: 𝘩_bottom,
            maxHeight: 𝘩_bottom + 50,
            padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
          )
          toolbar = FramePreference(
            minWidth: 𝘸 / 2 - 44,
            idealWidth: 𝘸 - 44,
            minHeight: 24,
            idealHeight: 34,
            maxHeight: 44,
            alignment: .trailing
          )

        default:
          mixer = FramePreference()
          player = FramePreference()
          mixerPlayer = FramePreference()
          transport = FramePreference()
          toolbar = FramePreference()
      }
    }
  }
}

// MARK: - FramePreference

private struct FramePreference
{
  let requiredWidth: CGFloat?
  let requiredHeight: CGFloat?
  let minWidth: CGFloat?
  let idealWidth: CGFloat?
  let maxWidth: CGFloat?
  let minHeight: CGFloat?
  let idealHeight: CGFloat?
  let maxHeight: CGFloat?
  let alignment: Alignment
  let padding: EdgeInsets

  init(requiredWidth: CGFloat? = nil,
       requiredHeight: CGFloat? = nil,
       minWidth: CGFloat? = nil,
       idealWidth: CGFloat? = nil,
       maxWidth: CGFloat? = nil,
       minHeight: CGFloat? = nil,
       idealHeight: CGFloat? = nil,
       maxHeight: CGFloat? = nil,
       alignment: Alignment = .center,
       padding: EdgeInsets = .init())
  {
    self.requiredWidth = requiredWidth
    self.requiredHeight = requiredHeight
    self.minWidth = minWidth
    self.idealWidth = idealWidth
    self.maxWidth = maxWidth
    self.minHeight = minHeight
    self.idealHeight = idealHeight
    self.maxHeight = maxHeight
    self.alignment = alignment
    self.padding = padding
  }
}

// MARK: - ApplyFramePreference

private struct ApplyFramePreference: ViewModifier
{
  let preference: FramePreference

  func body(content: Content) -> some View
  {
    switch (preference.requiredWidth, preference.requiredHeight)
    {
      case let (requiredWidth?, requiredHeight?):
        return content
          .frame(minWidth: requiredWidth,
                 idealWidth: requiredWidth,
                 maxWidth: requiredWidth,
                 minHeight: requiredHeight,
                 idealHeight: requiredHeight,
                 maxHeight: requiredHeight,
                 alignment: preference.alignment)
          .padding(preference.padding)
      case let (requiredWidth?, nil):
        return content
          .frame(minWidth: requiredWidth,
                 idealWidth: requiredWidth,
                 maxWidth: requiredWidth,
                 minHeight: preference.minHeight,
                 idealHeight: preference.idealHeight,
                 maxHeight: preference.maxHeight,
                 alignment: preference.alignment)
          .padding(preference.padding)
      case let (nil, requiredHeight?):
        return content
          .frame(minWidth: preference.minWidth,
                 idealWidth: preference.idealWidth,
                 maxWidth: preference.maxWidth,
                 minHeight: requiredHeight,
                 idealHeight: requiredHeight,
                 maxHeight: requiredHeight,
                 alignment: preference.alignment)
          .padding(preference.padding)
      case (nil, nil):
        return content
          .frame(minWidth: preference.minWidth,
                 idealWidth: preference.idealWidth,
                 maxWidth: preference.maxWidth,
                 minHeight: preference.minHeight,
                 idealHeight: preference.idealHeight,
                 maxHeight: preference.maxHeight,
                 alignment: preference.alignment)
          .padding(preference.padding)
    }
  }
}

extension View
{
  fileprivate func layout(_ preference: FramePreference) -> some View
  {
    modifier(ApplyFramePreference(preference: preference))
  }
}
