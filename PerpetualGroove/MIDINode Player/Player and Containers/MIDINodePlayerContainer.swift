//
//  MIDINodePlayerContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/7/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

final class MIDINodePlayerContainer: SecondaryControllerContainer {

  private(set) weak var playerViewController: MIDINodePlayerViewController! {
    didSet { MIDINodePlayer.playerContainer = self }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)

    playerViewController = segue.destination as? MIDINodePlayerViewController
  }

  override var blurFrame: CGRect {
    guard playerViewController?.isViewLoaded == true else { return super.blurFrame }
    return playerViewController!.playerView.frame
  }

}
