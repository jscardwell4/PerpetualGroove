//
//  Toolbar.swift
//
//
//  Created by Jason Cardwell on 2/3/21.
//
import SwiftUI
import MoonDev

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
public struct Toolbar: View
{
  /// The sequencer's player loaded into the environment by `ContentView`.
  @Environment(\.player) var player: Player

  /// The sequencer loaded into the enviroment by `GrooveApp`.
  @EnvironmentObject var sequencer: Sequencer

  /// Expose the default initializer.
  public init() {}
  
  public var body: some View
  {
    GeometryReader
    {
      proxy in

      let 𝘸 = proxy.size.width
      let 𝘩 = proxy.size.height

      let №buttons = Tool.allCases.count
      let №spaces = №buttons - 1

      let spacing: CGFloat = 20
      let availableSpace = 𝘸 - spacing * CGFloat(№spaces)

      let 𝘸_image = min(𝘩 - 10, availableSpace / CGFloat(№buttons))
      let insets_image = EdgeInsets(top: 𝘩 - 𝘸_image, leading: 0, bottom: 0, trailing: 0)

      HStack(spacing: spacing)
      {
        // I think this works because a tool button's id is its tool.
        ForEachCase { ToolButton(tool: $0, insets: insets_image) }
      }
      .frame(width: 𝘸, height: 𝘩)
    }
  }

}
