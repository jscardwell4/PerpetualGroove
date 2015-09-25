//
//  MIDIPlayerView.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

final class MIDIPlayerView: SKView {

  var midiPlayerScene: MIDIPlayerScene? { return scene as? MIDIPlayerScene }

  /** reset */
  func reset() { midiPlayerScene?.reset() }

  /** revert */
  func revert() { midiPlayerScene?.revert() }

  /** setup */
  private func setup() {
    ignoresSiblingOrder = true
    presentScene(MIDIPlayerScene(size: bounds.size))
    paused = true
  }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }
}
