//
//  PlayerController.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import SwiftUI
import UIKit

/// Controller for hosting instances of `PlayerView`.
@available(iOS 14.0, *)
public final class PlayerController: UIHostingController<PlayerView>
{
  /// Overridden to clear the background color.
  override public func viewDidLoad()
  {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }

  // MARK: Initializing

  public init() { super.init(rootView: PlayerView()) }
  override public init(rootView: PlayerView) { super.init(rootView: rootView) }
  public required init?(coder aDecoder: NSCoder) { super.init(rootView: PlayerView()) }
}
