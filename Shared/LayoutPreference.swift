//
//  LayoutPreference.swift
//  Groove
//
//  Created by Jason Cardwell on 2/5/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev
import SwiftUI

// MARK: - LayoutPreference

struct LayoutPreference
{
  let geometry: GeometryProxy
  let playerSize: CGSize

  private var preferences: [LayoutKey: FramePreference] = [:]

  subscript(key: LayoutKey) -> FramePreference { preferences[key] ?? FramePreference() }

  init(geometry proxy: GeometryProxy)
  {
    geometry = proxy

    switch (proxy.size.width, proxy.size.height)
    {
      case (1_194, _): // iPad Pro (11-inch)
        SupportedConfiguration.iPad11ʺLandscape.load(into: &preferences)
        playerSize = CGSize(square: proxy.size.width / 2 - 20)

      default:
        playerSize = .zero
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
