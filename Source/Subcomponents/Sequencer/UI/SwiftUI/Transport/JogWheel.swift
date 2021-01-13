//
//  JogWheel.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/11/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import MoonKit
import SwiftUI

// MARK: - JogWheel

struct JogWheel: UIViewRepresentable
{

  func makeUIView(context: Context) -> ScrollWheel
  {
    let jogWheel = ScrollWheel(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
    jogWheel.wheelImage = UIImage(named: "wheel", in: bundle, with: nil)
    jogWheel.dimpleImage = UIImage(named: "dimple", in: bundle, with: nil)
    jogWheel.dimpleFillImage = UIImage(named: "dimple_fill", in: bundle, with: nil)
    jogWheel.dimpleColor = .secondaryColor1
    jogWheel.wheelColor = .secondaryColor2
    jogWheel.dimpleStyle = .sourceAtop
    jogWheel.dimpleFillStyle = .sourceIn
    jogWheel.bounds = CGRect(size: CGSize(width: 150, height: 150))
    return jogWheel
  }

  func updateUIView(_ uiView: ScrollWheel, context: Context)
  {}
}

// MARK: - JogWheel_Previews

struct JogWheel_Previews: PreviewProvider
{
  static var previews: some View
  {
    JogWheel().frame(width: 150, height: 150, alignment: .center)
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
  }
}
