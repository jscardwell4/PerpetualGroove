//
//  DocumentsController.swift
//  Documents
//
//  Created by Jason Cardwell on 1/13/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import SwiftUI
import UIKit

/// Controller for hosting instances of `PlayerView`.
public final class DocumentsController: UIHostingController<DocumentsView>
{
  /// Overridden to clear the background color.
  override public func viewDidLoad()
  {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }

  // MARK: Initializing

  public init() { super.init(rootView: DocumentsView()) }
  override public init(rootView: DocumentsView) { super.init(rootView: rootView) }
  public required init?(coder aDecoder: NSCoder) { super.init(rootView: DocumentsView()) }
}
