//
//  Toolbar.swift
//
//
//  Created by Jason Cardwell on 2/3/21.
//
import SwiftUI

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct Toolbar: View
{
  /// The sequencer's player loaded into the environment by `ContentView`.
  @EnvironmentObject var player: Player

  /// The sequencer loaded into the enviroment by `GrooveApp`.
  @EnvironmentObject var sequencer: Sequencer

  var body: some View
  {
    GeometryReader
    {
      proxy in

      let 𝘸 = proxy.size.width
      let 𝘩 = proxy.size.height

      let №tools = AnyTool.allCases.count

      let loopActions = LoopButton.Action.actions(for: sequencer.mode)
      let №loops = loopActions.count

      let №buttons = №tools + №loops
      let №spaces = №buttons - 1

      let spacing: CGFloat = 20
      let availableSpace = 𝘸 - spacing * CGFloat(№spaces)

      let 𝘸_image = min(𝘩 - 10, availableSpace / CGFloat(№buttons))

      HStack(spacing: spacing)
      {
        Spacer()
        ForEach(AnyTool.allCases) { ToolButton(width: 𝘸_image, model: $0) }
          .onPreferenceChange(CurrentTool.self) { player.currentTool = $0.first ?? .none }
        Spacer()
        ForEach(loopActions) { LoopButton(width: 𝘸_image, action: $0) }
        Spacer()
      }
      .frame(width: 𝘸, height: 𝘩, alignment: .bottom)
      .accentColor(.primaryColor1)
    }
  }

}
