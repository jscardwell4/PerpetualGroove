//
//  TransportController.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/12/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import SwiftUI
import UIKit

@available(iOS 14.0, *)
public final class TransportController: UIHostingController<TransportView>
{

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }

  // MARK: Initializing

  public init() { super.init(rootView: TransportView()) }

  override public init(rootView: TransportView) { super.init(rootView: rootView) }

  public required init?(coder aDecoder: NSCoder)
  {
    super.init(rootView: TransportView())
  }
}
